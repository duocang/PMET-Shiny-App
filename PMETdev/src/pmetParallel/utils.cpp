#include <dirent.h>
// #include <gperftools/profiler.h>
#include <math.h>
#include <string.h>
#include <sys/types.h>

#include <algorithm>
#include <iomanip>
#include <iostream>
#include <numeric>
#include <sstream>
#include <thread>
#include <utility>
#include <vector>

#include "Output.hpp"
#include "motif.hpp"
#include "motifComparison.hpp"
#include "utils.hpp"

void exportResultParallel(std::string cluster, std::vector<Output>::iterator beginIt,
                          std::vector<Output>::iterator endIt, std::string outFile, long globalBonferroniFactor) {
  // open results file, pmet results
  std::ofstream outputFile;
  outputFile.open(outFile, std::ios_base::out);
  if (!outputFile.is_open()) {
    std::cout << "Error openning results file " << outFile << std::endl;
    exit(1);
  }

  // print sorted, correcgted compoarisons inb this cluster
  for (std::vector<Output>::iterator mc = beginIt; mc != endIt; mc++) {
    outputFile << cluster << '\t';  // cluster name
    mc->printMe(globalBonferroniFactor, outputFile);
  }

  outputFile.close();
}

void writeProgress(const std::string &fname, const std::string &message, float inc) {
  std::ifstream infile;

  float progress = 0.0;
  std::string oldMessage;

  infile.open(fname, std::ifstream::in);
  if (infile.is_open()) {
    infile >> progress >> oldMessage;
    infile.close();
  }
  progress += inc;
  std::ofstream outfile;

  outfile.open(fname, std::ofstream::out);

  if (outfile.is_open()) {
    outfile << progress << "\t" << message << std::endl;
    outfile.close();
  }
}

bool loadFiles(const std::string &path, const std::string &genesFile, const std::string &promotersFile,
               const std::string &binThreshFile, const std::string &ICFile, const std::string &fimoDir,
               std::unordered_map<std::string, int> &promSizes, std::unordered_map<std::string, double> &topNthreshold,
               std::unordered_map<std::string, std::vector<double>> &ICvalues,
               std::map<std::string, std::vector<std::string>> &clusters, std::vector<std::string> &fimoFiles,
               std::vector<std::map<std::string, std::vector<Output>>> &results) {
  std::cout << "Reading input files..." << std::endl;

  // get promoter lengths. These are stored in tsv file "Name  length"
  std::stringstream promFileContent;
  fastFileRead(path + promotersFile, promFileContent);  // reads into a single string

  std::string geneID, len;

  while (promFileContent >> geneID >> len)
    promSizes.emplace(geneID, stoi(len));  // key is genID, value is promoter length

  std::cout << "Universe size is " << promSizes.size() << std::endl;

  std::stringstream binFileContent;
  // same for binomial thresholds
  fastFileRead(path + binThreshFile, binFileContent);  // reads into a single string

  std::string motifID, threshold;

  while (binFileContent >> motifID >> threshold) topNthreshold.emplace(motifID, stof(threshold));

  // Information Content values. Here there is a float value for each position in the motif

  std::ifstream ifs(path + ICFile);

  if (!ifs) {
    std::cout << "Error: Cannot open file " << path + ICFile << std::endl;
    return false;
  }

  std::string line;
  while (std::getline(ifs, line)) {
    std::istringstream ics(line);
    double score;
    ics >> motifID;

    ICvalues.emplace(motifID, std::vector<double>());

    while (ics >> score) ICvalues[motifID].push_back(score);
  }

  // gene clusters

  std::stringstream geneFileContent;
  std::string clusterID;

  fastFileRead(genesFile, geneFileContent);

  long genesFound = 0;

  std::map<std::string, std::vector<std::string>>::iterator got;
  while (geneFileContent >> clusterID >> geneID) {
    // vector of genes for each cluster
    if ((got = clusters.find(clusterID)) == clusters.end()) {
      clusters.emplace(clusterID, std::vector<std::string>());

      for (int i = 0; i < results.size(); i++) {
        // initialise results vector for this cluster
        results[i].emplace(clusterID, std::vector<Output>());
      }
    }
    clusters[clusterID].push_back(geneID);
    genesFound++;
  }
  std::cout << "Found " << genesFound << " gene IDs in " << clusters.size() << " clusters" << std::endl;

  // need to sort clustrer first oc can find intersection efficiently.
  for (auto &cl : clusters) std::sort(cl.second.begin(), cl.second.end());

  // list of fimo files
  std::string searchDir = fimoDir;
  DIR *pDir = opendir(searchDir.c_str());

  if (!pDir) {
    std::cout << "Error: Cannot find directory " << searchDir << std::endl;
    return false;
  }

  struct dirent *fp;
  while ((fp = readdir(pDir)))  // exclude "." and ".."
    if (fp->d_name[0] != '.')
      fimoFiles.push_back(fp->d_name);

  closedir(pDir);

  // sort, excluding .txt part
  std::sort(fimoFiles.begin(), fimoFiles.end(), [](const std::string &a, const std::string &b) {
    return (a.compare(0, a.size() - 4, b, 0, b.size() - 4) < 0);
  });

  return true;
}

