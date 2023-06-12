//  Created by Paul Brown on 25/09/2019.
//  Copyright © 2019 Paul Brown. All rights reserved.
//

#include "Output.hpp"

void Output::printMe(long globalBonferroniFactor, std::ofstream& outFile) {
  /*Print in this order
  1 motif1name
  2 motif2name
  3 number of intersecting genes in the cluster
  4 Total number of intersecting genes
  5 Number of genes in cluster
  7 uncorrected pval
  8 BH corrected pval
  9 Bonferroni corrected for cluster size pval
  10 Global Bonferroni corrected pval
  11 list of genes in 3
   */

  double pvalBonferroniCorrected = std::min((pval * clusterSize), 1.0);

  // this factor is total number of all comparisons
  double pvalGlobalBonferroniCorrected = std::min((pval * globalBonferroniFactor), 1.0);

  outFile << motif1Name << '\t' << motif2Name << '\t' << genesInClusterWithBothMotifs.size() << '\t'
          << numSharedGenesInUniverse << '\t' << clusterSize << '\t' << pval << '\t' << pvalBHCorrected << '\t'
          << pvalBonferroniCorrected << '\t' << pvalGlobalBonferroniCorrected << '\t';

  for (auto gene = std::begin(genesInClusterWithBothMotifs); gene != std::end(genesInClusterWithBothMotifs); gene++)
    outFile << *gene << ';';

  outFile << std::endl;
}

void Output::writeHeaders(std::ofstream& of) {
  of << "Cluster\t"
     << "Motif 1\t"
     << "Motif 2\t"
     << "Number of genes in cluster with both motifs\t"
     << "Total number of genes with both motifs\t"
     << "Number of genes in cluster\t"
     << "Raw p-value\t"
     << "Adjusted p-value (BH)\t"
     << "Adjusted p-value (Bonf)\t"
     << "Adjusted p-value (Global Bonf)\t"
        "Genes"
     << std::endl;
}

bool sortComparisons(const Output& a, const Output& b) {
  // sort ascending on motif1, then motif2

  if (a.motif1Name == b.motif1Name)
    return (a.motif2Name < b.motif2Name);
  else
    return (a.motif1Name < b.motif1Name);
}
