#include <filesystem> // If using C++17 or later
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

void ensureEndsWith(std::string& str, char character);
bool loadFiles(const std::string& path, const std::string& genesFile, const std::string& promotersFile,
               const std::string& binThreshFile, const std::string& ICFile, const std::string& fimoDir,
               std::unordered_map<std::string, int>& promSizes, std::unordered_map<std::string, double>& topNthreshold,
               std::unordered_map<std::string, std::vector<double>>& ICvalues,
               std::map<std::string, std::vector<std::string>>& clusters, std::vector<std::string>& fimoFiles,
               std::map<std::string, std::vector<Output>>& results);
bool validateInputs(const std::unordered_map<std::string, int>& promSizes,
                    const std::unordered_map<std::string, double>& topNthreshold,
                    const std::unordered_map<std::string, std::vector<double>>& ICvalues,
                    const std::map<std::string, std::vector<std::string>>& clusters,
                    const std::vector<std::string> fimoFiles);
long fastFileRead(std::string filename, std::stringstream &results);

void bhCorrection(std::vector<Output>& motifs);
// void writeProgressFile(double val, std::string msg, std::string path);
void writeProgress(const std::string& fname, const std::string& message, float inc);
int SumVector(std::vector<int> &vec);

/**
 * @brief Reads and loads data from input files.
 *
 * This function reads and parses several input files to populate the relevant data structures.
 *
 * @param path The input directory path where the files are located.
 * @param genesFile The name of the file containing gene cluster information.
 * @param promotersFile The name of the file containing gene IDs and their corresponding promoter lengths.
 * @param binThreshFile The name of the file containing motif IDs and their corresponding binomial thresholds.
 * @param ICFile The name of the file containing motif IDs and their corresponding Information Content (IC) values.
 * @param fimoDir The directory where the FIMO files are located.
 * @param promSizes A map to store gene IDs and their corresponding promoter lengths.
 * @param topNthreshold A map to store motif IDs and their corresponding binomial thresholds.
 * @param ICvalues A map to store motif IDs and their corresponding Information Content (IC) values.
 * @param clusters A map to store cluster IDs and their corresponding gene IDs.
 * @param fimoFiles A vector to store the names of FIMO files in the directory.
 * @param results A vector of maps to store motif comparison results for each cluster.
 *
 * @return True if all input files are successfully loaded, false otherwise.
 */
bool loadFiles(const std::string &path,
               const std::string &genesFile,
               const std::string &promotersFile,
               const std::string &binThreshFile,
               const std::string &ICFile,
               const std::string &fimoDir,
               std::unordered_map<std::string, int> &promSizes,
               std::unordered_map<std::string, double> &topNthreshold,
               std::unordered_map<std::string, std::vector<double>> &ICvalues,
               std::map<std::string, std::vector<std::string>> &clusters,
               std::vector<std::string> &fimoFiles,
               std::vector<std::map<std::string, std::vector<Output>>> &results)
{
    std::cout << "Reading input files..." << std::endl;

    // Read and parse the "promoter_lengths.txt" file
    // Store gene IDs and their corresponding promoter lengths in 'promSizes'
    // Format: "Name  length"
    // Example: "geneID1  1000"
    //          "geneID2  800"
    std::ifstream promFile(path + promotersFile);
    std::string geneID, len;

    while (promFile >> geneID >> len)
    {
        promSizes.emplace(geneID, stoi(len)); // key is geneID, value is promoter length
    }

    std::cout << "Universe size is " << promSizes.size() << std::endl;

    // Read and parse the "binomial_thresholds.txt" file
    // Store motif IDs and their corresponding binomial thresholds in 'topNthreshold'
    // Format: "motifID  threshold"
    // Example: "motif1  0.05"
    //          "motif2  0.01"
    std::ifstream binFile(path + binThreshFile);
    std::string motifID, threshold;

    while (binFile >> motifID >> threshold)
    {
        topNthreshold.emplace(motifID, stof(threshold));
    }

    // Read and parse the "IC.txt" file
    // Store motif IDs and their corresponding Information Content (IC) values in 'ICvalues'
    // Example: "motif1  0.1  0.2  0.3"
    //          "motif2  0.5  0.6  0.4"
    std::ifstream ifs(path + ICFile);
    if (!ifs)
    {
        std::cout << "Error: Cannot open file " << path + ICFile << std::endl;
        return false;
    }

    std::string line;
    while (std::getline(ifs, line))
    {
        std::istringstream ics(line);
        double score;
        ics >> motifID;

        ICvalues.emplace(motifID, std::vector<double>());

        while (ics >> score)
        {
            ICvalues[motifID].push_back(score);
        }
    }

    // Read and parse the 'genesFile' file to create gene clusters
    // Store cluster IDs and their corresponding gene IDs in 'clusters'
    // Format: "clusterID  geneID"
    // Example: "cluster1  gene1"
    //          "cluster1  gene2"
    std::ifstream geneFile(genesFile);
    std::string clusterID;

    long genesFound = 0;
    while (geneFile >> clusterID >> geneID)
    {
        // vector of genes for each cluster
        clusters[clusterID].push_back(geneID);
        genesFound++;
    }
    geneFile.close();
    std::cout << "Found " << genesFound << " gene IDs in " << clusters.size() << " clusters" << std::endl;

    // Need to sort the clusters to find intersections efficiently
    for (auto &cl : clusters)
    {
        std::sort(cl.second.begin(), cl.second.end());
    }

    // Get the names of all files in the 'fimoDir' directory and store them in 'fimoFiles'
    // Example: fimoFiles = {"file1.txt", "file2.txt", ...}
    for (const auto &entry : std::filesystem::directory_iterator(fimoDir))
    {
        if (!entry.is_directory())
        {
            fimoFiles.push_back(entry.path().filename().string());
        }
    }

    // Sort the fimoFiles, excluding .txt part
    std::sort(fimoFiles.begin(), fimoFiles.end(), [](const std::string &a, const std::string &b)
              { return (a.compare(0, a.size() - 4, b, 0, b.size() - 4) < 0); });

    return true;
}

