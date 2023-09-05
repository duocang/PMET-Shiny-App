#include "pmet-index-FimoFile.h"

#include <string.h>  // For strtok
#include <stdbool.h> // For bool
#include <math.h>
#include <float.h> // for DBL_MAX

void initFimoFile_(FimoFile *file)
{
  if (!file)
  {
    fprintf(stderr, "Error: Invalid FimoFile provided.\n");
    return;
  }
  // Setting the entire structure to zero ensures that all members are `NULL` or `0`:
  memset(file, 0, sizeof(FimoFile));

  file->numLines = 0;
  file->motifName = NULL;
  file->motifLength = 0;
  file->fileName = NULL;
  file->outDir = NULL;
  file->binScore = false;
  file->hasMotifAlt = false;

  printf("Value of file->nodeStore: %p\n", file->nodeStore);

  // The `FimoFile` variable allocated on the stack is not explicitly
  // initialized to 0 or `NULL`, so the `nodeStore` member may contain
  // random garbage values.
  file->nodeStore = NULL;

  // Check if the nodeStore has already been allocated.
  if (!file->nodeStore)
  {
    file->nodeStore = malloc(sizeof(NodeStore));
    if (!file->nodeStore)
    {
      fprintf(stderr, "Error: Memory allocation failed for nodeStore in initFimoFile_ function.\n");
      exit(1); // Or handle the error in another way if you prefer
    }
  }

  // Initialize the nodeStore
  initNodeStore(file->nodeStore);
}

void initFimoFile(FimoFile *file,
                  int numLines,
                  char *motifName,
                  int motifLength,
                  char *fileName,
                  char *outDir,
                  bool hasMotifAlt,
                  bool binScore)
{
  if (file == NULL)
  {
    fprintf(stderr, "Error: Provided FimoFile pointer is NULL in initFimoFile.\n");
    return;
  }
  // Setting the entire structure to zero ensures that all members are `NULL` or `0`:
  memset(file, 0, sizeof(FimoFile));

  file->numLines = numLines;
  file->motifLength = motifLength;
  file->hasMotifAlt = hasMotifAlt;
  file->binScore = binScore;

  // 使用strdup为字符串创建新的内存副本
  // If the passed pointer is NULL, strdup will return NULL, so these operations are safe.
  // this can be different in other platforms, so we do as following
  file->motifName = motifName ? strdup(motifName) : NULL;
  file->fileName = fileName ? strdup(fileName) : NULL;
  file->outDir = outDir ? strdup(outDir) : NULL;
  // check ram allocating
  if ((motifName && !file->motifName) ||
      (fileName && !file->fileName) ||
      (outDir && !file->outDir))
  {
    fprintf(stderr, "Error: Memory allocation failed for strings in initFimoFile.\n");

    // Clean up any allocated memory to avoid memory leaks
    free(file->motifName);
    free(file->fileName);
    free(file->outDir);
    return;
  }

  file->nodeStore = malloc(sizeof(NodeStore));
  if (file->nodeStore == NULL)
  {
    fprintf(stderr, "Error: Memory allocation failed for NodeStore in initFimoFile.\n");

    // Clean up the allocated memory to avoid memory leaks
    free(file->motifName);
    free(file->fileName);
    free(file->outDir);
    return;
  }
  initNodeStore(file->nodeStore);
}

// bool areFimoFilesEqual(const FimoFile *file1, const FimoFile *file2) {
//     if (file1->numLines != file2->numLines)              return false;
//     if (strcmp(file1->motifName, file2->motifName) != 0) return false;
//     if (file1->motifLength != file2->motifLength)        return false;
//     if (strcmp(file1->fileName, file2->fileName) != 0)   return false;
//     if (strcmp(file1->outDir, file2->outDir) != 0)       return false;
//     if (file1->hasMotifAlt != file2->hasMotifAlt)        return false;
//     if (file1->binScore != file2->binScore)              return false;

