//
//  motif.cpp
//  PMET
//
//  Created by Paul Brown on 02/08/2019.
//  Copyright © 2019 Paul Brown. All rights reserved.
//

#include "motif.hpp"

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

bool sortHits(const motifInstance &a, const motifInstance &b) {
  // sort ascending
  return (a.getPValue() < b.getPValue());
}

void motif::setMotifName(const std::string &motif) { motifName = motif; }

std::string motif::getMotifName() const { return motifName; }

void motif::setThreshold(double thresh) { binomialThreshold = thresh; }

double motif::getThreshold() const { return binomialThreshold; }

bool motif::readFimoFile(const std::string filename, const std::string path,
                         std::unordered_map<std::string, std::vector<double>> &ICvalues,
                         std::unordered_map<std::string, double> &topNthreshold, bool *missingValues) {
  // filename is also name of motif
  // path is parent dir of fimohits dir

  instances.clear();

  // get size of file
  long flength;
  bool success = false;

  std::ifstream ifs(filename, std::ifstream::binary);

  if (!ifs) {
    std::cout << "Error: Cannot open fimo file " << filename << std::endl;
    return success;
  }

  ifs.seekg(0, ifs.end);
  flength = ifs.tellg();
  ifs.seekg(0, ifs.beg);

  // read all file in to memory

  std::string buffer(flength, '\0');
  std::stringstream results;

  if (!ifs.read(&buffer[0], flength))
    std::cout << "Error reading fimo file " << filename << std::endl;
  else {
    results.str(buffer);
    success = true;
  }

  ifs.close();

  if (success) {
    std::string motif, gene, seq, strand;
    int first, last;
    double p1, p2;

    // read 1 line, ie one occurenace of motif
    results >> motif >> gene >> first >> last >> strand >> p1 >> p2 >> seq;

    // These parts will be same fo revery line
    motifName = motif;  // in case different from file name
    motifLength = last - first + 1;

    if (ICvalues.find(motifName) == ICvalues.end()) {
      std::cout << "Error : Motif " << motifName << " not found in IC file!" << std::endl;
      *missingValues = true;
    } else {
      IC = ICvalues[motifName];

      if (IC.size() != motifLength) {
        std::cout << "Error : Motif " << motifName << "  IC values do not correspopnd to length of motif ("
                  << motifLength << ")!" << std::endl;
        std::cout << "file=" << filename << std::endl;
        *missingValues = true;
      }
    }

    if (topNthreshold.find(motifName) == topNthreshold.end()) {
      std::cout << "Error : Motif " << motifName << " not found in binomial thresholds file!" << std::endl;
      *missingValues = true;
    } else
      binomialThreshold = topNthreshold[motifName];

    // This creares an empty vector if key (gene id) doesn't exist. Returns a poibnter to the key / new or existing
    // vector pair
    std::pair<std::unordered_map<std::string, std::vector<motifInstance>>::iterator, bool> iter =
        instances.emplace(gene, std::vector<motifInstance>());

    //   std::vector<motifInstance>  motifPositions = (iter.first)->second;
    instances[gene].push_back(motifInstance(first, last, strand, p1, p2, seq));

    //      motifPositions.push_back(motifInstance(first, last, strand, p1, p2, seq));

    // reads rest of file
    while (results >> motif >> gene >> first >> last >> strand >> p1 >> p2 >> seq) {
      iter = instances.emplace(gene, std::vector<motifInstance>());
      // motifPositions = (iter.first)->second;
      //  motifPositions.push_back(motifInstance(first, last, strand, p1, p2, seq));

      instances[gene].push_back(motifInstance(first, last, strand, p1, p2, seq));
    }

    // for later analysis, sort instances in the same promoter by p2 value

    long totalHits = 0;

    for (auto &hit : instances) {
      std::sort(hit.second.begin(), hit.second.end(), sortHits);
      totalHits += hit.second.size();
    }

    std::cout << "Motif " << motifName << " has " << totalHits << " occurrences in " << instances.size() << "  genes"
              << std::endl;
  }

  return success;  // will be true as long as this fimo file read ok but if missingValues set then program will stop
                   // after all fimo files read
}

void motif::getListofGenes(std::vector<std::string> &genes) {
  // get keys from map. This is every gene in universe that has this motif

  genes.reserve(instances.size());

  for (std::unordered_map<std::string, std::vector<motifInstance>>::iterator it = instances.begin();
       it != instances.end(); it++)
    genes.push_back(it->first);

  // list must be sorted so we can get intersect with another motif
  std::sort(genes.begin(), genes.end());
}

long motif::getNumInstances(std::string geneID) { return instances[geneID].size(); }

motifInstance &motif::getInstance(std::string gene, long idx) { return instances[gene][idx]; }

double motif::getForwardICScore(int overlapLength) const {
  // fwdIC is defined as the sum of the IC of the overlap from the beginning of the  motif

  double score = 0.0;

  for (long i = 0; i < overlapLength; i++) score += IC[i];

  return score;
}

double motif::getReverseICScore(int overlapLength) const {
  // revIC is defined as the sum of IC in the overlapping end of motif

  double score = 0.0;

  for (long i = (IC.size() - overlapLength); i < IC.size(); i++) score += IC[i];

  return score;
}

int motif::getLength() const { return motifLength; }
