#ifndef PROMOTER_LENGTH_H
#define PROMOTER_LENGTH_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_PROMOTER_NAME_LENGTH 100 // Maximum allowable length for a promoter name

/**
 * Structure representing a single promoter.
 */
typedef struct Promoter
{
    char *promoterName;    ///< Name of the promoter.
    int length;            ///< Length of the promoter sequence.
    struct Promoter *next; ///< Pointer to the next promoter in the list.
} Promoter;

/**
 * Structure representing a list of promoters.
 */
typedef struct
{
    Promoter *head; ///< Pointer to the head (first element) of the promoter list.
} PromoterList;

// Function prototypes

/**
 * Initialize a promoter list to an empty state.
 *
 * @param list Pointer to the PromoterList to be initialized.
 */
void initPromoterList(PromoterList *list);

/**
 * Searches for a promoter by its name in the provided list and returns its length.
 *
 * @param list Pointer to the PromoterList to be searched.
 * @param promoterName Name of the promoter to be searched for.
 * @return Length of the promoter if found, otherwise -1.
 */
size_t findPromoterLength(PromoterList *list, const char *promoterName);

/**
 * Release all memory associated with a given promoter list, including each individual promoter.
 *
 * @param list Pointer to the PromoterList to be freed.
 */
void deletePromoterLenListContent(PromoterList *list);

/**
 * Release all memory associated with a given promoter list, including each individual promoter and itelsf.
 *
 * @param list Pointer to the PromoterList to be freed.
 */
void deletePromoterLenList(PromoterList *list);

/**
 * Inserts a new Promoter with the given name and length at the beginning of the PromoterList.
 * The function will exit with an error message if there's any memory allocation failure.
 *
 * @param list Pointer to the PromoterList where the new promoter should be inserted.
 * @param promoterName Name of the new promoter.
 * @param length Length of the new promoter.
 */
void insertPromoter(PromoterList *list, const char *promoterName, int length);

/**
 * Reads promoter data from a file and populates a provided promoter list.
 *
 * @param list Pointer to the PromoterList to be populated.
 * @param filename Name/path of the file containing promoter data.
 */
void readPromoterLengthFile(PromoterList *list, const char *filename);

#endif /* PROMOTER_LENGTH_H */
