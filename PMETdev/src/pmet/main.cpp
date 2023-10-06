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
#include "utils.hpp"

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

  // ================================= Loading Inputs =================================
  writeProgress(progressFile, "Reading inputs...", 0.0);

  // If the files cannot be loaded, exit the program with an error code (1).
  if (!loadFiles(inputDir, genesFile, promotersFile, binThreshFile, ICFile, fimoDir, promSizes, topNthreshold, ICvalues, clusters, fimoFiles, results))
    exit(1);

  // ================================ Validating Inputs ================================

  // Validate the inputs (promSizes, topNthreshold, ICvalues, clusters, fimoFiles).
  // If any of the inputs are invalid, exit the program with an error code (1).
  // Otherwise, proceed with the computations for each pair-wise comparison of fimo files.
  if (!validateInputs(promSizes, topNthreshold, ICvalues, clusters, fimoFiles)) {
    exit(1);
  }

  // For each pair-wise comparison of fimo files
  long numClusters      = clusters.size();
  long numFimoFiles     = fimoFiles.size();
  long totalComparisons = (numFimoFiles * numFimoFiles - numFimoFiles) / 2;

  // Create a vector to store all motif instances from fimo files
  std::vector<motif> allMotifs(numFimoFiles, motif());

  // Initialize a flag to check if there are any missing values while reading the fimo files.
  bool missingValues = false;

  msgString << "Reading " << fimoFiles.size() << " FIMO files..." << std::endl;
  std::cout << msgString.str();
  writeProgress(progressFile, msgString.str(), inc);

  // Read each fimo file and store the motif instances in the 'allMotifs' vector.
  for (long m = 0; m < numFimoFiles; ++m)
    allMotifs[m].readFimoFile(fimoDir + fimoFiles[m], inputDir, ICvalues, topNthreshold, &missingValues);
  std::cout << "Done" << std::endl;

  // If any missing values were encountered while reading the fimo files, exit the program with an error code (1).
  if (missingValues)
    exit(1);


  // ============================ Reserve storage for results ============================
  for (std::map<std::string, std::vector<Output>>::iterator i = results.begin(); i != results.end(); i++)  // for each cluster
             //(i->second).resize(totalComparisons, motifComparison());
    // For each cluster (i.e., each key in the 'results' map), reserve space in the vector
    // to accommodate 'totalComparisons' elements. Each element in the vector will be of type 'motifComparison'.
    // The purpose is to preallocate memory to reduce potential reallocations during vector resizing.
    (i->second).reserve(totalComparisons);

  // =============================== Pair-wise Comparisons ================================
  long numComplete = 0;

  msgString.str("");
  msgString << "Perfomed 0 of " << totalComparisons << " pair-wise comparisons" << std::endl;
  writeProgress(progressFile, msgString.str(), inc);
  std::cout << std::unitbuf;  // no buffering, print immediatley
  std::cout << msgString.str();
  std::cout << " 10%";

  motifComparison mComp;
  // Loop through allMotifs to perform pair-wise comparisons
  for (std::vector<motif>::iterator motif1 = allMotifs.begin(); motif1 != allMotifs.end() - 1; ++motif1) {
    // Nested loop to compare motif1 with all motifs that come after it in the allMotifs vector
    for (std::vector<motif>::iterator motif2 = motif1 + 1; motif2 != allMotifs.end(); ++motif2) {
      // do test on all clusters for this pair of fimo files
      // sets genesInUniverseWithBothMotifs, used in Coloc Test
      // Perform a test to find intersecting genes between motif1 and motif2 and store the result in genesInUniverseWithBothMotifs
      mComp.findIntersectingGenes(*motif1, *motif2, ICthreshold, promSizes);

      // Perform the colocTest for each cluster to assess co-localization of motif1 and motif2 in the genes of the cluster
      // Store the results in the 'results' map under the cluster name as the key
      for (auto& cl : clusters) {
        mComp.colocTest(promSizes.size(), ICthreshold, cl.first, cl.second);
        results[cl.first].push_back(Output(motif1->getMotifName(), motif2->getMotifName(), mComp));
      }

      // Update and display progress message
      std::cout << "\b\b\b";
      double progVal = 0.1 + double(0.8 * ++numComplete) / totalComparisons;
      std::cout << std::setw(2) << long(progVal * 100) << "%";
    }

    // Update and write progress information to a file after each motif1 has been compared with all motifs in the list
    msgString << "Perfomed " << numComplete << " of " << totalComparisons << " pair-wise comparisons" << std::endl;
    writeProgress(progressFile, msgString.str(), 0.0);
  }

  // ======================= Applying correction and save result ===============================
  std::ofstream outputFile;
  outputFile.open(outputDirName + outputFileName, std::ios_base::out);

  // Check if the output file is successfully opened
  if (!outputFile.is_open()) {
    std::cout << "Error openning results file " << (outputDirName + outputFileName) << std::endl;
    exit(1);
  }

  // Write headers to the output file
  Output::writeHeaders(outputFile);

  std::cout << std::endl << "Applying correction factors" << std::endl;
  writeProgress(progressFile, "Applying correction factors", 0.02);

  // Multiple testing corrections
  // Perform correction for each cluster using the Benjamini-Hochberg FDR correction method.
  // The Bonferroni factor for each cluster is equal to the size of the cluster multiplied by
  // the total number of pairwise comparisons performed.
  // The results are sorted based on cluster names, and then the motif comparisons are sorted
  // in ascending order using the sortComparisons function.
  long globalBonferroniFactor = numClusters * totalComparisons;  // Total number of tests performed
  for (std::map<std::string, std::vector<Output>>::iterator cl = results.begin(); cl != results.end(); cl++) {
    // cl->second is vector<motifComparison>

    // Sort the motif comparisons for each cluster
    std::sort((cl->second).begin(), (cl->second).end(), sortComparisons);

    // Apply Benjamini-Hochberg FDR correction to the motif comparisons
    bhCorrection(cl->second);

    // Print sorted, corrected comparisons in this cluster to the output file
    for (std::vector<Output>::iterator mc = std::begin(cl->second); mc != std::end(cl->second); mc++) {
      outputFile << cl->first << '\t';  // cluster name
      mc->printMe(globalBonferroniFactor, outputFile);
    }
  }
  outputFile.close();

  std::cout << "Done." << std::endl;
  writeProgress(progressFile, "Done", 0.0);
  return 0;
}

