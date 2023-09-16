#include "pmet-index-MotifHit.h"

// Initialize the MotifHit structure
void initMotifHit(MotifHit *hit,
                  const char *motif_id,
                  const char *motif_alt_id,
                  const char *sequence_name,
                  long startPos,
                  long stopPos,
                  char strand,
                  double score,
                  double pVal,
                  const char *sequence,
                  double binScore)
{
  hit->motif_id      = new_strdup(motif_id);         // Create a duplicate of the provided string.
  hit->motif_alt_id  = new_strdup(motif_alt_id); // Again, create a duplicate.
  hit->sequence_name = new_strdup(sequence_name);

  hit->startPos = startPos;
  hit->stopPos  = stopPos;
  hit->strand   = strand;
  hit->score    = score;
  hit->pVal     = pVal;

  hit->sequence = new_strdup(sequence);

  hit->binScore = binScore;
}

// Free the memory used by a MotifHit.
void deleteMotifHitContents(MotifHit *hit)
{
  new_free(hit->motif_id);
  new_free(hit->motif_alt_id);
  new_free(hit->sequence_name);
  new_free(hit->sequence);
  // reset the pointers to NULL after freeing
  hit->motif_id      = NULL;
  hit->motif_alt_id  = NULL;
  hit->sequence_name = NULL;
  hit->sequence      = NULL;
}

void deleteMotifHit(MotifHit *hit)
{
  deleteMotifHitContents(hit);

  new_free(hit);
}

// Compare two MotifHit structures based on their pVal.
// Return true if a's pVal is less than b's pVal, otherwise false.
int sortHits(const MotifHit *a, const MotifHit *b)
{
  // Sort in ascending order based on pVal.
  return (a->pVal < b->pVal);
}

// Print the details of a MotifHit to an output stream.
void printMotifHit(const MotifHit *hit)
{
  // The FIMO file format is:
  // motif gene    start   stop    strand  score   pVal  qVal  sequence
  // In the PMET analysis program, score is pVal, and p-val is adjusted p-val, qVal is empty.

  printf("%s\t%s\t%s\t%ld\t%ld\t%c\t%lf\t%lf\t%s",
          hit->motif_id,
          hit->motif_alt_id,
          hit->sequence_name,
          hit->startPos,
          hit->stopPos,
          hit->strand,
          hit->score,
          hit->pVal,
          hit->sequence);

  // If binScore is valid (i.e., non-negative), print it as well.
  if (hit->binScore >= 0)
  {
    printf("\t%lf", hit->binScore);
  }

  printf("\n"); // Append a newline for readability.
}