bool fastFileRead(std::string filename, std::stringstream &results) {
  // fast way to read a text file into memory
  // reads entire file into results and returns number of lines

  long flength;
  long numLines = 0;
  bool success = false;

  std::ifstream ifs(filename, std::ifstream::binary);

  if (!ifs) {
    std::cout << "Error: Cannot open file " << filename << std::endl;
    exit(1);
  }

  ifs.seekg(0, ifs.end);
  flength = ifs.tellg();
  ifs.seekg(0, ifs.beg);

  std::string buffer(flength, '\0');

  if (!ifs.read(&buffer[0], flength))
    std::cout << "Error reading file " << filename << std::endl;
  else {
    results.str(buffer);
    success = true;
  }

  ifs.close();

  if (success) {
    // count number of lines read
    numLines = std::count(std::istreambuf_iterator<char>(results), std::istreambuf_iterator<char>(), '\n');
    // in case no \n on last line
    results.unget();
    if (results.get() != '\n')
      numLines++;
    // reset iterator
    results.seekg(0);
  } else
    exit(1);

  return numLines;
}

bool validateInputs(const std::unordered_map<std::string, int> &promSizes,
                    const std::unordered_map<std::string, double> &topNthreshold,
                    const std::unordered_map<std::string, std::vector<double>> &ICvalues,
                    const std::map<std::string, std::vector<std::string>> &clusters,
                    const std::vector<std::string> fimoFiles) {
  std::cout << "Validating inputs...";

  if (clusters.empty()) {
    std::cout << "Error : No gene clusters found!" << std::endl;
    return false;
  }

  if (fimoFiles.empty()) {
    std::cout << "Error : FIMO files not found!" << std::endl;
    return false;
  }

  if (topNthreshold.empty()) {
    std::cout << "Error : Binomial threshold values not found!" << std::endl;
    return false;
  }

  if (ICvalues.empty()) {
    std::cout << "Error : Information Content values not found!" << std::endl;
    return false;
  }

  if (promSizes.empty()) {
    std::cout << "Error : No promoter sizes found!" << std::endl;
    return false;
  }

  bool noError = true;
  // promsizes must contain a value for every input gene
  for (auto cl = std::begin(clusters); cl != std::end(clusters); cl++) {
    for (auto gene = std::begin(cl->second); gene != std::end(cl->second); gene++) {
      // does this key exist?
      if (promSizes.find(*gene) == promSizes.end()) {
        std::cout << "Error : Gene ID " << *gene << " not found in promoter lengths file!" << std::endl;
        noError = false;
      }
    }
  }
  // theshold and IC must have values for every motif but will cgeck this after reading fimo files
  // in case motif name doesn't exactly match file name

  if (noError)
    std::cout << "OK";
  std::cout << std::endl;
  return noError;
}

void bhCorrection(std::vector<Output> &motifs) {
  // get list of all pvals fo rthis cluster, retaining original index position

  std::vector<std::pair<long, double>> pValues;
  long n = motifs.size();

  pValues.reserve(n);

  for (long i = 0; i < n; i++) pValues.push_back(std::make_pair(i, motifs[i].getpValue()));

  // sort descendingie largest p val first
  std::sort(pValues.begin(), pValues.end(),
            [](const std::pair<long, double> &a, const std::pair<long, double> &b) { return a.second > b.second; });

  // now multiply each p value by a factor based on its position in the sorted list
  for (long i = 0; i < n; i++) {
    pValues[i].second *= (n / (n - i));
    if (i && pValues[i].second > pValues[i - 1].second)
      pValues[i].second = pValues[i - 1].second;

    motifs[pValues[i].first].setBHCorrection(
        pValues[i].second);  // assign corrected value to its original index position before sort
  }
}