//     return areNodeStoresEqual(file1->nodeStore, file2->nodeStore);
// }

bool copyFimoFile(const FimoFile *source, FimoFile *dest)
{
  // Check if the provided FimoFile pointers and their nodeStores are valid
  if (!source || !dest || !source->nodeStore || !dest->nodeStore)
  {
    return false;
  }

  dest->numLines = source->numLines;
  dest->motifLength = source->motifLength;
  dest->hasMotifAlt = source->hasMotifAlt;
  dest->binScore = source->binScore; // Copying binScore

  if (source->motifName)
  {
    dest->motifName = strdup(source->motifName);
    if (!dest->motifName)
    {
      freeFimoFile(dest);
      return false; // Memory allocation failed.
    }
  }

  if (source->fileName)
  {
    dest->fileName = strdup(source->fileName);
    if (!dest->fileName)
    {
      freeFimoFile(dest);
      return false; // Memory allocation failed.
    }
  }

  if (source->outDir)
  {
    dest->outDir = strdup(source->outDir);
    if (!dest->outDir)
    {
      freeFimoFile(dest);
      return false; // Memory allocation failed.
    }
  }

  // Ensure the nodeStore is initialized for the destination
  if (!dest->nodeStore)
  {
    dest->nodeStore = malloc(sizeof(NodeStore));
    if (!dest->nodeStore)
    {
      freeFimoFile(dest);
      return false; // Memory allocation failed.
    }
    initNodeStore(dest->nodeStore);
  }
  // Here, we should also copy the content of nodes.
  // Depending on your specific needs, you might want to deep copy the list or just copy the pointers.

  // Deep copy the content of nodes.
  Node *currentSrcNode = source->nodeStore->head;
  while (currentSrcNode)
  {
    size_t i;
    for (i = 0; i < currentSrcNode->value->size; i++)
    {
      // Insert each MotifHit into the destination's NodeStore
      insertIntoNodeStore(dest->nodeStore, &(currentSrcNode->value->hits[i]));
    }
    currentSrcNode = currentSrcNode->next;
  }

  return true;
}

bool readFimoFile(FimoFile *fimoFile)
{
  // Ensure fimoFile and its nodeStore is initialized.
  if (!fimoFile ||
      !fimoFile->nodeStore ||
      !fimoFile->fileName ||
      !fimoFile->motifName ||
      !fimoFile->outDir)
  {
    fprintf(stderr, "Error: Invalid FimoFile provided.\n");
    return false;
  }

  char *fileContent;
  long numLines = readFileAndCountLines(fimoFile->fileName, &fileContent) + 1;

  if (numLines <= 0)
  {
    free(fileContent);
    return false;
  }

  fimoFile->numLines = numLines;

  char *saveptr; // Used for strtok_r
  char *line = strtok_r(fileContent, "\n", &saveptr);
  line = strtok_r(NULL, "\n", &saveptr); // skip header
  // char *line = strtok(fileContent, "\n"); // strtok` is a function that will modify its inputs
  // line = strtok(NULL, "\n"); // skip header
  int lineNum = 1;

  while (line)
  {
    char motif[256], motifAlt[256], geneID[256], sequence[256];
    int start, stop, binScore;
    char strand;
    double score, pval;
    MotifHit hit;

    if (fimoFile->binScore)
    {
      if (sscanf(line, "%255s %255s %255s %d %d %c %lf %lf %255s %d",
                 motif, motifAlt, geneID, &start, &stop, &strand, &score, &pval, sequence, &binScore) != 10)
      {
        free(fileContent);
        fprintf(stderr, "Error: Failed to parse line %d.\n", lineNum);
        return false;
      }
      initMotifHit(&hit, motif, motifAlt, geneID, start, stop, strand, score, pval, sequence, binScore);
    }
    else
    {
      if (sscanf(line, "%255s %255s %255s %d %d %c %lf %lf %255s",
                 motif, motifAlt, geneID, &start, &stop, &strand, &score, &pval, sequence) != 9)
      {
        free(fileContent);
        fprintf(stderr, "Error: Failed to parse line %d.\n", lineNum);
        return false;
      }
      initMotifHit(&hit, motif, motifAlt, geneID, start, stop, strand, score, pval, sequence, -1);
    }
    // fprintf(stderr, "基因：%s\n\n", geneID);
    fimoFile->motifLength = (stop - start) + 1;

    // Insert the hit into the NodeStore of the FimoFile
    insertIntoNodeStore(fimoFile->nodeStore, &hit);

    line = strtok_r(NULL, "\n", &saveptr); // Get next line using strtok_r
    // line = strtok(NULL, "\n"); // Get next line

    // printf("Reading line %d out of %ld lines\n", lineNum, numLines);
    lineNum++;
  }

  size_t genesNum = countNodesInStore(fimoFile->nodeStore);
  printf("%ld genes and %ld hits found related to %s\n\n", genesNum, numLines, fimoFile->motifName);

  free(fileContent); // Free the content after processing
  return true;
}