/**
 * @brief Validates the input data for motif comparison.
 *
 * This function checks whether the required input data is present and valid.
 * It ensures that gene clusters, FIMO files, binomial thresholds, Information Content (IC) values,
 * and promoter sizes are available.
 *
 * @param promSizes A map containing gene IDs and their corresponding promoter lengths.
 * @param topNthreshold A map containing motif IDs and their corresponding binomial thresholds.
 * @param ICvalues A map containing motif IDs and their corresponding Information Content (IC) values.
 * @param clusters A map containing cluster IDs and their corresponding gene IDs.
 * @param fimoFiles A vector containing the names of FIMO files.
 *
 * @return True if all required input data is present and valid, false otherwise.
 */
bool validateInputs(const std::unordered_map<std::string, int> &promSizes,
                    const std::unordered_map<std::string, double> &topNthreshold,
                    const std::unordered_map<std::string, std::vector<double>> &ICvalues,
                    const std::map<std::string, std::vector<std::string>> &clusters,
                    const std::vector<std::string> fimoFiles)
{
    std::cout << "Validating inputs...";

    // Check if gene clusters exist
    if (clusters.empty())
    {
        std::cout << "Error: No gene clusters found!" << std::endl;
        return false;
    }

    // Check if FIMO files exist
    if (fimoFiles.empty())
    {
        std::cout << "Error: FIMO files not found!" << std::endl;
        return false;
    }

    // Check if binomial thresholds exist
    if (topNthreshold.empty())
    {
        std::cout << "Error: Binomial threshold values not found!" << std::endl;
        return false;
    }

    // Check if Information Content (IC) values exist
    if (ICvalues.empty())
    {
        std::cout << "Error: Information Content values not found!" << std::endl;
        return false;
    }

    // Check if promoter sizes exist and match with the gene IDs in clusters
    for (auto cl = std::begin(clusters); cl != std::end(clusters); cl++)
    {
        for (auto gene = std::begin(cl->second); gene != std::end(cl->second); gene++)
        {
            // Check if the gene ID exists in the promoter sizes map
            if (promSizes.find(*gene) == promSizes.end())
            {
                std::cout << "Error: Gene ID " << *gene << " not found in the promoter lengths file!" << std::endl;
                return false;
            }
        }
    }

    // All checks passed, the input data is valid
    std::cout << "OK" << std::endl;
    return true;
}

