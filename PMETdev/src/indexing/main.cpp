//  Created by Paul Brown on 04/05/2020.
//  Copyright © 2020 Paul Brown. All rights reserved.

// g++ -I. -I/usr/local/include -L/usr/local/lib --std=c++11 main.cpp cFimoFile.cpp fastFileReader.cpp cMotifHit.cpp -O3
// -o pmetindex

#include <dirent.h>
#include <gperftools/profiler.h>

#include <fstream>
#include <iostream>
#include <regex>
#include <sstream>
#include <string>
#include <unordered_map>
#include <vector>

#include "cFimoFile.hpp"

void printHelp();
bool findFiles(const std::string &searchDir, const std::string &pattern, std::vector<std::string> &filesFound);
void writeProgress(const std::string &fname, const std::string &message, float inc, float total);

int main(int argc, const char *argv[]) {
  ProfilerStart("pmetindex.prof");
  // replicates the python script parse_matrix_n.py, excpet that it loops over all fimo files

  // inputs are
  //-f - fimodir, directorty to search for fimo files (fimo_*.txt)
  //-k - Maximum motif hits allowed within each promoter. Default value is 5
  //-n - How many top promoter hits to take per motif. Default is 5000
  //-o - output directory.
  //-g progress file. We want to increment progress by 25% here
  //-p promoter lengths file

  // output are a file called outDir/binomial_thresholds.txt and hits files in
  // outDir/fimohits/

  //   std::string data;
  //  std::cin>>data; //pipe input

  // default inputs
  std::string fimoDir("./fimo/");
  std::string fimoHitsDir("fimohits/");
  std::string outDir(".");
  std::string promotersFile("promoter_lengths.txt");
  std::string progressFile("/Users/paulbrown/Desktop/progress.txt");
  float totalProgress = 0.25;  // This binary represent 25% of the total time takren by PMET
  // TODO : allow input param to alter this

  long NHits = 5000;
  long kHits = 5;

  const std::string fimoName = "*.txt";
  const std::string fimoRegExp = "[a-zA-Z0-9._]+\\.txt";
  const std::string binThreshFile("binomial_thresholds.txt");

  bool binScore =
      false;  // if true, use alternate fimo file format with extra col 'binary score'. Not used but has to be read
  bool hasMotifAlt = true;  // set true when there is motif_alt_id in meme file.

  int i = 0;
  while (++i < argc) {
    if (!strcmp(argv[i], "-h")) {
      printHelp();
      return 0;
    } else if (!strcmp(argv[i], "-b"))
      binScore = true;
    else if (!strcmp(argv[i], "-k"))
      kHits = atof(argv[++i]);
    else if (!strcmp(argv[i], "-n"))
      NHits = atof(argv[++i]);
    else if (!strcmp(argv[i], "-f"))
      fimoDir = argv[++i];
    else if (!strcmp(argv[i], "-o"))
      outDir = argv[++i];
    else if (!strcmp(argv[i], "-a"))
      hasMotifAlt = false;
    else if (!strcmp(argv[i], "-p"))
      promotersFile = argv[++i];
    else if (!strcmp(argv[i], "-g"))
      progressFile = argv[++i];
    else {
      std::cerr << "Error: unknown command line switch " << argv[i] << std::endl;
      return 1;
    }
  }

  if (outDir.back() != '/')
    outDir += "/";

  if (fimoDir.back() != '/')
    fimoDir += "/";

  // ok, display inputs
  std::cout << "          Input parameters          " << std::endl;
  std::cout << "------------------------------------" << std::endl;
  std::cout << "fimo files\t\t" << fimoDir << fimoName << std::endl;
  std::cout << "promoters file\t\t" << promotersFile << std::endl;
  std::cout << "k\t\t\t" << kHits << std::endl;
  std::cout << "n\t\t\t" << NHits << std::endl;
  std::cout << "output directory\t" << outDir << std::endl;

  // read promoters file
  writeProgress(progressFile, "Reading inputs...", 0.0, totalProgress);
  std::stringstream promFileContent;
  std::unordered_map<std::string, long> promSizes;

  cFastFileReader ffr;
  ffr.getContent(promotersFile, promFileContent);  // reads into a single string

  std::string geneID, len;

  while (promFileContent >> geneID >> len)
    promSizes.emplace(geneID, stoi(len));  // key is genID, value is promoter length

  std::cout << "Universe size is " << promSizes.size() << std::endl;

  // loop for every file in fimoDir whose name starts "fimo_"
  std::cout << "Searching for fimo files...";

  std::vector<std::string> fimoFiles;

  if (!findFiles(fimoDir, fimoRegExp, fimoFiles))
    exit(1);

  long numFimoFiles = fimoFiles.size();
  std::cout << "Found " << numFimoFiles << std::endl;

  if (!numFimoFiles)  // no files
    return 1;

  // Got fimo files
  // process each one, writing threshold bin score to file

  std::ofstream btFile;
  btFile.open(outDir + binThreshFile, std::ios_base::app);

  float inc = totalProgress / numFimoFiles;

  for (long f = 0; f < numFimoFiles; f++) {
    std::stringstream message;
    message << "Processing file " << (f + 1) << " of " << numFimoFiles << std::endl;
    std::cout << message.str();
    writeProgress(progressFile, message.str(), inc, totalProgress);

    cFimoFile fimo(fimoDir + fimoFiles[f], outDir + fimoHitsDir, hasMotifAlt);  // read file
    fimo.readFile(binScore);
    std::pair<std::string, double> btVals = fimo.process(kHits, NHits, promSizes);

    // motif binscore
    btFile << btVals.first << "\t" << btVals.second << std::endl;
  }
  btFile.close();

  std::cout << std::endl << "Done" << std::endl;
  ProfilerStop();
  return 0;
}

void printHelp() {
  std::cout << "Required input arguments" << std::endl << std::endl;

  std::cout << "-b\tUse fimo files with the 10 column format. Use the 9 column format without this argument"
            << std::endl;
  std::cout << "-o\tOutput directory. Default is the current working directory" << std::endl;
  std::cout << "-p\tPromoter lengths file. Default is 'promoter_lengths.txt'" << std::endl;
  std::cout << "-f\tThe name of a directory containing fimo output files. Default is the current working directory."
            << std::endl;
  std::cout << "-k\tMaximum motif hits allowed within each promoter. Default value is 5." << std::endl;
  std::cout << "-n\tHow many top promoter hits to take per motif. Default is 5000" << std::endl;
  std::cout << "-h\tDisplay this message and exit." << std::endl;
}

bool findFiles(const std::string &searchDir, const std::string &pattern, std::vector<std::string> &filesFound) {
  DIR *pDir = opendir(searchDir.c_str());

  if (!pDir) {
    std::cerr << "Error: Cannot find directory " << searchDir << std::endl;
    return false;
  }

  struct dirent *fp;
  std::regex re(pattern);

  while ((fp = readdir(pDir)))  // exclude "." and ".."
    if (std::regex_match(fp->d_name, re))
      filesFound.push_back(fp->d_name);

  closedir(pDir);

  return true;
}

void writeProgress(const std::string &fname, const std::string &message, float inc, float total) {
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
