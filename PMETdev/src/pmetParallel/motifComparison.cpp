//
//  motifComparison.cpp
//  PMET
//
//  Created by Paul Brown on 01/07/2019.
//  Copyright © 2019 Paul Brown. All rights reserved.
//

#include <fstream>
#include <iostream>
#include <exception>
#include <math.h>
#include <stdexcept>
#include <limits>
#include "motifComparison.hpp"

void motifComparison::reset()
{
    genesInUniverseWithBothMotifs.clear();
    genesInClusterWithBothMotifs.clear();
    pval = 1.0;
}

void motifComparison::findIntersectingGenes(motif &motif1, motif &motif2, double ICthreshold, std::unordered_map<std::string, int> &promSizes)
{
    reset();
    // genesInUniverseWithBothMotifs is bm_genes in python code
    // find keys common to both lists

    std::vector<std::string> m1Genes, m2Genes, tmpSharedGenes;

    motif1.getListofGenes(m1Genes);
    motif2.getListofGenes(m2Genes);
    tmpSharedGenes.reserve(m1Genes.size());
    std::set_intersection(m1Genes.begin(), m1Genes.end(), m2Genes.begin(), m2Genes.end(), std::inserter(tmpSharedGenes, tmpSharedGenes.begin()));

    // filter for overlaps
    for (std::vector<std::string>::iterator gene = tmpSharedGenes.begin(); gene != tmpSharedGenes.end(); gene++)
    {
        if (promSizes[*gene])
        {
            // remove some instances of this gene based on overlap
            // do all pairwise comparisons between instances in 2 motifs

            long numM1Locations = motif1.getNumInstances(*gene);
            long numM2Locations = motif2.getNumInstances(*gene);

            std::vector<bool> motif1LocationsToKeep(numM1Locations, true);
            std::vector<bool> motif2LocationsToKeep(numM2Locations, true);

            for (long mLoc1 = 0; mLoc1 < numM1Locations; mLoc1++)
            {
                motifInstance &m1Instance = motif1.getInstance(*gene, mLoc1);

                for (long mLoc2 = 0; mLoc2 < numM2Locations; mLoc2++)
                {
                    motifInstance &m2Instance = motif2.getInstance(*gene, mLoc2);

                    if (motifInstancesOverlap(motif1, motif2, m1Instance, m2Instance, ICthreshold))
                    {
                        // reject due to overlap
                        motif1LocationsToKeep[mLoc1] = false;
                        motif2LocationsToKeep[mLoc2] = false;
                    }
                }
            }

            // done all pairwise comparisons. Do we need to delete esome instances?
            if ((std::find(motif1LocationsToKeep.begin(), motif1LocationsToKeep.end(), true) != motif1LocationsToKeep.end()) && (std::find(motif2LocationsToKeep.begin(), motif2LocationsToKeep.end(), true) != motif2LocationsToKeep.end()))
            {
                // gene still contains both motifs, not all removed

                if ((std::find(motif1LocationsToKeep.begin(), motif1LocationsToKeep.end(), false) == motif1LocationsToKeep.end()) && (std::find(motif2LocationsToKeep.begin(), motif2LocationsToKeep.end(), false) == motif2LocationsToKeep.end()))
                {

                    // in fact keeping all
                    genesInUniverseWithBothMotifs.push_back(*gene);
                }
                else
                {
                    // some locations removed, but some kept, re-calc binomial test. Must be less than threshold for both motifs
                    if (geometricBinomialTest(motif1LocationsToKeep, *gene, promSizes[*gene], motif1) && geometricBinomialTest(motif2LocationsToKeep, *gene, promSizes[*gene], motif2))
                        genesInUniverseWithBothMotifs.push_back(*gene); // best score is at or below threshold
                }
            }
        }
    } // next gene
}

bool motifComparison::motifInstancesOverlap(motif &motif1, motif &motif2, motifInstance &m1Instance, motifInstance &m2Instance, double ICthreshold)
{
    // any that return true will be filtered out
    // this is defineOverlapsBetweenTwoMotifs in python code
    int m1Start = m1Instance.getStartPos();
    int m2Start = m2Instance.getStartPos();
    int m1End = m1Instance.getEndPos();
    int m2End = m2Instance.getEndPos();

    if ((m1Start < m2Start && m1End < m2Start) || (m2End < m1Start && m2End < m1End))
        return false; // no overlap so keep

    if ((m1Start >= m2Start && m1End <= m2End) || (m2Start >= m1Start && m2End <= m1End))
        return true; // one motif entirely with the other so reject

    if (m2Start > m1Start)
    {
        // overlap is in the last part of motif1 and beginning of motif2
        int overlapLen = m1End - m2Start + 1;
        return (std::min(motif1.getReverseICScore(overlapLen), motif2.getForwardICScore(overlapLen)) > ICthreshold);

        // fwdIC is defined as the sum of the IC of the overlap in the
        // beginning of the second motif
        // revIC is defined as the sum of IC in the overlapping end of motif 1
        // if the overlap is too large and we need to ditch both of these hits
    }
    else
    {
        // overlap is in the first part of motif1 and end of motif2
        int overlapLen = m2End - m1Start + 1;
        return (std::min(motif1.getForwardICScore(overlapLen), motif2.getReverseICScore(overlapLen)) > ICthreshold);
    }
}