double processFimoFile(FimoFile *fimoFile, int k, int N, PromoterList *promSizes)
{
  // Null checks
  if (!fimoFile || !fimoFile->nodeStore || !promSizes)
  {
    fprintf(stderr, "Error: Null pointer passed to processFimoFile.\n");
    exit(1);
  }

  // printf("%ld\n", countNodesInStore(fimoFile->nodeStore));
  ScoreLabelPairVector *binThresholds = createScoreLabelPairVector();

  if (!binThresholds)
  {
    fprintf(stderr, "Error: Failed to create binThresholds vector.\n");
    exit(1);
  }

  Node *currentNode = fimoFile->nodeStore->head;
  size_t numDone = 0;

  while (currentNode)
  {
    char *geneID = currentNode->key;
    if (!geneID)
    {
      fprintf(stderr, "Error: Encountered a node with a null key.\n");
      deletePromoterLenList(binThresholds);
      exit(1);
    }
    size_t geneNum = countNodesInStore(fimoFile->nodeStore);
    MotifHitVector *vec = currentNode->value;
    if (!vec)
    {
      fprintf(stderr, "Error: Encountered a node with a null value.\n");
      deletePromoterLenList(binThresholds);
      exit(1);
    }

    // Sort hits within the gene based on their p-values.
    sortMotifHitVectorByPVal(vec);

    // Top k motifHit in vector with overlap with any one in the vector
    size_t currentIndex = 0;
    while (currentIndex < vec->size && currentIndex < k)
    {
      size_t nextIndex = currentIndex + 1;

      while (nextIndex < vec->size)
      {
        if (motifsOverlap(&vec->hits[currentIndex], &vec->hits[nextIndex]))
        {
          removeHitAtIndex(vec, nextIndex);
          // Do not increment nextIndex here because after removing
          // an element, the next element shifts to the current nextIndex
        }
        else
        {
          nextIndex++; // No overlap, move to next hit
        }
      }
      currentIndex++;
    }
    if (vec->size > k)
    {
      retainTopKMotifHits(currentNode->value, k);
    }

    // if (strcmp(geneID, "AT1G01470") == 0) {
    //   printMotifHitVector(currentNode->value);
    // }

    // Find the promoter size for the current gene in promSizes map
    size_t promterLength = findPromoterLength(promSizes, geneID);
    if (promterLength == -1)
    {
      printf("Error: Sequence ID: %s not found in promoter lengths file!\n", geneID);
      exit(1);
    }

    // Calculate the binomial p-value and the corresponding bin value for this gene
    Pair binom_p = geometricBinTest(currentNode->value, promterLength, fimoFile->motifLength);

    // if (strcmp(geneID, "AT1G20680") == 0) {
    //   printf(" binom_p.score：%f\n",  binom_p.score);

    //   printf(" binom_p.idx：%ld\n",  binom_p.idx);

    //   printf(" currentNode->value->size：%d\n",  currentNode->value->size);
    // }
    // Save the best bin value for this gene in the binThresholds vector
    pushBack(binThresholds, binom_p.score, geneID);

    // Resize the hits for this gene if necessary based on the bin value
    if (currentNode->value->size > (binom_p.idx + 1))
    {
      retainTopKMotifHits(currentNode->value, binom_p.idx + 1);
    }

    currentNode = currentNode->next; // go for next gene
  }                                  // while (currentNode)

  // Sort the binThresholds vector by ascending score
  sortVector(binThresholds);

  // Save the Nth best bin value and gene ID to the thresholds file
  if (binThresholds->size > N)
    retainTopN(binThresholds, N);

  DynamicArray genesDeleted;
  genesDeleted.items = malloc(sizeof(char *) * 10); // initial capacity, say 10
  genesDeleted.size = 0;
  genesDeleted.capacity = 10;

  currentNode = fimoFile->nodeStore->head;
  while (currentNode)
  {
    char *geneID = currentNode->key;

    // Check if the gene is in binThresholds.
    if (labelExists(binThresholds, geneID) != 1)
    {
      // Resize if necessary
      if (genesDeleted.size == genesDeleted.capacity)
      {
        genesDeleted.capacity *= 2; // Double the capacity
        genesDeleted.items = realloc(genesDeleted.items, sizeof(char *) * genesDeleted.capacity);
      }
      // Append geneID
      genesDeleted.items[genesDeleted.size] = strdup(geneID);
      genesDeleted.size++;
    }
    currentNode = currentNode->next; // go for next gene
  }                                  // while (currentNode)

  int i = 0;
  for (i = 0; i < genesDeleted.size; i++)
  {
    char *geneIDToDelete = genesDeleted.items[i];
    deleteNodeByKeyStore(fimoFile->nodeStore, geneIDToDelete);
  }
  // Release the memory of a dynamic array.
  for (i = 0; i < genesDeleted.size; i++)
  {
    free(genesDeleted.items[i]); // Free each strdup'ed string
  }
  free(genesDeleted.items);

  // write the bin thresholds to file
  char *outputDir = removeTrailingSlashAndReturn(fimoFile->outDir);
  printf("  Write all processed fimo results to %s\n", paste(4, "", outputDir, "/", fimoFile->motifName, ".txt"));
  writeNodeStoreToFile(fimoFile->nodeStore, paste(4, "", outputDir, "/", fimoFile->motifName, ".txt"));

  // return Nth best value to save in thresholds file
  double thresholdScore = binThresholds->items[binThresholds->size-1].score;

  free(outputDir);
  deletePromoterLenList(binThresholds); // Release the memory of a dynamic array.

  return thresholdScore;
}

