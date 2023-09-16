#include "pmet-index-MotifHitVector.h"
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

// Returns the current size of the MotifVector.
size_t motifHitVectorSize(const MotifHitVector *vec)
{
  return vec->size;
}

// Prints all hits in the MotifVector to the console.
void printMotifHitVector(const MotifHitVector *vec)
{
  size_t i;
  for (i = 0; i < vec->size; ++i)
  {
    printMotifHit(&(vec->hits[i]));
  }
}

void adapterPrintFunction(void *ptr)
{
  printMotifHitVector((MotifHitVector *)ptr);
}

MotifHitVector *createMotifHitVector()
{
  // 分配内存空间给 MotifHitVector
  MotifHitVector *newVec = (MotifHitVector *)new_malloc(sizeof(MotifHitVector));
  if (newVec == NULL)
  {
    #ifdef DEBUG
    fprintf(stderr, "Failed to allocate memory for MotifHitVector.\n");
    #endif

    return NULL;
  }

  // 初始化新的 MotifHitVector 的属性
  newVec->size = 0;
  newVec->capacity = 10; // 你可以根据需要改变这个初始容量
  newVec->hits = (MotifHit *)new_malloc(newVec->capacity * sizeof(MotifHit));
  if (newVec->hits == NULL)
  {
    #ifdef DEBUG
    fprintf(stderr, "Failed to allocate memory for hits array.\n");
    #endif

    new_free(newVec);
    return NULL;
  }

  return newVec;
}

void initMotifHitVector(MotifHitVector *vec)
{
  vec->hits = (MotifHit *)new_malloc(sizeof(MotifHit));
  if (!vec->hits)
  {
    fprintf(stderr, "Failed to allocate memory for MotifVector.\n");

    exit(EXIT_FAILURE);
  }
  vec->size = 0;
  vec->capacity = 1;
}

void pushMotifHitVector(MotifHitVector *vec, const MotifHit *hit)
{
  // Check if capacity expansion is required
  if (vec->size == vec->capacity)
  {
    vec->capacity *= 2;
    vec->hits = (MotifHit *)new_realloc(vec->hits, vec->capacity * sizeof(MotifHit));

    // Still need to check if realloc is successful. If there is not enough memory, realloc will return NULL.
    if (!vec->hits)
    {
      // Handle out-of-memory situations, such as printing an error message and exiting
      fprintf(stderr, "Failed to reallocate memory for MotifVector.\n");

      exit(EXIT_FAILURE);
    }
  }

  /*  Copy the content of the new element to an array.
   *  Field-by-field copying (using `new_strdup`) is a deep
   *  copy method that ensures independent copies of string fields.
   */
  vec->hits[vec->size].motif_id = new_strdup(hit->motif_id);
  vec->hits[vec->size].motif_alt_id = new_strdup(hit->motif_alt_id);
  vec->hits[vec->size].sequence_name = new_strdup(hit->sequence_name);
  vec->hits[vec->size].startPos = hit->startPos;
  vec->hits[vec->size].stopPos = hit->stopPos;
  vec->hits[vec->size].strand = hit->strand;
  vec->hits[vec->size].score = hit->score;
  vec->hits[vec->size].pVal = hit->pVal;
  vec->hits[vec->size].sequence = new_strdup(hit->sequence);
  vec->hits[vec->size].binScore = hit->binScore;

  // Shallow copy. This means that the string field only copies the pointer, not the actual data.
  // vec->hits[vec->size] = *hit;

  vec->size++;
}

int compareMotifHitsByPVal(const void *a, const void *b)
{
  double pValA = ((MotifHit *)a)->pVal;
  double pValB = ((MotifHit *)b)->pVal;

  if (pValA < pValB)
    return -1;
  if (pValA > pValB)
    return 1;
  return 0;
}

void sortMotifHitVectorByPVal(MotifHitVector *vec)
{
  qsort(vec->hits, vec->size, sizeof(MotifHit), compareMotifHitsByPVal);
}

void retainTopKMotifHits(MotifHitVector *vec, size_t k)
{
  if (!vec || k >= vec->size)
  {
    // If k is greater than the current size or the vector is not initialized, simply return.
    return;
  }

  // Resize the vector to only keep top k elements.
  size_t i;
  size_t new_size = k;
  for (i = new_size; i < vec->size; ++i)
  {
    // MotifHit has dynamic memory allocations like strings, free them here.
    deleteMotifHitContents(&vec->hits[i]);
  }
  // 使用realloc来重新分配vec->hits的大小
  vec->hits = new_realloc(vec->hits, new_size * sizeof(MotifHit));
  vec->size = new_size;
}

void removeHitAtIndex(MotifHitVector *vec, size_t indx)
{
  if (!vec || indx >= vec->size)
  {
    return; // Invalid vector or index
  }

  // Free memory of removed hits
  deleteMotifHitContents(&vec->hits[indx]);

  // Move elements to the left
  size_t i;
  for (i = indx; i < vec->size - 1; ++i)
  {
    vec->hits[i] = vec->hits[i + 1];
  }

  vec->size--; // Decrement the size

  // Consider resizing the capacity if size is much smaller than capacity
  if (vec->size < vec->capacity / 2)
  {
    vec->capacity /= 2; // halve the capacity
    MotifHit *newSpace = (MotifHit *)new_realloc(vec->hits, sizeof(MotifHit) * vec->capacity);
    if (newSpace)
    {
      vec->hits = newSpace;
    }
    else
    {
      perror("Memory reallocation failed in removeHitAtIndex");
      exit(EXIT_FAILURE);
    }
  }
}

void deleteMotifHitVectorContents(MotifHitVector *vec)
{
  size_t i;
  for (i = 0; i < vec->size; i++)
  {
    deleteMotifHitContents(&(vec->hits[i]));
  }
  new_free(vec->hits);
  vec->hits = NULL;
  vec->size = 0;
  vec->capacity = 0;
}

void deleteMotifHitVector(MotifHitVector *vec)
{
  deleteMotifHitVectorContents(vec);
  new_free(vec);
}

void adapterDeleteFunction(void *ptr)
{
  deleteMotifHitVector((MotifHitVector *)ptr);
}

void writeVectorToFile(const MotifHitVector *vec, const char *filename)
{
  if (vec == NULL || vec->hits == NULL || filename == NULL)
  {
    fprintf(stderr, "Invalid parameters provided to writeVectorToFile.\n");
    return;
  }

  FILE *file = fopen(filename, "a");
  if (file == NULL)
  {
    fprintf(stderr, "Failed to open the file for writing.\n");
    return;
  }

  size_t i;
  for (i = 0; i < vec->size; i++)
  {
    MotifHit hit = vec->hits[i];
    fprintf(file, "%s\t%s\t%ld\t%ld\t%c\t%f\t%.3e\t%s\n",
            hit.motif_id,
            hit.sequence_name,
            hit.startPos,
            hit.stopPos,
            hit.strand,
            hit.score,
            hit.pVal,
            hit.sequence);
  }

  if (fclose(file) != 0)
  {
    fprintf(stderr, "Error closing the file %s.\n", filename);
  }
}