bool motifComparison::geometricBinomialTest(const std::vector<bool> &motifLocationsToKeep, const std::string &gene, int promoterLength, motif &mt)
{
    // Test for one motif in one promoter
    // motifLocations contain p-values. Use if motifLocationsToKeep is true

    // returtn smallest value for this motif in this promoter
    long numpVals = std::count(motifLocationsToKeep.begin(), motifLocationsToKeep.end(), true);
    std::vector<double> pVals;
    pVals.reserve(numpVals);

    long possibleLocations = 2 * (promoterLength - mt.getLength() + 1);

    for (int i = 0; i < motifLocationsToKeep.size(); i++)
    {
        if (motifLocationsToKeep[i])
        {

            motifInstance mInst = mt.getInstance(gene, i);
            pVals.push_back(mInst.getPValue());
        }
    }

    // motif instances have already been sorted and so pVsls will be in ascending order
    // calculate geomtric mean of all included p-vals

    double lowestScore = std::numeric_limits<double>::max();

    for (std::vector<double>::iterator i = pVals.begin(); i < pVals.end(); i++)
    {
        // calculate geomtric mean of all  p-vals up to this one
        double gm = geometricMean(pVals.begin(), i + 1);

        double binomP = 1 - binomialCDF((i + 1 - pVals.begin()), possibleLocations, gm);

        lowestScore = (binomP < lowestScore) ? binomP : lowestScore;
    }

    return lowestScore <= mt.getThreshold();
}

double motifComparison::geometricMean(std::vector<double>::iterator first, std::vector<double>::iterator last)
{
    double sum = 0.0;
    long len = last - first;

    for (std::vector<double>::iterator i = first; i < last; i++)
        sum += log(*i);

    return exp(sum / len);
}

double motifComparison::binomialCDF(long numPVals, long numLocations, double gm)
{
    // gm is geometric mean
    double cdf = 0.0;
    double b = 0.0;

    double logP = log(gm);
    double logOneMinusP = log(1 - gm);

    for (int k = 0; k < numPVals; k++)
    {
        if (k > 0)
            b += log(numLocations - k + 1) - log(k);

        cdf += exp(b + k * logP + (numLocations - k) * logOneMinusP);
    }
    return cdf;
}

void motifComparison::colocTest(long universeSize, double ICthreshold, const std::string &clusterName, std::vector<std::string> &genesInCluster)
{
    // universeSize - total of all genes
    // ICthreshold - used in discarding 2 motifs on same gene which partially overlap
    // clusterName - cluster name fromn input file
    // geneInCluster = genes in cluster clusterName. Already sorted to make this more efficient

    // first find intersecting genes that are in this cluster

    long numGenesWithBothMotifs = genesInUniverseWithBothMotifs.size();

    clusterSize = genesInCluster.size();

    if (!numGenesWithBothMotifs || !clusterSize || !universeSize)
        return;

    genesInClusterWithBothMotifs.clear();
    genesInClusterWithBothMotifs.reserve(numGenesWithBothMotifs);

    std::set_intersection(genesInUniverseWithBothMotifs.begin(), genesInUniverseWithBothMotifs.end(), genesInCluster.begin(), genesInCluster.end(), std::inserter(genesInClusterWithBothMotifs, genesInClusterWithBothMotifs.begin()));

    if (!genesInClusterWithBothMotifs.size())
        return;

    // pval = exp(log_hypergeometric( universeSize));

    // hypergeometric test
    // The computation of the log-scale p-value of the pairwise hypergeometric test.
    // Mirrored after Matlab function proposed by Meng et al. (2009).

    // compile their logftable thing within the function and use that as needed
    // it would appear that the largest index of it they ever access is U+1

    // nedd to sum  the log of all numbers up to universize +1

    std::vector<double> logf(universeSize + 2, 0.0);
    // could just do this once
    logf[1] = log(1);
    for (int i = 2; i < logf.size(); i++)
        logf[i] = logf[i - 1] + log(i);

    long minSetSize = (clusterSize < numGenesWithBothMotifs) ? clusterSize : numGenesWithBothMotifs;

    long aSize = minSetSize - genesInClusterWithBothMotifs.size() + 1;
    std::vector<double> a(aSize);

    double amax = -std::numeric_limits<double>::max();

    for (int i = 0; i < aSize; i++)
    {
        long hold = genesInClusterWithBothMotifs.size() + i;
        a[i] = (-logf[hold] - logf[clusterSize - hold] - logf[numGenesWithBothMotifs - hold] - logf[universeSize + hold - clusterSize - numGenesWithBothMotifs]);
        amax = (a[i] > amax) ? a[i] : amax;
    }

    double aSum = 0.0;
    for (int i = 0; i < aSize; i++)
        aSum += exp(a[i] - amax);

    pval = exp(logf[clusterSize] + logf[universeSize - clusterSize] + logf[numGenesWithBothMotifs] + logf[universeSize - numGenesWithBothMotifs] - logf[universeSize] + amax + log(aSum));
}
