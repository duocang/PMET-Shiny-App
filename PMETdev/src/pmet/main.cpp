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
#include <math.h>
#include <string.h>
#include <sys/types.h>

#include <iomanip>
#include <iostream>
#include <sstream>
#include <utility>
#include <vector>

#include "Output.hpp"
#include "motif.hpp"
#include "motifComparison.hpp"
#include "utils.cpp"

// take progress up by 5% of total runtime

int main(int argc, const char* argv[]) {
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
  std::string outputFileName("motif_output.txt");

  std::string genesFile("input.txt");
  std::string progressFile("/Users/paulbrown/Desktop/progress.txt");
  // this binary will increase progress by 5% of total run time
  float inc = 0.01;

  double ICthreshold = 4.0;

  std::stringstream msgString;

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
      return 0;
    } else if (!strcmp(argv[i], "-i"))
      ICthreshold = atof(argv[i + 1]);
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

  ensureEndsWith(inputDir, '/');
  ensureEndsWith(outputDirName, '/');
  ensureEndsWith(fimoDir, '/');

  fimoDir = inputDir + fimoDir;

  std::cout << "          Input parameters          "     << std::endl;
  std::cout << "------------------------------------"     << std::endl;
  std::cout << "Input Directory:\t\t\t"                   << inputDir << std::endl;
  std::cout << "Gene list file:\t\t\t\t"                  << genesFile << std::endl;
  std::cout << "IC threshold:\t\t\t\t"                    << ICthreshold << std::endl;
  std::cout << "Promoter lengths:\t\t\t"                  << promotersFile << std::endl;
  std::cout << "Binomial threshold values:\t\t"           << binThreshFile << std::endl;
  std::cout << "Motif IC values:\t\t\t"                   << ICFile << std::endl;
  std::cout << "Fimo files:\t\t\t\t"                      << fimoDir << std::endl;
  std::cout << "Output directory:\t\t\t"                << outputDirName << std::endl;
  std::cout << "------------------------------------"     << std::endl << std::endl;

  std::unordered_map<std::string, int>                 promSizes;
  std::unordered_map<std::string, double>              topNthreshold;
  std::unordered_map<std::string, std::vector<double>> ICvalues;
  std::vector<std::string>                             fimoFiles;
  std::map<std::string, std::vector<std::string>>      clusters;  // ordered map faster to iterate sequentially
  std::map<std::string, std::vector<Output>>           results;  // key is cluster name, value is vector of pairwise motif comparisons;
  // results will be sotred serpately for each cluster to make later MTC stuff more efficient

  // Reading inputs ---------------------------------------------------------------------
  writeProgress(progressFile, "Reading inputs...", 0.0);

  if (!loadFiles(inputDir, genesFile, promotersFile, binThreshFile, ICFile, fimoDir, promSizes, topNthreshold, ICvalues,
                 clusters, fimoFiles, results))
    exit(1);

  if (!validateInputs(promSizes, topNthreshold, ICvalues, clusters, fimoFiles))
    exit(1);

  // Got valid data to proceed

  // For each pair-wise comparison of fimo files
  long numClusters      = clusters.size();
  long numFimoFiles     = fimoFiles.size();
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

  // reseerve storage for results
  for (std::map<std::string, std::vector<Output>>::iterator i = results.begin(); i != results.end(); i++)  // for each cluster
             //(i->second).resize(totalComparisons, motifComparison());
    (i->second).reserve(totalComparisons);  // one element for each pairwise comparison

  // pair-wise comparisons ---------------------------------------------------------------------
  long numComplete = 0;

  msgString.str("");
  msgString << "Perfomed 0 of " << totalComparisons << " pair-wise comparisons" << std::endl;
  writeProgress(progressFile, msgString.str(), inc);
  std::cout << std::unitbuf;  // no buffering, print immediatley
  std::cout << msgString.str();
  std::cout << " 10%";

  motifComparison mComp;

  for (std::vector<motif>::iterator motif1 = allMotifs.begin(); motif1 != allMotifs.end() - 1; ++motif1) {
    for (std::vector<motif>::iterator motif2 = motif1 + 1; motif2 != allMotifs.end(); ++motif2) {
      // do test on all clusters for this pair of fimo files

      // sets genesInUniverseWithBothMotifs, used in Coloc Test
      mComp.findIntersectingGenes(*motif1, *motif2, ICthreshold, promSizes); 
      // got shared genes so do test for each cluster
      for (auto& cl : clusters) {
        mComp.colocTest(promSizes.size(), ICthreshold, cl.first, cl.second);
        results[cl.first].push_back(Output(motif1->getMotifName(), motif2->getMotifName(), mComp));
      }
      // message
      std::cout << "\b\b\b";
      // progress goes from 10 to 90% in this loop
      double progVal = 0.1 + double(0.8 * ++numComplete) / totalComparisons;
      std::cout << std::setw(2) << long(progVal * 100) << "%";
    }
    msgString << "Perfomed " << numComplete << " of " << totalComparisons << " pair-wise comparisons" << std::endl;
    writeProgress(progressFile, msgString.str(), 0.0);
  }

  // Applying correction and save result --------------------------------------------------------------
  std::ofstream outputFile;
  outputFile.open(outputDirName + outputFileName, std::ios_base::out);
  if (!outputFile.is_open()) {
    std::cout << "Error openning results file " << (outputDirName + outputFileName) << std::endl;
    exit(1);
  }
  Output::writeHeaders(outputFile);

  std::cout << std::endl << "Applying correction factors" << std::endl;
  writeProgress(progressFile, "Applying correction factors", 0.02);
  // Multiple testing corrections

  // per cluster. Bonferroni factor is size of cluster. Calculate  Benjamini-Hochberg FDR correction.
  // map will be already sorted on sort on cluster name, sort members by motif1, then motif2
  long globalBonferroniFactor = numClusters * totalComparisons;  // total number of tests performed
  for (std::map<std::string, std::vector<Output>>::iterator cl = results.begin(); cl != results.end(); cl++) {
    // cl->second is vector<motifComparison>
    std::sort((cl->second).begin(), (cl->second).end(), sortComparisons); 

    bhCorrection(cl->second);

    // print sorted, correcgted compoarisons inb this cluster
    for (std::vector<Output>::iterator mc = std::begin(cl->second); mc != std::end(cl->second); mc++) {
      outputFile << cl->first << '\t';  // cluster name
      mc->printMe(globalBonferroniFactor, outputFile);
    }
    // after each cluster completed
  }
  outputFile.close();

  std::cout << "Done." << std::endl;
  writeProgress(progressFile, "Done", 0.0);
  return 0;
}

