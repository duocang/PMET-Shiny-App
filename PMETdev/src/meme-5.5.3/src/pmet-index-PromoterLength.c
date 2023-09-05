#include <stdio.h>
#include <stdlib.h>
#include <string.h>

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

void deletePromoterLenListContent(PromoterList *list)
{
  if (!list)
  {
    fprintf(stderr, "Warning: Attempted to free a NULL PromoterList. Operation skipped.\n");
    return;
  }

  Promoter *current = list->head;
  while (current)
  {
    Promoter *toDelete = current;
    if (toDelete->promoterName)
    {
      free(toDelete->promoterName);
    }
    current = current->next;
    free(toDelete);
  }
  list->head = NULL;
}

void deletePromoterLenList(PromoterList *list)
{
  if (!list)
  {
    fprintf(stderr, "Warning: Attempted to free a NULL PromoterList. Operation skipped.\n");
    return;
  }

  deletePromoterLenListContent(list);

  free(list);
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

  Promoter *newPromoter = (Promoter *)malloc(sizeof(Promoter));
  if (!newPromoter)
  {
    perror("Failed to allocate memory for new promoter");
    exit(EXIT_FAILURE);
  }

  newPromoter->promoterName = strdup(promoterName);
  if (!newPromoter->promoterName)
  {
    perror("Failed to allocate memory for promoter name");
    free(newPromoter);
    exit(EXIT_FAILURE);
  }

  newPromoter->length = length;
  newPromoter->next = list->head;
  list->head = newPromoter;
}

void readPromoterLengthFile(PromoterList *list, const char *filename)
{
  if (list == NULL)
  {
    fprintf(stderr, "Error: The provided PromoterList pointer is NULL. Cannot initialize.\n");
    exit(EXIT_FAILURE);
  }
  // 初始化PromoterList
  initPromoterList(list);
  FILE *file = fopen(filename, "r");
  if (!file)
  {
    perror("Failed to open file");
    return;
  }

  char promoterName[MAX_PROMOTER_NAME_LENGTH];
  long length;
  while (fscanf(file, "%99s %ld", promoterName, &length) == 2)
  { // Read max 99 chars to prevent overflow
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
}
