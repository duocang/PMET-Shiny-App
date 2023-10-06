//
//  main.cpp
//  PMET
//
//  Created by Paul Brown on 25/04/2019.
//  Copyright © 2019 Paul Brown. All rights reserved.
//

// Compile on MAC

// g++ -I. -I/usr/local/include -L/usr/local/lib -stdlib=libc++ -std=c++11 main.cpp Output.cpp motif.cpp
// motifComparison.cpp -O3 -o pmet

// Compile on nero, devtoolset 4

// g++ -I. -I/usr/local/include -L/usr/local/lib -std=c++11 main.cpp Output.cpp motif.cpp motifComparison.cpp -O3 -o
// pmet

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

bool loadFiles(const std::string &path, const std::string &genesFile, const std::string &promotersFile,
               const std::string &binThreshFile, const std::string &ICFile, const std::string &fimoDir,
               std::unordered_map<std::string, int> &promSizes, std::unordered_map<std::string, double> &topNthreshold,
               std::unordered_map<std::string, std::vector<double>> &ICvalues,
               std::map<std::string, std::vector<std::string>> &clusters, std::vector<std::string> &fimoFiles,
               std::vector<std::map<std::string, std::vector<Output>>> &results);
bool validateInputs(const std::unordered_map<std::string, int> &promSizes,
                    const std::unordered_map<std::string, double> &topNthreshold,
                    const std::unordered_map<std::string, std::vector<double>> &ICvalues,
                    const std::map<std::string, std::vector<std::string>> &clusters,
                    const std::vector<std::string> fimoFiles);
bool fastFileRead(std::string filename, std::stringstream &results);

void bhCorrection(std::vector<Output> &motifs);
// void writeProgressFile(double val, std::string msg, std::string path);
void writeProgress(const std::string &fname, const std::string &message, float inc);
std::vector<std::vector<int>> fairDivision(std::vector<int> input, int numGroups);
int SumVector(std::vector<int> &vec);
// take progress up by 5% of total runtime

int output(std::vector<motif>::iterator first, std::vector<motif>::iterator later, std::vector<motif>::iterator last,
           std::map<std::string, std::vector<std::string>> clusters, motifComparison mComp,
           std::map<std::string, std::vector<Output>> *results, double ICthreshold,
           std::unordered_map<std::string, int> promSizes, long numComplete, long totalComparisons,
           std::string outputDirName);

int outputParallel(std::vector<int> motifsIndx, std::vector<motif> *allMotifs,
                   std::map<std::string, std::vector<std::string>> clusters, motifComparison mComp,
                   std::map<std::string, std::vector<Output>> *results, double ICthreshold,
                   std::unordered_map<std::string, int> promSizes, long numComplete, long totalComparisons,
                   std::string outputDirName);
void exportResultParallel(std::string cluster, std::vector<Output>::iterator beginIt,
                          std::vector<Output>::iterator endIt, std::string outFile, long globalBonferroniFactor);
