#ifndef MOTIF_HIT_H
#define MOTIF_HIT_H

#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h> // for free function
#include <assert.h> // for assert function

#include "pmet-index-MemCheck.h"

// /// Maximum size for the sequence string. Adjust as needed.
// #define MAX_SEQUENCE_SIZE 100

/// Structure representing a hit in the FIMO file.
typedef struct
{
  char *motif_id;      // Motif identifier.
  char *motif_alt_id;  // Alternate motif identifier.
  char *sequence_name; // Name of the sequence.
  long startPos;       // Starting position of the motif hit.
  long stopPos;        // Ending position of the motif hit.
  char strand;         // Strand, either '+' or '-'.
  double score;        // Score of the motif hit.
  double pVal;         // P-value of the motif hit.
  char *sequence;      // Matched sequence string.
  double binScore;     // Bin score of the motif hit.
} MotifHit;

/**
 * Initialize a MotifHit structure.
 *
 * @param hit Pointer to the MotifHit to initialize.
 * @param motif_id Motif identifier.
 * @param motif_alt_id Alternate motif identifier.
 * @param sequence_name Name of the sequence.
 * @param startPos Starting position of the motif hit.
 * @param stopPos Ending position of the motif hit.
 * @param strand Strand, either '+' or '-'.
 * @param score Score of the motif hit.
 * @param pVal P-value of the motif hit.
 * @param sequence Matched sequence string.
 * @param binScore Bin score of the motif hit.
 */
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
                  double binScore);

/**
 * Compare two MotifHit instances for sorting.
 *
 * @param a First MotifHit for comparison.
 * @param b Second MotifHit for comparison.
 * @return
 *   * a negative value if a's score < b's score
 *   * 0 if a's score == b's score
 *   * a positive value if a's score > b's score
 */
int sortHits(const MotifHit *a, const MotifHit *b);

/**
 * Print details of a MotifHit to an output stream.
 *
 * @param hit MotifHit to be printed.
 */
void printMotifHit(const MotifHit *hit);

/**
 * Free allocated memory for a MotifHit.
 *
 * @param hit MotifHit to free.
 * @details Should be called once a MotifHit is no longer needed.
 */
void deleteMotifHitContents(MotifHit *hit);

void deleteMotifHit(MotifHit *hit);

#endif /* MOTIF_HIT_H */
