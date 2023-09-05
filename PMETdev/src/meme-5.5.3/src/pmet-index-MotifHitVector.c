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
    printMotifHit(stdout, &(vec->hits[i]));
  }
}

void initMotifHitVector(MotifHitVector *vec)
{
  vec->hits = (MotifHit *)malloc(sizeof(MotifHit));
  if (!vec->hits)
  {
    fprintf(stderr, "Failed to allocate memory for MotifVector.\n");
    exit(EXIT_FAILURE);
  }
  vec->size = 0;
  vec->capacity = 1;
}

void pushMotifHitVector(MotifHitVector* vec, const MotifHit* hit)
{
    // Check if capacity expansion is required
    if (vec->size == vec->capacity)
    {
        vec->capacity *= 2;
        vec->hits = (MotifHit*)realloc(vec->hits, vec->capacity * sizeof(MotifHit));

        // Still need to check if realloc is successful. If there is not enough memory, realloc will return NULL.
        if (!vec->hits)
        {
            // Handle out-of-memory situations, such as printing an error message and exiting
            fprintf(stderr, "Failed to reallocate memory for MotifVector.\n");
            exit(EXIT_FAILURE);
        }
    }

    /*  Copy the content of the new element to an array.
     *  Field-by-field copying (using `strdup`) is a deep
     *  copy method that ensures independent copies of string fields.
    */
    vec->hits[vec->size].motif_id = strdup(hit->motif_id);
    vec->hits[vec->size].motif_alt_id = strdup(hit->motif_alt_id);
    vec->hits[vec->size].sequence_name = strdup(hit->sequence_name);
    vec->hits[vec->size].startPos = hit->startPos;
    vec->hits[vec->size].stopPos = hit->stopPos;
    vec->hits[vec->size].strand = hit->strand;
    vec->hits[vec->size].score = hit->score;
    vec->hits[vec->size].pVal = hit->pVal;
    vec->hits[vec->size].sequence = strdup(hit->sequence);
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

MotifHitVector* deepCopyMotifHitVector(const MotifHitVector *original) {
  if (original == NULL) {
    return NULL;
  }

  // Allocate memory for new MotifHitVector
  MotifHitVector *copy = malloc(sizeof(MotifHitVector));
  if (copy == NULL) {
    fprintf(stderr, "Error: Could not allocate memory for MotifHitVector copy.\n");
    return NULL;
  }

  copy->size = original->size;
  copy->capacity = original->capacity;

  // Allocate memory for data array
  copy->hits = malloc(original->capacity * sizeof(MotifHit));
  if (copy->hits == NULL) {
    fprintf(stderr, "Error: Could not allocate memory for MotifHitVector data copy.\n");
    free(copy);
    return NULL;
  }

  // Deep copy each MotifHit
  size_t i;
  for (i = 0; i < original->size; ++i) {
    MotifHit *origHit = &original->hits[i];
    MotifHit *copyHit = &copy->hits[i];

    // Copy simple fields
    // ... (other fields)

    // Deep copy sequence_name
    copyHit->sequence_name = strdup(origHit->sequence_name);
    if (copyHit->sequence_name == NULL) {
      fprintf(stderr, "Error: Could not allocate memory for sequence_name copy.\n");
      // Clean up
      size_t j;
      for (j = 0; j < i; ++j) {
        free(copy->hits[j].sequence_name);
        // ... (other dynamically allocated fields)
      }
      free(copy->hits);
      free(copy);
      return NULL;
    }

    // Deep copy motif_id
    copyHit->motif_id = strdup(origHit->motif_id);
    if (copyHit->motif_id == NULL) {
      fprintf(stderr, "Error: Could not allocate memory for motif_id copy.\n");
      // Clean up
      free(copyHit->sequence_name);
      size_t j;
      for (j = 0; j < i; ++j) {
        free(copy->hits[j].sequence_name);
        // ... (other dynamically allocated fields)
      }
      free(copy->hits);
      free(copy);
      return NULL;
    }
  }

  return copy;
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
  size_t new_size = k;
  size_t i;
  for (i = new_size; i < vec->size; ++i)
  {
    // Optional: If your MotifHit has dynamic memory allocations like strings, free them here.
    // Example: free(vec->hits[i].someString);

    // For now, if there are no such allocations, we can leave this loop empty.
  }
  // 使用realloc来重新分配vec->hits的大小
  vec->hits = realloc(vec->hits, new_size * sizeof(MotifHit));
  vec->size = new_size;
}

void removeHitAtIndex(MotifHitVector *vec, size_t indx)
{
  if (!vec || indx >= vec->size)
  {
    return; // Invalid vector or index
  }

  size_t i;
  for (i = indx; i < vec->size - 1; ++i)
  {
    vec->hits[i] = vec->hits[i + 1]; // Move elements to the left
  }

  vec->size--; // Decrement the size

  // // Optionally, you can reallocate memory to shrink the dynamic array
  // vec->hits = realloc(vec->hits, sizeof(MotifHit) * vec->size);

  // Consider resizing the capacity if size is much smaller than capacity
  if (vec->size < vec->capacity / 2)
  {
    vec->capacity /= 2; // halve the capacity
    MotifHit *newSpace = realloc(vec->hits, sizeof(MotifHit) * vec->capacity);
    if (newSpace)
    {
      vec->hits = newSpace;
    }
    else
    {
      // realloc failed; it's up to you how you want to handle this.
      // For now, I'm printing an error and exiting.
      perror("Memory reallocation failed in removeHitAtIndex");
      exit(EXIT_FAILURE);
    }
  }
}

void deleteMotifHitVectorContent(MotifHitVector *vec) {
  size_t i;
  for (i = 0; i < vec->size; i++)
  {
    free(vec->hits[i].motif_id);
    free(vec->hits[i].motif_alt_id);
    free(vec->hits[i].sequence_name);
    free(vec->hits[i].sequence);
  }
  free(vec->hits);
  vec->hits = NULL;
  vec->size = 0;
  vec->capacity = 0;
}

void deleteMotifHitVector(MotifHitVector *vec) {
  deleteMotifHitVectorContent(vec);
  free(vec);
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