int main(int argc, const char *argv[]) {
  // ProfilerStart("pmetParallel.prof");
  /*
  inputs,
  1) IC threshold, used in discarding 2 motifs on same gene which partially overlap
  2) path to input files,
  3) genes file, user-supplied gene list, each line "CLUSTER   GENEID"
  */

  std::string inputDir(".");
  // These 3 files expected to be in inputDir, along with folder 'fimohits'
  std::string promotersFile("promoter_lengths.txt");
  std::string binThreshFile("binomial_thresholds.txt");
  std::string ICFile("IC.txt");
  std::string fimoDir("fimohits/");

  std::string outputDirName("./");
  std::string outputFileName("temp_header.txt");

  std::string genesFile("input.txt");
  std::string progressFile("/Users/paulbrown/Desktop/progress.txt");
  // this binary will increase progress by 5% of total run time
  float inc = 0.01;
  double ICthreshold = 4.0;
  double numThreads = 16;
  std::stringstream msgString;
  // parse parameters
  for (int i = 1; i < argc; i += 2) {
    if (!strcmp(argv[i], "-h")) {
      std::cout << "pmet [-d input_directory = '.']\n"
              "     [-g genes_file = 'input.txt']\n"
              "     [-i ICthreshold = 4]\n"
              "     [-p promoter_lengths_file = 'promoter_lengths.txt']\n"
              "     [-b binomial_values_file = 'binomial_thresholds.txt']\n"
              "     [-c information_content_file = 'IC.txt']\n"
              "     [-f fimo_dir = 'fimohits']\n"
              "     [-s progress_file = 'progress.log']\n"
              "     [-o output_file = 'motif_found.txt']\n";

      std::cout << "Usage: pmet [OPTIONS]" << std::endl;
      std::cout << "Options:" << std::endl;
      std::cout << "  -d <input_directory>           Set input directory.          Default is '.'."                       << std::endl;
      std::cout << "  -g <genes_file>                Set genes file.               Default is 'input.txt'."               << std::endl;
      std::cout << "  -i <ICthreshold>               Set IC threshold.             Default is 4."                         << std::endl;
      std::cout << "  -p <promoter_lengths_file>     Set promoter lengths file.    Default is 'promoter_lengths.txt'."    << std::endl;
      std::cout << "  -b <binomial_values_file>      Set binomial values file.     Default is 'binomial_thresholds.txt'." << std::endl;
      std::cout << "  -c <information_content_file>  Set information content file. Default is 'IC.txt'."                  << std::endl;
      std::cout << "  -s <progress_file>             Set progress log.             Default is 'progress.log'."            << std::endl;
      std::cout << "  -o <output_file>               Set output file.              Default is 'motif_found.txt'."         << std::endl;

      return 0;
    } else if (!strcmp(argv[i], "-i"))
      ICthreshold = atof(argv[i + 1]);
    else if (!strcmp(argv[i], "-t"))
      numThreads = atof(argv[i + 1]);
    else if (!strcmp(argv[i], "-d"))
      inputDir = argv[i + 1];
    else if (!strcmp(argv[i], "-g"))
      genesFile = argv[i + 1];  // should be a full path
    else if (!strcmp(argv[i], "-p"))
      promotersFile = argv[i + 1];
    else if (!strcmp(argv[i], "-b"))
      binThreshFile = argv[i + 1];
    else if (!strcmp(argv[i], "-c"))
      ICFile = argv[i + 1];
    else if (!strcmp(argv[i], "-f"))
      fimoDir = argv[i + 1];
    else if (!strcmp(argv[i], "-o"))
      outputDirName = argv[i + 1];
    else if (!strcmp(argv[i], "-s"))
      progressFile = argv[++i];  // must be full path
    else {
      std::cout << "Error: unknown command line switch " << argv[i] << std::endl;
      return 1;
    }
  }

  if (inputDir.back() != '/')
    inputDir += "/";

  if (outputDirName.back() != '/')
    outputDirName += "/";

  if (fimoDir.back() != '/')
    fimoDir += "/";

  fimoDir = inputDir + fimoDir;

  std::cout << "          Input parameters          " << std::endl;
  std::cout << "------------------------------------" << std::endl;
  std::cout << "Input Directory:\t\t\t" << inputDir << std::endl;
  std::cout << "Gene list file:\t\t\t\t" << genesFile << std::endl;
  std::cout << "IC threshold:\t\t\t\t" << ICthreshold << std::endl;
  std::cout << "Threads used \t\t\t\t" << numThreads << std::endl;
  std::cout << "Promoter lengths:\t\t\t" << promotersFile << std::endl;
  std::cout << "Binomial threshold values:\t\t" << binThreshFile << std::endl;
  std::cout << "Motif IC values:\t\t\t" << ICFile << std::endl;
  std::cout << "Fimo files:\t\t\t\t" << fimoDir << std::endl;
  std::cout << "Output directory:\t\t\t" << outputDirName << std::endl;
  std::cout << "------------------------------------" << std::endl << std::endl;

  std::unordered_map<std::string, int> promSizes;
  std::unordered_map<std::string, double> topNthreshold;
  std::unordered_map<std::string, std::vector<double>> ICvalues;
  std::vector<std::string> fimoFiles;
  std::map<std::string, std::vector<std::string>> clusters;  // ordered map faster to iterate sequentially
  std::vector<std::map<std::string, std::vector<Output>>> results(
      numThreads);  // key is cluster name, value is vector of pairwise motif comparisons;
  // results will be sotred serpately for each cluster to make later MTC stuff more efficient

  writeProgress(progressFile, "Reading inputs...", 0.0);

  if (!loadFiles(inputDir, genesFile, promotersFile, binThreshFile, ICFile, fimoDir, promSizes, topNthreshold, ICvalues,
                 clusters, fimoFiles, results))
    exit(1);

  if (!validateInputs(promSizes, topNthreshold, ICvalues, clusters, fimoFiles))
    exit(1);

  // Got valid data so proceed

  // For each pair-wise comparison of fimo files
  long numClusters = clusters.size();
  long numFimoFiles = fimoFiles.size();
  long totalComparisons = (numFimoFiles * numFimoFiles - numFimoFiles) / 2;

  std::vector<motif> allMotifs(numFimoFiles, motif());

  bool missingValues = false;

  msgString << "Reading " << fimoFiles.size() << " FIMO files..." << std::endl;

  std::cout << msgString.str();
  writeProgress(progressFile, msgString.str(), inc);

  for (long m = 0; m < numFimoFiles; ++m)  // read each file
    allMotifs[m].readFimoFile(fimoDir + fimoFiles[m], inputDir, ICvalues, topNthreshold, &missingValues);
  std::cout << "Done" << std::endl;
  if (missingValues)
    exit(1);

  // now do all pair-wise comparisons
  long numComplete = 0;

  msgString.str("");
  msgString << "Perfomed 0 of " << totalComparisons << " pair-wise comparisons" << std::endl;
  writeProgress(progressFile, msgString.str(), inc);

  std::cout << std::unitbuf;  // no buffering, print immediatley
  std::cout << msgString.str();
  std::cout << " 10%" << std::endl;

  motifComparison mComp;  // represents one line in the results file

  // The idea of parallel computing:
  // distribute motifs into each thread, to have sum of motifs' comparsions relatively equal in each thread.
  // be aware that, the motifs are divided into n+1 threads, instead of n threads.
  int numMotifs = std::distance(allMotifs.begin(), allMotifs.end());
  std::vector<int> numMotifsPairComparasionVector(numMotifs);
  for (int i = 0; i < numMotifs; i++) numMotifsPairComparasionVector[i] = i;
  std::vector<std::vector<int>> motifsInThread = fairDivision(numMotifsPairComparasionVector, numThreads);

  // allocate space for results of motifs' comparsios
  for (int i = 0; i < numThreads - 1 + 1; i++) {  // per thread
    std::cout << "Reserve storage for results of Thread: " << i + 1 << std::endl;
    for (std::map<std::string, std::vector<Output>>::iterator j = results[i].begin(); j != results[i].end();
         j++) {  // per cluster
      int spaceNeeded = 0;
      for (int comparsionOfoneMotif : motifsInThread[i]) spaceNeeded += comparsionOfoneMotif;
      std::cout << "      Storage needed by cluster " << j->first << " is " << spaceNeeded << std::endl;
      (j->second).reserve(totalComparisons);
    }
  }

  // setup computing in n threads
  std::vector<std::thread> threads(numThreads - 1);
  for (int i = 0; i < numThreads - 1; ++i) {
    std::cout << "----------------------------   Thread " << i + 1 << " is running  ----------------------------"
              << std::endl;

    threads[i] = std::thread(outputParallel, motifsInThread[i], &allMotifs, clusters, mComp, &results[i], ICthreshold,
                             promSizes, numComplete, totalComparisons, outputDirName);
  }
  // setup n+1 thread
  std::cout << "----------------------------   Thread " << numThreads << " is running  ----------------------------"
            << std::endl;
  outputParallel(motifsInThread[numThreads - 1], &allMotifs, clusters, mComp, &results[numThreads - 1], ICthreshold,
                 promSizes, numComplete, totalComparisons, outputDirName);
  // run all threads
  for (auto &entry : threads) entry.join();

  // concatenate results from threads
  for (std::vector<std::map<std::string, std::vector<Output>>>::iterator resultsIt = results.begin() + 1;
       resultsIt != results.end();) {
    // append elements of results (from the second to the last) to the first one results[0]
    // consider different clusters of each element from results
    for (auto const &x : results[0])
      results[0][x.first].insert(results[0][x.first].end(), (*resultsIt)[x.first].begin(), (*resultsIt)[x.first].end());
    resultsIt = results.erase(resultsIt);  // remove element of threads, keep results[0] only
  }

  std::cout << std::endl << "Applying correction factors" << std::endl;
  writeProgress(progressFile, "Applying correction factors", 0.02);
  // Multiple testing corrections
  // global
  long globalBonferroniFactor = numClusters * totalComparisons;  // total number of tests performed

  // export results to multiple temp fiels to accelerate
  for (std::map<std::string, std::vector<Output>>::iterator cl = results[0].begin(); cl != results[0].end(); cl++) {
    // per cluster. Bonferroni factor is size of cluster. Calculate  Benjamini-Hochberg FDR correction.
    // map will be already sorted on sort on cluster name, sort members by motif1, then motif2
    std::sort((cl->second).begin(), (cl->second).end(), sortComparisons);  // cl->second is vector<motifComparison>
    bhCorrection(cl->second);

    int interval = (int)(cl->second).size() / numThreads;
    // initialize threads
    std::vector<std::thread> threads(numThreads);
    for (int i = 0; i < numThreads; i++) {
      int beginIndx = i * interval;
      int endIndx = i * interval + interval - 1;
      endIndx = (endIndx >= (cl->second).size() - 1 || i == numThreads - 1) ? (cl->second).size() - 1 : endIndx;

      // std::cout << endIndx << std::endl;
      std::vector<Output> v2 =
          std::vector<Output>(std::begin(cl->second) + beginIndx, std::begin(cl->second) + endIndx + 1);
      // std::cout << outputDirName + "temp_result_" + cl->first + "_" + std::to_string(i) + ".txt"
      //           << "预计的大小：" << v2.size() << std::endl;

      threads[i] = std::thread(
          exportResultParallel, cl->first, std::begin(cl->second) + beginIndx, std::begin(cl->second) + endIndx + 1,
          outputDirName + "temp_result_" + cl->first + "_" + std::to_string(i) + ".txt", globalBonferroniFactor);
    }
    // run all threads
    for (auto &entry : threads) entry.join();

    // std::cout << std::endl << std::endl;
  }
  // merge temp files
  // open results file, pmet results
  std::ofstream outputFile;
  outputFile.open(outputDirName + outputFileName, std::ios_base::out);
  if (!outputFile.is_open()) {
    std::cout << "Error openning results file " << (outputDirName + outputFileName) << std::endl;
    exit(1);
  }

  // add header
  Output::writeHeaders(outputFile);

  outputFile.close();

  // ProfilerStop();

  std::cout << "Done." << std::endl;
  return 0;
}