/**
 * @brief Reads a text file into a stringstream efficiently and returns the number of lines read.
 *
 * This function reads an entire text file into a stringstream 'results' and returns the number of lines read.
 * It is an optimized way to read a file into memory and count the lines simultaneously.
 *
 * @param filename The name of the file to be read.
 * @param results The stringstream to store the file content.
 * @return The number of lines read from the file.
 */
long fastFileRead(std::string filename, std::stringstream &results)
{
    long flength;
    long numLines = 0;
    bool success = false;

    // Open the file in binary mode for efficient reading
    std::ifstream ifs(filename, std::ifstream::binary);

    if (!ifs)
    {
        std::cout << "Error: Cannot open file " << filename << std::endl;
        exit(1);
    }

    // Get the file size
    ifs.seekg(0, ifs.end);
    flength = ifs.tellg();
    ifs.seekg(0, ifs.beg);

    // Create a buffer to store the file content
    std::string buffer(flength, '\0');

    // Read the file into the buffer
    if (!ifs.read(&buffer[0], flength))
        std::cout << "Error reading file " << filename << std::endl;
    else
    {
        // Store the buffer content into the stringstream
        results.str(buffer);
        success = true;
    }

    // Close the file
    ifs.close();

    if (success)
    {
        // Count the number of lines read
        numLines = std::count(std::istreambuf_iterator<char>(results), std::istreambuf_iterator<char>(), '\n');
        // In case there is no '\n' on the last line, increase the line count by 1
        results.unget();
        if (results.get() != '\n')
            numLines++;
        // Reset the stringstream iterator
        results.seekg(0);
    }
    else
        exit(1);

    return numLines;
}



void exportResultParallel(std::string cluster, std::vector<Output>::iterator beginIt, std::vector<Output>::iterator endIt, std::string outFile, long globalBonferroniFactor)
{
    // open results file, pmet results
    std::ofstream outputFile;
    outputFile.open(outFile, std::ios_base::out);
    if (!outputFile.is_open())
    {
        std::cout << "Error openning results file " << outFile << std::endl;
        exit(1);
    }

    // print sorted, correcgted compoarisons inb this cluster
    for (std::vector<Output>::iterator mc = beginIt; mc != endIt; mc++)
    {
        outputFile << cluster << '\t'; // cluster name
        mc->printMe(globalBonferroniFactor, outputFile);
    }

    outputFile.close();
}

void writeProgress(const std::string &fname, const std::string &message, float inc)
{
    std::ifstream infile;

    float progress = 0.0;
    std::string oldMessage;

    infile.open(fname, std::ifstream::in);
    if (infile.is_open())
    {
        infile >> progress >> oldMessage;
        infile.close();
    }
    progress += inc;
    std::ofstream outfile;

    outfile.open(fname, std::ofstream::out);

    if (outfile.is_open())
    {
        outfile << progress << "\t" << message << std::endl;
        outfile.close();
    }
}



void bhCorrection(std::vector<Output> &motifs)
{
    // get list of all pvals fo rthis cluster, retaining original index position

    std::vector<std::pair<long, double>> pValues;
    long n = motifs.size();

    pValues.reserve(n);

    for (long i = 0; i < n; i++)
        pValues.push_back(std::make_pair(i, motifs[i].getpValue()));

    // sort descendingie largest p val first
    std::sort(pValues.begin(),
              pValues.end(),
              [](const std::pair<long, double> &a, const std::pair<long, double> &b)
              { return a.second > b.second; });

    // now multiply each p value by a factor based on its position in the sorted list
    for (long i = 0; i < n; i++)
    {
        pValues[i].second *= (n / (n - i));
        if (i && pValues[i].second > pValues[i - 1].second)
            pValues[i].second = pValues[i - 1].second;

        motifs[pValues[i].first].setBHCorrection(pValues[i].second); // assign corrected value to its original index position before sort
    }
}

