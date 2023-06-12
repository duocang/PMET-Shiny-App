//
//  motifComparison.hpp
//  PMET
//
//  Created by Paul Brown on 01/07/2019.
//  Copyright © 2019 Paul Brown. All rights reserved.
//

#ifndef motifComparison_hpp
#define motifComparison_hpp

#include <string>
#include <vector>
#include <fstream>
#include "motif.hpp"

class motifComparison
{

    // represents one line in the results file

public:
    double getpValue() const { return pval; };
    long getClusterSize() const { return clusterSize; };
    std::vector<std::string> getSharedGenesInCluster() const { return genesInClusterWithBothMotifs; };
    long getNumSharedGenesInUniverse() const { return genesInUniverseWithBothMotifs.size(); };

    void findIntersectingGenes(motif &m1, motif &m2, double ICthreshold, std::unordered_map<std::string, int> &promSizes);
    void colocTest(long universeSize, double ICthreshold, const std::string &clusterName, std::vector<std::string> &genesInCluster);

private:
    void reset();
    bool motifInstancesOverlap(motif &m1, motif &m2, motifInstance &m1Instance, motifInstance &m2Instance, double IDthreshold);
    bool geometricBinomialTest(const std::vector<bool> &motifLocationsToKeep, const std::string &gene, int promoterLength, motif &mt);
    double geometricMean(std::vector<double>::iterator first, std::vector<double>::iterator last);
    double binomialCDF(long numPVals, long numLocations, double gm);

    double pval;
    long clusterSize;

    std::vector<std::string> genesInClusterWithBothMotifs;
    std::vector<std::string> genesInUniverseWithBothMotifs;
};

#endif /* motifComparison_hpp */
