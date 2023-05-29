//  Created by Paul Brown on 08/09/2020.
//  Copyright © 2020 Paul Brown. All rights reserved.
//

#include "cMotifHit.hpp"

#include <iostream>

bool sortHits(const cMotifHit& a, const cMotifHit& b) {
  // sort ascending on p-val
  return (a.pVal < b.pVal);
}

std::ostream& operator<<(std::ostream& ostr, const cMotifHit& hit) {
  // fimo files have format
  // motif gene    start   stop    strand  score   pVal  qVal  sequence

  // in the PMET analysis program, score is pVal, and p-val is adjusted p-val, qVal is empty

  ostr << hit.startPos << "\t" << hit.endPos << "\t" << hit.strand << "\t" << hit.score << "\t" << hit.pVal << "\t"
       << hit.sequence;

  if (hit.binScore >= 0)
    ostr << "\t" << hit.binScore;

  return ostr;
}
