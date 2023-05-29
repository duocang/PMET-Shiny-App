//  Created by Paul Brown on 06/05/2020.
//  Copyright © 2020 Paul Brown. All rights reserved.
//

#include "cFimoFile.hpp"

#include <limits>
#include <sstream>
#include <stdexcept>

bool cFimoFile::readFile(bool hasBinScore) {
  std::stringstream fileContent;
  std::cout << "\tReading file...0%\r";
  numLines = ffr.getContent(fileName, fileContent);  // reads into a single string

  std::string motif, motifAlt, geneID, sequence;
  long start, stop;
  char strand;
  double score, pval;
  long line = 0;

  // discard first header line

  char ch = '\0';
  while (ch != '\n') ch = fileContent.get();

  if (hasBinScore) {
    double binScore;

    // qval column is empty???
    while (fileContent >> motif >> motifAlt >> geneID >> start >> stop >> strand >> score >> pval >> sequence >>
           binScore) {
      // each line is a single motif instance
      if (!motifName.length()) {
        motifName = motif;  // same on every line
        motifLength = (stop - start) + 1;
      }
      // create hit instance and add to fimoHits with geneID as key
      fimoHits.emplace(geneID, std::vector<cMotifHit>());  // create empty vector this gene if not yet done
      fimoHits[geneID].push_back(cMotifHit(start, stop, strand, score, pval, sequence, binScore));

      if (!(++line % 1000))
        std::cout << "\tReading file..." << int((100.0 * line) / numLines) << "%\r";
    }
  } else {
    while (fileContent >> motif >> motifAlt >> geneID >> start >> stop >> strand >> score >> pval >> sequence) {
      // each line is a single motif instance
      if (!motifName.length()) {
        motifName = motif;  // same on every line
        motifLength = (stop - start) + 1;
      }
      // create hit instance and add to fimoHits with geneID as key
      fimoHits.emplace(geneID, std::vector<cMotifHit>());  // create empty vector this gene if not yet done
      fimoHits[geneID].push_back(cMotifHit(start, stop, strand, score, pval, sequence));

      if (!(++line % 1000))
        std::cout << "\tReading file..." << int((100.0 * line) / numLines) << "%\r";
    }
  }
  std::cout << std::endl << "\t" << fimoHits.size() << " genes and " << numLines << " hits found" << std::endl;

  return true;
}

