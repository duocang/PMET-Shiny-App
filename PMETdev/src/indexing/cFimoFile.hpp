//  Created by Paul Brown on 06/05/2020.
//  Copyright © 2020 Paul Brown. All rights reserved.
//

#ifndef cFimoFile_hpp
#define cFimoFile_hpp

#include <math.h>

#include <map>
#include <string>
#include <unordered_map>
#include <vector>

#include "cMotifHit.hpp"
#include "fastFileReader.hpp"

class cFimoFile {
  // class to represent the content of a fimo file
public:
  cFimoFile(){};
  cFimoFile(const std::string& fname, const std::string& odir, bool hasAlt)
      : fileName(fname), outDir(odir), hasMotifAlt(hasAlt){};
  bool readFile(bool binScore);
  std::pair<std::string, double> process(long k, long N, std::unordered_map<std::string, long>& promSizes);

private:
  bool motifsOverlap(cMotifHit& m1, cMotifHit& m2);
  std::pair<long, double> geometricBinTest(const std::vector<cMotifHit>& motifs, const long promoterLength);
  double binomialCDF(long numPVals, long numLocations, double gm);

  long numLines;
  cFastFileReader ffr;

  std::string motifName;
  long motifLength;
  std::string fileName;
  std::string outDir;

  bool hasMotifAlt;

  std::map<std::string, std::vector<cMotifHit> > fimoHits;
  std::vector<std::pair<double, std::string> > binThresholds;
};

#endif /* cFimoFile_hpp */
