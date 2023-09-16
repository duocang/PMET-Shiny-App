#ifndef SCORE_LABEL_PAIR_VECTOR_H
#define SCORE_LABEL_PAIR_VECTOR_H

/**
 * @file score_label_pair.h
 * Provides data structures and operations for maintaining a dynamic vector of
 * score-label pairs, with functions for sorting, searching, and file I/O.
 */

#include "pmet-index-MemCheck.h"

#include <stdlib.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>

#define FOUND 1
#define NOT_FOUND 0
#define LABEL_NOT_FOUND -1.0

/**
 * Represents a pair of a double score and a corresponding string label.
 */
typedef struct
{
  double score; /**< The numerical score. */
  char *label;  /**< The corresponding label. */
} ScoreLabelPair;

/**
 * Dynamic array to store ScoreLabelPair elements.
 */
typedef struct
{
  ScoreLabelPair *items; /**< Pointer to the array of items. */
  size_t size;           /**< Number of items currently in the vector. */
  size_t capacity;       /**< Total capacity of the vector. */
} ScoreLabelPairVector;

/**
 * Create a new ScoreLabelPairVector.
 *
 * @return Pointer to the newly created ScoreLabelPairVector.
 */
ScoreLabelPairVector *createScoreLabelPairVector();

/**
 * Add a new score-label pair to the vector.
 *
 * @param vec The vector to add the pair to.
 * @param score The score to add.
 * @param label The label to add.
 * @return true if the pair was successfully added, false otherwise.
 */
bool pushBack(ScoreLabelPairVector *vec, double score, char *label);

/**
 * Retains the top N score-label pairs in the vector, based on the score.
 *
 * @param vec The vector to process.
 * @param N The number of top pairs to retain.
 */
void retainTopN(ScoreLabelPairVector *vec, size_t N);

/**
 * Compare two ScoreLabelPairs for sorting.
 *
 * @param a First pair for comparison.
 * @param b Second pair for comparison.
 * @return
 *   * a negative value if a's score < b's score
 *   * 0 if a's score == b's score
 *   * a positive value if a's score > b's score
 */
int comparePairs(const void *a, const void *b);

/**
 * Check if a given label exists in the vector.
 *
 * @param vec The vector to search.
 * @param searchLabel The label to search for.
 * @return The index of the label if it exists, or -1 if it doesn't.
 */
int labelExists(const ScoreLabelPairVector *vec, const char *searchLabel);

/**
 * Find the score associated with a given label in the vector.
 *
 * @param vec The vector to search.
 * @param searchLabel The label to search for.
 * @return The score associated with the label, or -1.0 if the label doesn't exist.
 */
double findScoreByLabel(ScoreLabelPairVector *vec, const char *searchLabel);

/**
 * Sort the score-label pairs in the vector based on their scores.
 *
 * @param vec The vector to sort.
 */
void sortVector(ScoreLabelPairVector *vec);

/**
 * Print the contents of the vector to the console.
 *
 * @param vec The vector to print.
 */
void printVector(ScoreLabelPairVector *vec);

/**
 * Free the memory occupied by the ScoreLabelPairVector.
 *
 * @param vec The vector to free.
 */
void deleteScoreLabelVectorContents(ScoreLabelPairVector *vec);

void deleteScoreLabelVector(ScoreLabelPairVector *vec);

/**
 * Write the contents of the ScoreLabelPairVector to a text file.
 *
 * @param vector The vector to write.
 * @param filename The name of the file to write to.
 */
void writeScoreLabelPairVectorToTxt(ScoreLabelPairVector *vector, const char *filename);

#endif /* SCORE_LABEL_PAIR_VECTOR_H */