std::pair<std::string, double> cFimoFile::process(long k, long N, std::unordered_map<std::string, long> &promSizes) {
  binThresholds.reserve(fimoHits.size());
  long numDone = 0;

  for (auto &hit : fimoHits) {
    std::cout << "\tProcessing gene " << ++numDone << " of " << fimoHits.size() << "\r";

    // sort hits within gene on p val
    std::sort(hit.second.begin(), hit.second.end(), sortHits);

    const std::string &geneID = hit.first;

    // remove overlaps
    for (std::vector<cMotifHit>::iterator m1 = hit.second.begin(); m1 < (hit.second.end()); m1++) {
      // take top k of remaining
      if (m1 == (hit.second.begin() + (k - 1))) {  // pointing a kth hit, delete all later ones
        hit.second.resize(k);
        break;
      }

      std::vector<cMotifHit>::iterator m2 = m1 + 1;

      while (m2 != hit.second.end()) {
        if (motifsOverlap(*m1, *m2))
          hit.second.erase(m2);  // m2 now points to one beyond erased element, or end() if last erased
        else
          m2++;
      }
    }
    // now have a list of top k hits for a gene, sorted by p-val with no overlaps
    // binomial test
    // first get promoter size

    // promsizes must contain a value for every input gene
    std::unordered_map<std::string, long>::const_iterator promLen = promSizes.find(geneID);
    // hit.first is gene name

    if (promLen == promSizes.end()) {
      std::cout << "Error : Gene ID " << geneID << " not found in promoter lengths file!" << std::endl;
      exit(1);
    }

    std::pair<long, double> binom_p = geometricBinTest(hit.second, promLen->second);

    // save best bin value for this gene
    binThresholds.push_back(std::pair<double, std::string>(binom_p.second, geneID));
    // its index val indicates number of motifs to save to fimohits file

    if (hit.second.size() > (binom_p.first + 1))
      hit.second.resize(binom_p.first + 1);
    // done for this gene
  }

  std::cout << std::endl << "\tWriting outputs: " + outDir + motifName + ".txt" << std::endl;
  // sort bin thresholds by ascending score

  std::sort(binThresholds.begin(), binThresholds.end(),
            [](const std::pair<double, std::string> &a, const std::pair<double, std::string> &b) {
              return a.first < b.first;
            });

  // save Nth best to thresholds file, noting all gene sin topN
  if (binThresholds.size() > N)
    binThresholds.resize(N);
  // take remaining hits
  // any that apply to a gene in topN, write to file

  std::stringstream hitsfile;
  hitsfile << outDir << motifName << ".txt";

  std::ofstream oFile(hitsfile.str(), std::ofstream::out);
  for (auto &hit : fimoHits) {
    const std::string geneID = hit.first;
    std::vector<cMotifHit> &hitsForGene = hit.second;
    // is gene in binThresholds?
    auto binVal = std::find_if(binThresholds.begin(), binThresholds.end(),
                               [&geneID](const std::pair<double, std::string> a) { return a.second == geneID; });

    //  if (std::find_if(binThresholds.begin(), binThresholds.end(), [&geneID](const std::pair<double, std::string> a)
    //  {return a.second==geneID;}) != binThresholds.end()) {
    if (binVal != binThresholds.end()) {
      // write all hits for this gene
      for (std::vector<cMotifHit>::iterator it = hitsForGene.begin(); it != hitsForGene.end(); it++)
        oFile << motifName << "\t" << geneID << "\t" << *it << std::endl;
      // oFile << motifName << "\t" << geneID << "\t" << *it << "\t" << binVal->first << std::endl;
    }
  }
  oFile.close();

  // return Nth best value to save in thresholds file
  double thresholdScore = (binThresholds.end() - 1)->first;
  return std::pair<std::string, double>(motifName, thresholdScore);
}

bool cFimoFile::motifsOverlap(cMotifHit &m1, cMotifHit &m2) {
  // m2 will be removed if it overlqps m1

  return !(m2.getStartPos() > m1.getEndPos() || m2.getEndPos() < m1.getStartPos());
}

std::pair<long, double> cFimoFile::geometricBinTest(const std::vector<cMotifHit> &hits, const long promoterLength) {
  long possibleLocations = 2 * (promoterLength - motifLength + 1);

  std::vector<double> pVals;
  pVals.reserve(hits.size());

  for (int i = 0; i < hits.size(); i++) pVals.push_back(hits[i].getPVal());

  // motif instances have already been sorted and so pVsls will be in ascending order
  // calculate geomtric mean of all included p-vals
  double lowestScore = std::numeric_limits<double>::max();
  long lowestIdx = hits.size() - 1;
  double product = 1.0;

  for (long k = 0; k < pVals.size(); k++) {
    // calculate geomtric mean of all  p-vals up to k
    product *= pVals[k];
    double geom = pow(product, 1.0 / (double(k) + 1.0));

    double binomP = 1 - binomialCDF(k + 1, possibleLocations, geom);

    if (lowestScore > binomP) {
      lowestScore = binomP;
      lowestIdx = k;
    }
  }
  return std::pair<long, double>(lowestIdx, lowestScore);
}

double cFimoFile::binomialCDF(long numPVals, long numLocations, double gm) {
  // gm is geometric mean
  double cdf = 0.0;
  double b = 0.0;

  double logP = log(gm);
  double logOneMinusP = log(1 - gm);

  for (int k = 0; k < numPVals; k++) {
    if (k > 0)
      b += log(numLocations - k + 1) - log(k);
    cdf += exp(b + k * logP + (numLocations - k) * logOneMinusP);
  }
  return cdf;
}