std::vector<std::vector<int>> fairDivision(std::vector<int> input, int numGroups) {
  std::vector<std::vector<int>> resultVector;
  if (numGroups >= input.size()) {
    resultVector.resize(input.size());
    for (int i = 0; i < input.size(); i++) {
      resultVector[i] = {input[i]};
    }
  }

  resultVector.resize(numGroups);

  std::sort(input.begin(), input.end(), std::greater<int>());

  // 从最大的开始填充到结果中
  for (int i = 0; i < numGroups; i++) resultVector[i] = {input[i]};

  // 从大到小遍历剩下的数字
  for (int i = numGroups; i < input.size(); i++) {
    std::vector<int> tempSum(numGroups);  // a temp vector to keep sum of each group

    for (int j = 0; j < resultVector.size(); j++) tempSum[j] = SumVector(resultVector[j]) + input[i];

    int minIndex = min_element(tempSum.begin(), tempSum.end()) - tempSum.begin();  // 找出当前和最小的分组
    resultVector[minIndex].push_back(input[i]);  // add the max of the rest numbers to the group with min sum
  }
  return resultVector;
}

int SumVector(std::vector<int> &vec) {
  int res = 0;
  for (size_t i = 0; i < vec.size(); i++) res += vec[i];
  return res;
}

int output(std::vector<motif>::iterator blockstart, std::vector<motif>::iterator blockEnd,
           std::vector<motif>::iterator last, std::map<std::string, std::vector<std::string>> clusters,
           motifComparison mComp, std::map<std::string, std::vector<Output>> *results, double ICthreshold,
           std::unordered_map<std::string, int> promSizes, long numComplete, long totalComparisons,
           std::string outputDirName) {
  for (std::vector<motif>::iterator motif1 = blockstart; motif1 != blockEnd; ++motif1) {
    for (std::vector<motif>::iterator motif2 = motif1 + 1; motif2 != last; ++motif2) {
      mComp.findIntersectingGenes(*motif1, *motif2, ICthreshold,
                                  promSizes);  // sets genesInUniverseWithBothMotifs, used in Coloc Test
      // got shared genes so do test for each cluster
      for (auto &cl : clusters) {
        // std::cout << "                          Gene cluster: " << cl.first << std::endl;
        // std::cout << "                                 mComp: " << mComp.getpValue() << std::endl;
        mComp.colocTest(promSizes.size(), ICthreshold, cl.first, cl.second);
        (*results)[cl.first].push_back(Output(motif1->getMotifName(), motif2->getMotifName(), mComp));
      }

      std::cout << "\b\b\b";
      // progress goes from 10 to 90% in this loop
      double progVal = 0.1 + double(0.8 * ++numComplete) / totalComparisons;
      std::cout << std::setw(2) << long(progVal * 100) << "%" << std::endl;
    }
    std::cout << " Perfomed " << numComplete << " of " << totalComparisons << " pair-wise comparisons" << std::endl;
  }
  return 1;
}

/*
    motif pair comparsion, one of motif (from a vector) compares with following motifs

    @motifsIndxVector: a vector of motifs' index
    @*allMotifs: a vector of motifs' name
    @clusters: clusters of genes
    @motifComparison: result of motif's comparsion
    @*results: as it named
    @ICthreshold
    @promSizes
    @numComplete
    @outputDirName
*/
int outputParallel(std::vector<int> motifsIndxVector, std::vector<motif> *allMotifs,
                   std::map<std::string, std::vector<std::string>> clusters, motifComparison mComp,
                   std::map<std::string, std::vector<Output>> *results, double ICthreshold,
                   std::unordered_map<std::string, int> promSizes, long numComplete, long totalComparisons,
                   std::string outputDirName) {
  for (int i : motifsIndxVector) {
    motif motif1 = (*allMotifs)[i];
    for (int j = i + 1; j < (*allMotifs).size(); j++) {
      motif motif2 = (*allMotifs)[j];

      mComp.findIntersectingGenes(motif1, motif2, ICthreshold,
                                  promSizes);  // sets genesInUniverseWithBothMotifs, used in Coloc Test
      // got shared genes so do test for each cluster
      for (auto &cl : clusters) {
        mComp.colocTest(promSizes.size(), ICthreshold, cl.first, cl.second);
        (*results)[cl.first].push_back(Output(motif1.getMotifName(), motif2.getMotifName(), mComp));
        // std::cout   << cl.first << " " << motif1.getMotifName() << " " << motif2.getMotifName()
        //             << " " << mComp.getSharedGenesInCluster().size() << " "  << mComp.getpValue() << std::endl;
      }
    }
  }
  return 1;
}