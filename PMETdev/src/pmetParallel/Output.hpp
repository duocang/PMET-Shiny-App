//
//  Output.hpp
//  PMET
//
//  Created by Paul Brown on 25/09/2019.
//  Copyright © 2019 Paul Brown. All rights reserved.
//

#ifndef Output_hpp
#define Output_hpp

#include "motifComparison.hpp"

class Output {
  friend bool sortComparisons(const Output &a, const Output &b);

public:
  Output(){};
  Output(const std::string &m1name, const std::string &m2name, const motifComparison &mComp) {
    motif1Name = m1name;
    motif2Name = m2name;

    pval = mComp.getpValue();
    clusterSize = mComp.getClusterSize();

    genesInClusterWithBothMotifs = mComp.getSharedGenesInCluster();
    numSharedGenesInUniverse = mComp.getNumSharedGenesInUniverse();
  }

  static void writeHeaders(std::ofstream &of);
  void printMe(long globalBonferroniFactor, std::ofstream &outFile);
  double getpValue() const { return pval; };
  void setBHCorrection(double p) { pvalBHCorrected = p; };

private:
  std::string motif1Name;
  std::string motif2Name;
  double pval;
  double pvalBHCorrected;
  long clusterSize;

  std::vector<std::string> genesInClusterWithBothMotifs;
  long numSharedGenesInUniverse;
};

bool sortComparisons(const Output &a, const Output &b);

#endif /* Output_hpp */
