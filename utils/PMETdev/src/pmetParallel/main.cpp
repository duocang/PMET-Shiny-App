//
//  main.cpp
//  PMET
//
//  Created by Paul Brown on 25/04/2019.
//  Copyright © 2019 Paul Brown. All rights reserved.
//

// Compile on MAC

// g++ -I. -I/usr/local/include -L/usr/local/lib -stdlib=libc++ -std=c++11 main.cpp Output.cpp motif.cpp motifComparison.cpp -O3 -o pmet

// Compile on nero, devtoolset 4

// g++ -I. -I/usr/local/include -L/usr/local/lib -std=c++11 main.cpp Output.cpp motif.cpp motifComparison.cpp -O3 -o pmet

#include <iostream>
#include <sstream>
#include <iostream>
#include <iomanip>
#include <utility>
#include <dirent.h>
#include <sys/types.h>
#include <math.h>
#include <vector>
#include <string.h>
#include <thread>
#include <algorithm>
#include <numeric>
#include <vector>
#include "motif.hpp"
#include "motifComparison.hpp"
#include "Output.hpp"
#include <gperftools/profiler.h>

bool loadFiles(const std::string &path, const std::string &genesFile,
               const std::string &promotersFile, const std::string &binThreshFile,
               const std::string &ICFile, const std::string &fimoDir, std::unordered_map<std::string, int> &promSizes,
               std::unordered_map<std::string, double> &topNthreshold, std::unordered_map<std::string, std::vector<double>> &ICvalues,
               std::map<std::string, std::vector<std::string>> &clusters,
               std::vector<std::string> &fimoFiles,
               std::vector<std::map<std::string, std::vector<Output>>> &results);
bool validateInputs(const std::unordered_map<std::string, int> &promSizes, const std::unordered_map<std::string, double> &topNthreshold, const std::unordered_map<std::string, std::vector<double>> &ICvalues, const std::map<std::string, std::vector<std::string>> &clusters, const std::vector<std::string> fimoFiles);
bool fastFileRead(std::string filename, std::stringstream &results);

void bhCorrection(std::vector<Output> &motifs);
// void writeProgressFile(double val, std::string msg, std::string path);
void writeProgress(const std::string &fname, const std::string &message, float inc);
std::vector<std::vector<int>> fairDivision(std::vector<int> input, int numGroups);
int SumVector(std::vector<int> &vec);
// take progress up by 5% of total runtime

int output(std::vector<motif>::iterator first, std::vector<motif>::iterator later, std::vector<motif>::iterator last,
           std::map<std::string, std::vector<std::string>> clusters, motifComparison mComp, std::map<std::string, std::vector<Output>> *results, double ICthreshold, std::unordered_map<std::string, int> promSizes, long numComplete, long totalComparisons, std::string outputDirName);

int outputParallel(std::vector<int> motifsIndx,
                   std::vector<motif> *allMotifs,
                   std::map<std::string, std::vector<std::string>> clusters,
                   motifComparison mComp,
                   std::map<std::string, std::vector<Output>> *results,
                   double ICthreshold,
                   std::unordered_map<std::string, int> promSizes,
                   long numComplete,
                   long totalComparisons,
                   std::string outputDirName);
