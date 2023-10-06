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