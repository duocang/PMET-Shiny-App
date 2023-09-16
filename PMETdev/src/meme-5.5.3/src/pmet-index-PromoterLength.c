#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include "pmet-index-PromoterLength.h"

void initPromoterList(PromoterList *list)
{
  if (list == NULL)
  {
    fprintf(stderr, "Error: The provided PromoterList pointer is NULL. Cannot initialize.\n");
    exit(EXIT_FAILURE);
  }

  list->head = NULL;
}

size_t findPromoterLength(PromoterList *list, const char *promoterName)
{
  if (!list)
  {
    fprintf(stderr, "Error: The provided PromoterList pointer is NULL. Cannot perform the search.\n");
    return -1;
  }

  if (!promoterName)
  {
    fprintf(stderr, "Error: The provided promoter name is NULL. Cannot perform the search.\n");
    return -1;
  }

  Promoter *current = list->head;
  while (current)
  {
    if (strcmp(current->promoterName, promoterName) == 0)
    {
      return current->length;
    }
    current = current->next;
  }
  return -1; // Not found
}

void deletePromoterLenListContents(PromoterList *list)
{
  if (!list)
  {
    fprintf(stderr, "Warning: Attempted to free a NULL PromoterList. Operation skipped.\n");
    return;
  }
  // Start timing
  clock_t start_time = clock();
  Promoter *current = list->head;
  while (current)
  {
    Promoter *toDelete = current;
    if (toDelete->promoterName)
    {
      new_free(toDelete->promoterName);
    }
    current = current->next;
    new_free(toDelete);
  }
  list->head = NULL;

  // Stop timing
  clock_t end_time = clock();

#ifdef DEBUG
  // Calculate and print the elapsed time.
  double time_taken = ((double)end_time - start_time) / CLOCKS_PER_SEC; // in seconds
  printf("deletePromoterLenListContents took %f seconds to execute.\n", time_taken);
#endif
}

void deletePromoterLenList(PromoterList *list)
{
  if (!list)
  {
    fprintf(stderr, "Warning: Attempted to free a NULL PromoterList. Operation skipped.\n");
    return;
  }

  deletePromoterLenListContents(list);

  new_free(list);
}

void insertPromoter(PromoterList *list, const char *promoterName, int length)
{
  if (!list)
  {
    fprintf(stderr, "Error: The provided PromoterList pointer is NULL. Cannot insert.\n");
    exit(EXIT_FAILURE);
  }

  if (!promoterName)
  {
    fprintf(stderr, "Error: The provided promoter name is NULL. Cannot insert.\n");
    exit(EXIT_FAILURE);
  }

  Promoter *newPromoter = (Promoter *)new_malloc(sizeof(Promoter));
  if (!newPromoter)
  {
    perror("Failed to allocate memory for new promoter");
    exit(EXIT_FAILURE);
  }

  newPromoter->promoterName = new_strdup(promoterName);
  if (!newPromoter->promoterName)
  {
    perror("Failed to allocate memory for promoter name");
    new_free(newPromoter);
    exit(EXIT_FAILURE);
  }

  newPromoter->length = length;
  newPromoter->next = list->head;
  list->head = newPromoter;
}

size_t readPromoterLengthFile(PromoterList *list, const char *filename)
{
  if (list == NULL)
  {
    fprintf(stderr, "Error: The provided PromoterList pointer is NULL. Cannot initialize.\n");
    exit(EXIT_FAILURE);
  }

  // Initialize PromoterList
  initPromoterList(list);

  FILE *file = fopen(filename, "r");
  if (!file)
  {
    perror("Failed to open file");
    return 0; // Return 0 if unable to open the file
  }

  char promoterName[MAX_PROMOTER_NAME_LENGTH];
  long length;
  size_t lineCount = 0; // To keep track of the number of lines read

  while (fscanf(file, "%99s %ld", promoterName, &length) == 2)
  {
    // Read max 99 chars to prevent overflow
    lineCount++; // Increase the count for every line read

    if (strlen(promoterName) >= MAX_PROMOTER_NAME_LENGTH - 1)
    {
      fprintf(stderr, "Promoter name too long: %s\n", promoterName);
      continue; // Skip this line and move to next
    }

    insertPromoter(list, promoterName, length);
  }

  if (fclose(file) != 0)
  {
    perror("Failed to close the file");
  }

  return lineCount; // Return the number of lines read
}
