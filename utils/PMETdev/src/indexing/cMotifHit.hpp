//  Created by Paul Brown on 08/09/2020.
//  Copyright © 2020 Paul Brown. All rights reserved.
//

#ifndef cMotifHit_hpp
#define cMotifHit_hpp

#include <string>

class cMotifHit {
  // represents a line from a fimo file
  // fimo files are tab-seperared and have the following col headings on line 0

  // pattern name (motif name) (string)
  // sequence name (gene ID) (string)
  // start (int)
  // stop (int)
  // strand (char '+' or '-'_
  // score (double)
  // p-val (double)
  // q-val (double)
  // matched seq (string)
  friend std::ostream& operator<<(std::ostream& ostr, const cMotifHit& hit);

  friend bool sortHits(const cMotifHit& a, const cMotifHit& b);

public:
  cMotifHit(){};
  cMotifHit(long sp, long ep, char str, double sc, double p, std::string seq)
      : startPos(sp), endPos(ep), strand(str), score(sc), pVal(p), sequence(seq), binScore(-1){};
  cMotifHit(long sp, long ep, char str, double sc, double p, std::string seq, double bs)
      : startPos(sp), endPos(ep), strand(str), score(sc), pVal(p), sequence(seq), binScore(bs){};
  long getStartPos() const { return startPos; };
  long getEndPos() const { return endPos; };
  double getPVal() const { return pVal; };

private:
  long startPos;
  long endPos;
  char strand;
  double score;
  double pVal;
  std::string sequence;
  double binScore;
};

bool sortHits(const cMotifHit& a, const cMotifHit& b);

#endif /* cMotifHit_hpp */