Pair geometricBinTest(MotifHitVector *hitsVec, size_t promoterLength, size_t motifLength)
{
  // Null check for hitsVec
  if (!hitsVec)
  {
    fprintf(stderr, "Error: Null hitsVec provided to geometricBinTest.\n");
    exit(1); // Consider if you want to exit or handle the error differently
  }

  // Data integrity checks
  if (promoterLength <= 0 || motifLength <= 0 || motifLength > promoterLength || !hitsVec->hits)
  {
    fprintf(stderr, "Error: Invalid data provided to geometricBinTest.\n");
    exit(1); // Consider if you want to exit or handle the error differently
  }

  size_t possibleLocations = 2 * (promoterLength - motifLength + 1);

  double *pVals = (double *)malloc(hitsVec->size * sizeof(double));

  // Check memory allocation
  if (!pVals)
  {
    fprintf(stderr, "Error: Memory allocation failed in geometricBinTest.\n");
    exit(1);
  }

  size_t i;
  for (i = 0; i < hitsVec->size; i++)
  {
    pVals[i] = hitsVec->hits[i].pVal;
  }

  double lowestScore = DBL_MAX;
  size_t lowestIdx = hitsVec->size - 1;
  double product = 1.0;
  size_t k;
  for (k = 0; k < hitsVec->size; k++)
  {
    product *= pVals[k];
    double geom = pow(product, 1.0 / (k + 1.0));
    double binomP = 1 - binomialCDF(k + 1, possibleLocations, geom);

    if (lowestScore > binomP)
    {
      lowestScore = binomP;
      lowestIdx = k;
    }
  }

  free(pVals);

  Pair result;
  result.idx = lowestIdx;
  result.score = lowestScore;

  return result;
}

