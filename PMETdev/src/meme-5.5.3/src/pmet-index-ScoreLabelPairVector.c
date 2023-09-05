#include "pmet-index-ScoreLabelPairVector.h"

ScoreLabelPairVector *createScoreLabelPairVector()
{
  ScoreLabelPairVector *vec = (ScoreLabelPairVector *)malloc(sizeof(ScoreLabelPairVector));
  if (!vec)
  {
    perror("Failed to allocate memory for ScoreLabelPairVector");
    exit(EXIT_FAILURE);
  }
  vec->items = NULL;
  vec->size = 0;
  vec->capacity = 0;
  return vec;
}

int comparePairs(const void *a, const void *b)
{
  double diff = ((ScoreLabelPair *)a)->score - ((ScoreLabelPair *)b)->score;
  return (diff > 0.0) - (diff < 0.0);
}

void sortVector(ScoreLabelPairVector *vec)
{
  if (!vec || !vec->items)
  {
    fprintf(stderr, "Warning: Attempted to sort a NULL or uninitialized ScoreLabelPairVector. Operation skipped.\n");
    return;
  }

  qsort(vec->items, vec->size, sizeof(ScoreLabelPair), comparePairs);
}

bool pushBack(ScoreLabelPairVector *vec, double score, char *label)
{
  if (!vec || !label)
  {
    fprintf(stderr, "Warning: Received NULL vector or label in pushBack. Operation skipped.\n");
    return false;
  }

  if (vec->size >= vec->capacity)
  {
    size_t newCapacity = vec->capacity == 0 ? 4 : vec->capacity * 2;
    ScoreLabelPair *newItems = (ScoreLabelPair *)realloc(vec->items, newCapacity * sizeof(ScoreLabelPair));
    if (!newItems)
    {
      fprintf(stderr, "Memory allocation failed in pushBack.\n");
      return false;
    }
    vec->items = newItems;
    vec->capacity = newCapacity;
  }

  vec->items[vec->size].score = score;
  // 分配内存并复制标签
  /*
      内存泄漏：你在pushBack函数里直接将传入的label指针赋值给vec->items[vec->size].label。
      如果你传入的是一个栈上的局部字符串，那么当这个字符串超出其作用域时，你的动态数组里的指针将
      会指向无效的内存。为了解决这个问题，你应该在pushBack函数里为label分配堆内存，并复制字符
      串到这片内存。
  */
  vec->items[vec->size].label = strdup(label);
  if (!vec->items[vec->size].label)
  {
    fprintf(stderr, "Memory allocation for label failed in pushBack.\n");
    return false;
  }

  vec->size++;
  return true;
}

void retainTopN(ScoreLabelPairVector *vec, size_t N)
{
  if (!vec)
  {
    fprintf(stderr, "Error: Received NULL vector in retainTopN.\n");
    return;
  }

  // If N is greater than or equal to the current size, do nothing
  if (N >= vec->size)
  {
    return;
  }

  // Free memory for labels that are beyond the Nth element
  size_t i;
  for (i = N; i < vec->size; ++i)
  {
    free(vec->items[i].label);
  }

  // Update the size of the vector to N
  vec->size = N;

  // Resize the items array to match the new size
  // realloc 的结果（即可能的新地址）被赋给一个新的指针变量 newItems，
  // 而原始的 vec->items 保持不变。这样，如果 realloc 失败并返回 NULL，
  // 你仍然有原始的 vec->items 指针指向之前分配的内存，这样你就不会丢失对
  // 那块内存的引用，可以在后续中安全地释放它。
  ScoreLabelPair *newItems = realloc(vec->items, N * sizeof(ScoreLabelPair));
  if (newItems == NULL)
  {
    fprintf(stderr, "Error: Memory reallocation failed in retainTopN.\n");
    return; // Just return. It's up to the calling function to check the state of the vector and decide how to proceed.
  }
  vec->items = newItems;
  vec->capacity = N; // Update the capacity to N
}

int labelExists(const ScoreLabelPairVector *vec, const char *searchLabel)
{
  if (!vec || !searchLabel)
  {
    fprintf(stderr, "Warning: NULL argument passed to labelExists().\n");
    return NOT_FOUND;
  }
  size_t i;
  for (i = 0; i < vec->size; i++)
  {
    if (strcmp(vec->items[i].label, searchLabel) == 0)
    {
      return FOUND; // Label found
    }
  }
  return NOT_FOUND; // Label not found
}

double findScoreByLabel(ScoreLabelPairVector *vec, const char *searchLabel)
{
  if (!vec || !searchLabel)
  {
    fprintf(stderr, "Warning: NULL argument passed to findScoreByLabel().\n");
    return LABEL_NOT_FOUND;
  }

  size_t i;
  for (i = 0; i < vec->size; i++)
  {
    if (strcmp(vec->items[i].label, searchLabel) == 0)
    {
      return vec->items[i].score;
    }
  }
  return LABEL_NOT_FOUND; // Label not found
}

void printVector(ScoreLabelPairVector *vec)
{
  if (!vec)
  {
    fprintf(stderr, "Warning: NULL vector passed to printVector().\n");
    return;
  }

  printf("Printing vector contents:\n");
  printf("==========================\n");
  size_t i;
  for (i = 0; i < vec->size; i++)
  {
    printf("Item %zu - Score: %.15f, Label: %s\n", i, vec->items[i].score, vec->items[i].label);
  }
  printf("==========================\n");
}

void deleteScoreLabelVectorContent(ScoreLabelPairVector *vec)
{
  if (!vec)
  {
    return;
  }
  // Free each label
  size_t i;
  for (i = 0; i < vec->size; i++)
  {
    free(vec->items[i].label);
    vec->items[i].label = NULL;
  }

  // Free the items array
  free(vec->items);
  vec->items = NULL;
}

void deleteScoreLabelVector(ScoreLabelPairVector *vec)
{
  if (!vec)
  {
    return;
  }

  deleteScoreLabelVectorContent(vec);

  // Free the vector itself
  free(vec);
}

void writeScoreLabelPairVectorToTxt(ScoreLabelPairVector *vector, const char *filename)
{
  if (!vector || !filename)
  {
    fprintf(stderr, "Warning: NULL vector passed to printVector().\n");
    return;
  }

  FILE *file = fopen(filename, "a");
  if (!file)
  {
    perror("Unable to open file for writing");
    return;
  }

  // // Assuming the first line to be headers
  // fprintf(file, "Score\tLabel\n");
  size_t i;
  for (i = 0; i < vector->size; i++)
  {
    fprintf(file, "%s\t%.15f\n", vector->items[i].label, vector->items[i].score);
  }

  if (fclose(file) != 0)
  {
    perror("Error closing the file");
  }
}
