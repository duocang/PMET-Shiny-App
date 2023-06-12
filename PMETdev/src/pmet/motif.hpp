//  Created by Paul Brown on 02/08/2019.
//  Copyright © 2019 Paul Brown. All rights reserved.
//

#ifndef motif_hpp
#define motif_hpp

#include <algorithm>
#include <map>
#include <string>
#include <unordered_map>
#include <vector>

class motifInstance {
  // reperesents  a line in fimo file

public:
  motifInstance(int start, int end, std::string str, double p1, double p2, std::string seq)
      : startPos(start), endPos(end), strand(str), pVal(p1), adjPVal(p2), sequence(seq){};
  int getStartPos() const { return startPos; };
  int getEndPos() const { return endPos; };
  double getPValue() const { return adjPVal; };  // use dfor geometric mean

private:
  int startPos;
  int endPos;
  std::string strand;
  double pVal;
  double adjPVal;
  std::string sequence;
};

bool sortHits(const motifInstance& a, const motifInstance& b);

class motif {
  // represents the content of 1 fimo file

public:
  bool readFimoFile(const std::string filename, const std::string path,
                    std::unordered_map<std::string, std::vector<double> >& ICvalues,
                    std::unordered_map<std::string, double>& topNthreshold, bool* missingValues);
  void setMotifName(const std::string& motif);
  std::string getMotifName() const;
  void setThreshold(double thresh);
  double getThreshold() const;
  void getListofGenes(std::vector<std::string>& genes);
  double getForwardICScore(int overlapLength) const;
  double getReverseICScore(int overlapLength) const;
  int getLength() const;

  long getNumInstances(std::string geneID);

  motifInstance& getInstance(std::string gene, long idx);

private:
  std::string motifName;
  int motifLength;
  std::vector<double> IC;
  double binomialThreshold;

  // key is gene ID, value is list of positions found in that gene (a line in a fimo/motif file)
  std::unordered_map<std::string, std::vector<motifInstance> > instances;
};

#endif /* motif_hpp */