bool motifsOverlap(MotifHit *m1, MotifHit *m2)
{
  // Check if motifs are NULL
  if (!m1 || !m2)
  {
    return false; // Consider if you want to exit or return false in this scenario
  }

  // Check data integrity for both motifs
  if (m1->startPos > m1->stopPos || m2->startPos > m2->stopPos)
  {
    return false; // Consider if you want to exit or return false in this scenario
  }

  // Overlapping condition
  return !(m1->stopPos < m2->startPos || m1->startPos > m2->stopPos);
}

double binomialCDF(size_t numPVals, size_t numLocations, double gm)
{
  // gm is geometric mean
  if (gm <= 0.0 || gm >= 1.0 || numPVals < 0 || numPVals > numLocations)
  {
    fprintf(stderr, "Error: Invalid parameters in binomialCDF.\n");
    return -1.0; // Error value
  }

  // gm is geometric mean
  double cdf = 0.0;
  double b = 0.0;

  double logP = log(gm);
  double logOneMinusP = log(1 - gm);

  size_t k;
  for (k = 0; k < numPVals; k++)
  {
    if (k > 0)
      b += log((double)(numLocations - k + 1)) - log((double)k);
    cdf += exp(b + k * logP + (numLocations - k) * logOneMinusP);
  }
  return cdf;
}

void freeFimoFileContents(FimoFile *file)
{
  if (!file)
    return; // Check if the provided pointer is not NULL

  // Free the nodes store
  if (file->nodeStore)
  {
    freeNodeStore(file->nodeStore); // Assuming this function correctly frees the nodeStore and its inner data
    free(file->nodeStore);
    file->nodeStore = NULL;
  }

  // Free motifName if allocated
  if (file->motifName)
  {
    free(file->motifName);
    file->motifName = NULL;
  }

  // Free fileName if allocated
  if (file->fileName)
  {
    free(file->fileName);
    file->fileName = NULL;
  }

  // Free outDir if allocated
  if (file->outDir)
  {
    free(file->outDir);
    file->outDir = NULL;
  }

  printf("FimoFile (contents only) has been released!\n");
}

void freeFimoFile(FimoFile *file)
{
  freeFimoFileContents(file);

  // Finally, free the FimoFile struct itself
  free(file);

  printf("FimoFile (including itself) has been released!\n");
}

// 创建一个假的Fimo文件
void createMockFimoFile(const char *fileName)
{
  FILE *file = fopen(fileName, "w");
  if (!file)
  {
    fprintf(stderr, "Error: Unable to create mock Fimo file.\n");
    return;
  }

  // 这是一个简单的模拟内容。请根据您的真实格式进行修改。
  // fprintf(file, "HEADER LINE\n");
  fprintf(file, "motif_id	motif_alt_id	sequence_name	start	stop	strand	score	p-value	q-value	matched_sequence\n");
  fprintf(file, "MOTIF1 MOTIF1-ALT GENE1 1 3 + 0.5 0.001 SEQ1 1\n");
  fprintf(file, "MOTIF2 MOTIF2-ALT GENE2 2 4 + 0.6 0.002 SEQ2 0\n");
  fclose(file);
}