std::vector<std::vector<int>> fairDivision(std::vector<int> input, int numGroups)
{
    std::vector<std::vector<int>> resultVector;
    if (numGroups >= input.size())
    {
        resultVector.resize(input.size());
        for (int i = 0; i < input.size(); i++)
        {
            resultVector[i] = {input[i]};
        }
    }

    resultVector.resize(numGroups);

    std::sort(input.begin(), input.end(), std::greater<int>());

    // 从最大的开始填充到结果中
    for (int i = 0; i < numGroups; i++)
        resultVector[i] = {input[i]};

    // 从大到小遍历剩下的数字
    for (int i = numGroups; i < input.size(); i++)
    {
        std::vector<int> tempSum(numGroups); // a temp vector to keep sum of each group

        for (int j = 0; j < resultVector.size(); j++)
            tempSum[j] = SumVector(resultVector[j]) + input[i];

        int minIndex = min_element(tempSum.begin(), tempSum.end()) - tempSum.begin(); // 找出当前和最小的分组
        resultVector[minIndex].push_back(input[i]);                                   // add the max of the rest numbers to the group with min sum
    }
    return resultVector;
}

int SumVector(std::vector<int> &vec)
{
    int res = 0;
    for (size_t i = 0; i < vec.size(); i++)
        res += vec[i];
    return res;
}

int output(std::vector<motif>::iterator blockstart, std::vector<motif>::iterator blockEnd, std::vector<motif>::iterator last, std::map<std::string, std::vector<std::string>> clusters, motifComparison mComp,
           std::map<std::string, std::vector<Output>> *results, double ICthreshold, std::unordered_map<std::string, int> promSizes, long numComplete, long totalComparisons, std::string outputDirName)
{
    for (std::vector<motif>::iterator motif1 = blockstart; motif1 != blockEnd; ++motif1)
    {
        for (std::vector<motif>::iterator motif2 = motif1 + 1; motif2 != last; ++motif2)
        {
            mComp.findIntersectingGenes(*motif1, *motif2, ICthreshold, promSizes); // sets genesInUniverseWithBothMotifs, used in Coloc Test
            // got shared genes so do test for each cluster
            for (auto &cl : clusters)
            {
                // std::cout << "                          Gene cluster: " << cl.first << std::endl;
                // std::cout << "                                 mComp: " << mComp.getpValue() << std::endl;
                mComp.colocTest(promSizes.size(), ICthreshold, cl.first, cl.second);
                (*results)[cl.first].push_back(Output(motif1->getMotifName(), motif2->getMotifName(), mComp));
            }

            std::cout << "\b\b\b";
            // progress goes from 10 to 90% in this loop
            double progVal = 0.1 + double(0.8 * ++numComplete) / totalComparisons;
            std::cout << std::setw(2) << long(progVal * 100) << "%" << std::endl;
        }
        std::cout << " Perfomed " << numComplete << " of " << totalComparisons << " pair-wise comparisons" << std::endl;
    }
    return 1;
}

/*
    motif pair comparsion, one of motif (from a vector) compares with following motifs

    @motifsIndxVector: a vector of motifs' index
    @*allMotifs: a vector of motifs' name
    @clusters: clusters of genes
    @motifComparison: result of motif's comparsion
    @*results: as it named
    @ICthreshold
    @promSizes
    @numComplete
    @outputDirName
*/
int outputParallel(std::vector<int> motifsIndxVector,
                   std::vector<motif> *allMotifs,
                   std::map<std::string, std::vector<std::string>> clusters,
                   motifComparison mComp,
                   std::map<std::string, std::vector<Output>> *results,
                   double ICthreshold,
                   std::unordered_map<std::string, int> promSizes,
                   long numComplete,
                   long totalComparisons,
                   std::string outputDirName)
{

    for (int i : motifsIndxVector)
    {
        motif motif1 = (*allMotifs)[i];
        for (int j = i + 1; j < (*allMotifs).size(); j++)
        {
            motif motif2 = (*allMotifs)[j];

            mComp.findIntersectingGenes(motif1, motif2, ICthreshold, promSizes); // sets genesInUniverseWithBothMotifs, used in Coloc Test
            // got shared genes so do test for each cluster
            for (auto &cl : clusters)
            {
                mComp.colocTest(promSizes.size(), ICthreshold, cl.first, cl.second);
                (*results)[cl.first].push_back(Output(motif1.getMotifName(), motif2.getMotifName(), mComp));
                // std::cout   << cl.first << " " << motif1.getMotifName() << " " << motif2.getMotifName()
                //             << " " << mComp.getSharedGenesInCluster().size() << " "  << mComp.getpValue() << std::endl;
            }
        }
    }
    return 1;
}