void exportResultParallel(std::string cluster, std::vector<Output>::iterator beginIt, std::vector<Output>::iterator endIt, std::string outFile, long globalBonferroniFactor);
int main(int argc, const char *argv[])
{
    ProfilerStart("pmetParallel.prof");
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
    for (int i = 1; i < argc; i += 2)
    {
        if (!strcmp(argv[i], "-h"))
        {
            std::cout << "pmet [-d input_directory = '.'] [-g genes_file = 'input.txt'] [-i ICthreshold = 4] [-p promoter_lengths_file = 'promoter_lengths.txt'] ";
            std::cout << "[-b binomial_values_file = 'binomial_thresholds.txt'] [-c information_content_file = 'IC.txt'] [-f fimo_dir = 'fimohits'] [-o output_file = 'motif_found.txt']" << std::endl;
            return 0;
        }
        else if (!strcmp(argv[i], "-i"))
            ICthreshold = atof(argv[i + 1]);
        else if (!strcmp(argv[i], "-t"))
            numThreads = atof(argv[i + 1]);
        else if (!strcmp(argv[i], "-d"))
            inputDir = argv[i + 1];
        else if (!strcmp(argv[i], "-g"))
            genesFile = argv[i + 1]; // should be a full path
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
            progressFile = argv[++i]; // must be full path
        else
        {
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
    std::cout << "------------------------------------" << std::endl
              << std::endl;

    std::unordered_map<std::string, int> promSizes;
    std::unordered_map<std::string, double> topNthreshold;
    std::unordered_map<std::string, std::vector<double>> ICvalues;
    std::vector<std::string> fimoFiles;
    std::map<std::string, std::vector<std::string>> clusters;                    // ordered map faster to iterate sequentially
    std::vector<std::map<std::string, std::vector<Output>>> results(numThreads); // key is cluster name, value is vector of pairwise motif comparisons;
    // results will be sotred serpately for each cluster to make later MTC stuff more efficient

    writeProgress(progressFile, "Reading inputs...", 0.0);

    if (!loadFiles(inputDir, genesFile, promotersFile, binThreshFile, ICFile, fimoDir, promSizes, topNthreshold, ICvalues, clusters, fimoFiles, results))
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

    for (long m = 0; m < numFimoFiles; ++m) // read each file
        allMotifs[m].readFimoFile(fimoDir + fimoFiles[m], inputDir, ICvalues, topNthreshold, &missingValues);
    std::cout << "Done" << std::endl;
    if (missingValues)
        exit(1);

    // now do all pair-wise comparisons
    long numComplete = 0;

    msgString.str("");
    msgString << "Perfomed 0 of " << totalComparisons << " pair-wise comparisons" << std::endl;
    writeProgress(progressFile, msgString.str(), inc);

    std::cout << std::unitbuf; // no buffering, print immediatley
    std::cout << msgString.str();
    std::cout << " 10%" << std::endl;

    motifComparison mComp; // represents one line in the results file

    // The idea of parallel computing:
    // distribute motifs into each thread, to have sum of motifs' comparsions relatively equal in each thread.
    // be aware that, the motifs are divided into n+1 threads, instead of n threads.
    int numMotifs = std::distance(allMotifs.begin(), allMotifs.end());
    std::vector<int> numMotifsPairComparasionVector(numMotifs);
    for (int i = 0; i < numMotifs; i++)
        numMotifsPairComparasionVector[i] = i;
    std::vector<std::vector<int>> motifsInThread = fairDivision(numMotifsPairComparasionVector, numThreads);

    // allocate space for results of motifs' comparsios
    for (int i = 0; i < numThreads - 1 + 1; i++)
    { // per thread
        std::cout << "Reserve storage for results of Thread: " << i + 1 << std::endl;
        for (std::map<std::string, std::vector<Output>>::iterator j = results[i].begin(); j != results[i].end(); j++)
        { // per cluster
            int spaceNeeded = 0;
            for (int comparsionOfoneMotif : motifsInThread[i])
                spaceNeeded += comparsionOfoneMotif;
            std::cout << "      Storage needed by cluster " << j->first << " is " << spaceNeeded << std::endl;
            (j->second).reserve(totalComparisons);
        }
    }

    // setup computing in n threads
    std::vector<std::thread> threads(numThreads - 1);
    for (int i = 0; i < numThreads - 1; ++i)
    {
        std::cout << "----------------------------   Thread " << i + 1 << " is running  ----------------------------" << std::endl;

        threads[i] = std::thread(outputParallel,
                                 motifsInThread[i],
                                 &allMotifs,
                                 clusters, mComp, &results[i], ICthreshold, promSizes, numComplete, totalComparisons,
                                 outputDirName);
    }
    // setup n+1 thread
    std::cout << "----------------------------   Thread " << numThreads << " is running  ----------------------------" << std::endl;
    outputParallel(motifsInThread[numThreads - 1],
                   &allMotifs,
                   clusters, mComp, &results[numThreads - 1], ICthreshold, promSizes, numComplete, totalComparisons,
                   outputDirName);
    // run all threads
    for (auto &entry : threads)
        entry.join();

    // concatenate results from threads
    for (std::vector<std::map<std::string, std::vector<Output>>>::iterator resultsIt = results.begin() + 1; resultsIt != results.end();)
    {
        // append elements of results (from the second to the last) to the first one results[0]
        // consider different clusters of each element from results
        for (auto const &x : results[0])
            results[0][x.first].insert(results[0][x.first].end(), (*resultsIt)[x.first].begin(), (*resultsIt)[x.first].end());
        resultsIt = results.erase(resultsIt); // remove element of threads, keep results[0] only
    }

    std::cout << std::endl
              << "Applying correction factors" << std::endl;
    writeProgress(progressFile, "Applying correction factors", 0.02);
    // Multiple testing corrections
    // global
    long globalBonferroniFactor = numClusters * totalComparisons; // total number of tests performed

    // export results to multiple temp fiels to accelerate
    for (std::map<std::string, std::vector<Output>>::iterator cl = results[0].begin(); cl != results[0].end(); cl++)
    {
        // per cluster. Bonferroni factor is size of cluster. Calculate  Benjamini-Hochberg FDR correction.
        // map will be already sorted on sort on cluster name, sort members by motif1, then motif2
        std::sort((cl->second).begin(), (cl->second).end(), sortComparisons); // cl->second is vector<motifComparison>
        bhCorrection(cl->second);

        int interval = (int)(cl->second).size() / numThreads;
        // initialize threads
        std::vector<std::thread> threads(numThreads);
        for (int i = 0; i < numThreads; i++)
        {
            int beginIndx = i * interval;
            int endIndx = i * interval + interval - 1;
            endIndx = (endIndx >= (cl->second).size() - 1 || i == numThreads - 1) ? (cl->second).size() - 1 : endIndx;

            // std::cout << endIndx << std::endl;
            std::vector<Output> v2 = std::vector<Output>(std::begin(cl->second) + beginIndx, std::begin(cl->second) + endIndx + 1);
            std::cout << outputDirName + "temp_result_" + cl->first + "_" + std::to_string(i) + ".txt"
                      << "预计的大小：" << v2.size() << std::endl;

            threads[i] = std::thread(exportResultParallel,
                                     cl->first,
                                     std::begin(cl->second) + beginIndx,
                                     std::begin(cl->second) + endIndx + 1,
                                     outputDirName + "temp_result_" + cl->first + "_" + std::to_string(i) + ".txt",
                                     globalBonferroniFactor);
        }
        // run all threads
        for (auto &entry : threads)
            entry.join();

        std::cout << std::endl
                  << std::endl;
    }
    // merge temp files
    // open results file, pmet results
    std::ofstream outputFile;
    outputFile.open(outputDirName + outputFileName, std::ios_base::out);
    if (!outputFile.is_open())
    {
        std::cout << "Error openning results file " << (outputDirName + outputFileName) << std::endl;
        exit(1);
    }

    // add header
    Output::writeHeaders(outputFile);

    outputFile.close();

    ProfilerStop();

    std::cout << "Done." << std::endl;
    return 0;
}

void exportResultParallel(std::string cluster, std::vector<Output>::iterator beginIt, std::vector<Output>::iterator endIt, std::string outFile, long globalBonferroniFactor)
{
    // open results file, pmet results
    std::ofstream outputFile;
    outputFile.open(outFile, std::ios_base::out);
    if (!outputFile.is_open())
    {
        std::cout << "Error openning results file " << outFile << std::endl;
        exit(1);
    }

    // print sorted, correcgted compoarisons inb this cluster
    for (std::vector<Output>::iterator mc = beginIt; mc != endIt; mc++)
    {
        outputFile << cluster << '\t'; // cluster name
        mc->printMe(globalBonferroniFactor, outputFile);
    }

    outputFile.close();
}

void writeProgress(const std::string &fname, const std::string &message, float inc)
{
    std::ifstream infile;

    float progress = 0.0;
    std::string oldMessage;

    infile.open(fname, std::ifstream::in);
    if (infile.is_open())
    {
        infile >> progress >> oldMessage;
        infile.close();
    }
    progress += inc;
    std::ofstream outfile;

    outfile.open(fname, std::ofstream::out);

    if (outfile.is_open())
    {
        outfile << progress << "\t" << message << std::endl;
        outfile.close();
    }
}

bool loadFiles(const std::string &path,
               const std::string &genesFile,
               const std::string &promotersFile,
               const std::string &binThreshFile,
               const std::string &ICFile,
               const std::string &fimoDir,
               std::unordered_map<std::string, int> &promSizes,
               std::unordered_map<std::string, double> &topNthreshold,
               std::unordered_map<std::string,
                                  std::vector<double>> &ICvalues,
               std::map<std::string,
                        std::vector<std::string>> &clusters,
               std::vector<std::string> &fimoFiles,
               std::vector<std::map<std::string,
                                    std::vector<Output>>> &results)
{
    std::cout << "Reading input files..." << std::endl;

    // get promoter lengths. These are stored in tsv file "Name  length"
    std::stringstream promFileContent;
    fastFileRead(path + promotersFile, promFileContent); // reads into a single string

    std::string geneID, len;

    while (promFileContent >> geneID >> len)
        promSizes.emplace(geneID, stoi(len)); // key is genID, value is promoter length

    std::cout << "Universe size is " << promSizes.size() << std::endl;

    std::stringstream binFileContent;
    // same for binomial thresholds
    fastFileRead(path + binThreshFile, binFileContent); // reads into a single string

    std::string motifID, threshold;

    while (binFileContent >> motifID >> threshold)
        topNthreshold.emplace(motifID, stof(threshold));

    // Information Content values. Here there is a float value for each position in the motif

    std::ifstream ifs(path + ICFile);

    if (!ifs)
    {
        std::cout << "Error: Cannot open file " << path + ICFile << std::endl;
        return false;
    }

    std::string line;
    while (std::getline(ifs, line))
    {
        std::istringstream ics(line);
        double score;
        ics >> motifID;

        ICvalues.emplace(motifID, std::vector<double>());

        while (ics >> score)
            ICvalues[motifID].push_back(score);
    }

    // gene clusters

    std::stringstream geneFileContent;
    std::string clusterID;

    fastFileRead(genesFile, geneFileContent);

    long genesFound = 0;

    std::map<std::string, std::vector<std::string>>::iterator got;
    while (geneFileContent >> clusterID >> geneID)
    {
        // vector of genes for each cluster
        if ((got = clusters.find(clusterID)) == clusters.end())
        {
            clusters.emplace(clusterID, std::vector<std::string>());

            for (int i = 0; i < results.size(); i++)
            {
                // initialise results vector for this cluster
                results[i].emplace(clusterID, std::vector<Output>());
            }
        }

        clusters[clusterID].push_back(geneID);
        genesFound++;
    }
    std::cout << "Found " << genesFound << " gene IDs in " << clusters.size() << " clusters" << std::endl;

    // need to sort clustrer first oc can find intersection efficiently.
    for (auto &cl : clusters)
        std::sort(cl.second.begin(), cl.second.end());

    // list of fimo files

    std::string searchDir = fimoDir;

    DIR *pDir = opendir(searchDir.c_str());

    if (!pDir)
    {
        std::cout << "Error: Cannot find directory " << searchDir << std::endl;
        return false;
    }

    struct dirent *fp;
    while ((fp = readdir(pDir))) // exclude "." and ".."
        if (fp->d_name[0] != '.')
            fimoFiles.push_back(fp->d_name);

    closedir(pDir);

    // sort, excluding .txt part
    std::sort(fimoFiles.begin(), fimoFiles.end(), [](const std::string &a, const std::string &b)
              { return (a.compare(0, a.size() - 4, b, 0, b.size() - 4) < 0); });

    //  if (std::filesystem::exists(searchDir) && std::filesystem::is_directory(searchDir)){
    //    for (const auto & entry : std:filesystem::directory_iterator(searchDir))
    //      fimoFiles.push_back(entry.path().string());
    // }

    return true;
}

bool fastFileRead(std::string filename, std::stringstream &results)
{
    // fast way to read a text file into memory
    // reads entire file into results and returns number of lines

    long flength;
    long numLines = 0;
    bool success = false;

    std::ifstream ifs(filename, std::ifstream::binary);

    if (!ifs)
    {
        std::cout << "Error: Cannot open file " << filename << std::endl;
        exit(1);
    }

    ifs.seekg(0, ifs.end);
    flength = ifs.tellg();
    ifs.seekg(0, ifs.beg);

    std::string buffer(flength, '\0');

    if (!ifs.read(&buffer[0], flength))
        std::cout << "Error reading file " << filename << std::endl;
    else
    {
        results.str(buffer);
        success = true;
    }

    ifs.close();

    if (success)
    {
        // count number of lines read
        numLines = std::count(std::istreambuf_iterator<char>(results), std::istreambuf_iterator<char>(), '\n');
        // in case no \n on last line
        results.unget();
        if (results.get() != '\n')
            numLines++;
        // reset iterator
        results.seekg(0);
    }
    else
        exit(1);

    return numLines;
}

bool validateInputs(const std::unordered_map<std::string, int> &promSizes, const std::unordered_map<std::string, double> &topNthreshold, const std::unordered_map<std::string, std::vector<double>> &ICvalues, const std::map<std::string, std::vector<std::string>> &clusters, const std::vector<std::string> fimoFiles)
{
    std::cout << "Validating inputs...";

    if (clusters.empty())
    {
        std::cout << "Error : No gene clusters found!" << std::endl;
        return false;
    }

    if (fimoFiles.empty())
    {
        std::cout << "Error : FIMO files not found!" << std::endl;
        return false;
    }

    if (topNthreshold.empty())
    {
        std::cout << "Error : Binomial threshold values not found!" << std::endl;
        return false;
    }

    if (ICvalues.empty())
    {
        std::cout << "Error : Information Content values not found!" << std::endl;
        return false;
    }

    if (promSizes.empty())
    {
        std::cout << "Error : No promoter sizes found!" << std::endl;
        return false;
    }

    bool noError = true;
    // promsizes must contain a value for every input gene
    for (auto cl = std::begin(clusters); cl != std::end(clusters); cl++)
    {
        for (auto gene = std::begin(cl->second); gene != std::end(cl->second); gene++)
        {
            // does this key exist?
            if (promSizes.find(*gene) == promSizes.end())
            {
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

void bhCorrection(std::vector<Output> &motifs)
{
    // get list of all pvals fo rthis cluster, retaining original index position

    std::vector<std::pair<long, double>> pValues;
    long n = motifs.size();

    pValues.reserve(n);

    for (long i = 0; i < n; i++)
        pValues.push_back(std::make_pair(i, motifs[i].getpValue()));

    // sort descendingie largest p val first
    std::sort(pValues.begin(),
              pValues.end(),
              [](const std::pair<long, double> &a, const std::pair<long, double> &b)
              { return a.second > b.second; });

    // now multiply each p value by a factor based on its position in the sorted list
    for (long i = 0; i < n; i++)
    {
        pValues[i].second *= (n / (n - i));
        if (i && pValues[i].second > pValues[i - 1].second)
            pValues[i].second = pValues[i - 1].second;

        motifs[pValues[i].first].setBHCorrection(pValues[i].second); // assign corrected value to its original index position before sort
    }
}

std::vector<std::vector<int>> fairDivision(std::vector<int> input, int numGroups)
{
    std::vector<std::vector<int>> resultVector;
    if (numGroups >= input.size())
    {
        resultVector.resize(input.size());
        for (int i = 0; i < input.size(); i++)
        {
            resultVector[i] = {input[i]};
        }
    }

    resultVector.resize(numGroups);

    std::sort(input.begin(), input.end(), std::greater<int>());

    // 从最大的开始填充到结果中
    for (int i = 0; i < numGroups; i++)
        resultVector[i] = {input[i]};

    // 从大到小遍历剩下的数字
    for (int i = numGroups; i < input.size(); i++)
    {
        std::vector<int> tempSum(numGroups); // a temp vector to keep sum of each group

        for (int j = 0; j < resultVector.size(); j++)
            tempSum[j] = SumVector(resultVector[j]) + input[i];

        int minIndex = min_element(tempSum.begin(), tempSum.end()) - tempSum.begin(); // 找出当前和最小的分组
        resultVector[minIndex].push_back(input[i]);                                   // add the max of the rest numbers to the group with min sum
    }
    return resultVector;
}

int SumVector(std::vector<int> &vec)
{
    int res = 0;
    for (size_t i = 0; i < vec.size(); i++)
        res += vec[i];
    return res;
}

int output(std::vector<motif>::iterator blockstart, std::vector<motif>::iterator blockEnd, std::vector<motif>::iterator last, std::map<std::string, std::vector<std::string>> clusters, motifComparison mComp,
           std::map<std::string, std::vector<Output>> *results, double ICthreshold, std::unordered_map<std::string, int> promSizes, long numComplete, long totalComparisons, std::string outputDirName)
{
    for (std::vector<motif>::iterator motif1 = blockstart; motif1 != blockEnd; ++motif1)
    {
        for (std::vector<motif>::iterator motif2 = motif1 + 1; motif2 != last; ++motif2)
        {
            mComp.findIntersectingGenes(*motif1, *motif2, ICthreshold, promSizes); // sets genesInUniverseWithBothMotifs, used in Coloc Test
            // got shared genes so do test for each cluster
            for (auto &cl : clusters)
            {
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
int outputParallel(std::vector<int> motifsIndxVector,
                   std::vector<motif> *allMotifs,
                   std::map<std::string, std::vector<std::string>> clusters,
                   motifComparison mComp,
                   std::map<std::string, std::vector<Output>> *results,
                   double ICthreshold,
                   std::unordered_map<std::string, int> promSizes,
                   long numComplete,
                   long totalComparisons,
                   std::string outputDirName)
{

    for (int i : motifsIndxVector)
    {
        motif motif1 = (*allMotifs)[i];
        for (int j = i + 1; j < (*allMotifs).size(); j++)
        {
            motif motif2 = (*allMotifs)[j];

            mComp.findIntersectingGenes(motif1, motif2, ICthreshold, promSizes); // sets genesInUniverseWithBothMotifs, used in Coloc Test
            // got shared genes so do test for each cluster
            for (auto &cl : clusters)
            {
                mComp.colocTest(promSizes.size(), ICthreshold, cl.first, cl.second);
                (*results)[cl.first].push_back(Output(motif1.getMotifName(), motif2.getMotifName(), mComp));
                // std::cout   << cl.first << " " << motif1.getMotifName() << " " << motif2.getMotifName()
                //             << " " << mComp.getSharedGenesInCluster().size() << " "  << mComp.getpValue() << std::endl;
            }
        }
    }
    return 1;
}