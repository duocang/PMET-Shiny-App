#include "pmet-index-Node.h"
#include <string.h> // for strcmp
#include <stdio.h>

void initNodeStore(NodeStore *store)
{
  // Check if the provided pointer is not NULL
  if (store == NULL)
  {
    fprintf(stderr, "Error: Provided NodeStore pointer is NULL in initNodeStore.\n");
    return;
  }

  store->head = NULL;
}

// bool areNodeStoresEqual(NodeStore *store1, NodeStore *store2)
// {
//   // Check for NULL pointers
//   if (!store1 || !store2)
//   {
//     fprintf(stderr, "Error: One or both NodeStores provided are NULL.\n");
//     return false;
//   }

//   Node *node1 = store1->head;
//   Node *node2 = store2->head;

//   while (node1 && node2)
//   {
//     // Check node keys for NULL before comparing
//     if ((!node1->key || !node2->key) ||
//         (strcmp(node1->key, node2->key) != 0))
//     {
//       return false;
//     }

//     // Check MotifHitVectors for NULL before comparing
//     if (!node1->value || !node2->value)
//     {
//       fprintf(stderr, "Error: One or both MotifHitVectors in a Node are NULL.\n");
//       return false;
//     }

//     // Compare MotifHitVectors
//     if (!areMotifHitVectorsEqual(node1->value, node2->value))
//     {
//       return false;
//     }

//     node1 = node1->next;
//     node2 = node2->next;
//   }

//   // If either of the linked lists has additional nodes, they aren't equal
//   if (node1 || node2)
//   {
//     return false;
//   }

//   return true;
// }

Node *findNodeInStore(NodeStore *store, const char *key)
{
  if (store == NULL)
  {
    fprintf(stderr, "Error: Provided NodeStore pointer is NULL in findNodeInStore.\n");
    return NULL;
  }

  if (key == NULL)
  {
    fprintf(stderr, "Error: Provided key pointer is NULL in findNodeInStore.\n");
    return NULL;
  }

  Node *current = store->head;
  while (current != NULL)
  {
    if (strcmp(current->key, key) == 0)
    {
      return current;
    }
    current = current->next;
  }
  return NULL;
}

void insertIntoNodeStore(NodeStore *store, const MotifHit *hit)
{
  if (store == NULL)
  {
    fprintf(stderr, "Error: Provided NodeStore pointer is NULL in insertIntoNodeStore.\n");
    return;
  }

  if (hit == NULL)
  {
    fprintf(stderr, "Error: Provided MotifHit pointer is NULL in insertIntoNodeStore.\n");
    return;
  }

  if (hit->sequence_name == NULL || hit->motif_alt_id == NULL || hit->motif_id == NULL || hit->sequence == NULL)
  {
    fprintf(stderr, "Error: One or more of the string fields in MotifHit is NULL.\n");
    exit(EXIT_FAILURE); // or handle it in a manner appropriate to your application
  }

  Node *node = findNodeInStore(store, hit->sequence_name);

  // If node with the key is not found, create a new one.
  if (!node)
  {
    node = malloc(sizeof(Node));
    if (!node)
    {
      fprintf(stderr, "Error: Failed to allocate memory for a Node in insertIntoNodeStore.\n");
      return;
    }

    node->key = strdup(hit->sequence_name);
    if (!node->key)
    {
      fprintf(stderr, "Error: Failed to allocate memory for a key in insertIntoNodeStore.\n");
      free(node);
      return;
    }

    node->value = malloc(sizeof(MotifHitVector));
    if (!node->value)
    {
      fprintf(stderr, "Error: Failed to allocate memory for MotifHitVector in insertIntoNodeStore.\n");
      free(node->key);
      free(node);
      return;
    }

    initMotifHitVector(node->value);
    node->next = store->head;
    store->head = node;
  }

  // Insert the hit into the node's vector.
  pushMotifHitVector(node->value, hit);
}

void freeNodeStore(NodeStore *store)
{
  Node *current = store->head;
  while (current)
  {
    Node *temp = current;
    free(current->key);
    current->key = NULL; // Set to NULL after freeing

    deleteMotifHitVectorContents(current->value); // This also frees internal strings and the hits array
    free(current->value);
    current->value = NULL; // Set to NULL after freeing

    current = current->next; // Move to the next node before freeing current one
    free(temp);
    temp = NULL; // Set to NULL after freeing
  }
  store->head = NULL; // Ensure the head of the store is NULL after all nodes are deleted
}

void printNodeStore(NodeStore *store)
{
  if (store == NULL)
  {
    fprintf(stderr, "Error: The given NodeStore pointer is NULL.\n");
    return;
  }

  if (store->head == NULL)
  {
    printf("The NodeStore is empty.\n");
    return;
  }

  Node *node = store->head;
  while (node)
  {
    if (node->key == NULL)
    {
      fprintf(stderr, "Error: Encountered a node with a NULL key.\n");
      return;
    }
    printf("Key: %s\n", node->key);

    if (node->value == NULL)
    {
      fprintf(stderr, "Error: Encountered a node with a NULL value.\n");
      return;
    }

    for (size_t i = 0; i < node->value->size; ++i)
    {
      if (node->value->hits == NULL)
      {
        fprintf(stderr, "Error: The hits array in a node's value is NULL.\n");
        return;
      }
      printMotifHit(&node->value->hits[i]);
    }
    printf("------------------\n\n");
    node = node->next;
  }
}

size_t countNodesInStore(NodeStore *store)
{
  if (store == NULL)
  {
    fprintf(stderr, "Error: The given NodeStore pointer is NULL.\n");
    return 0; // Return 0 as there's no node to count, or handle as deemed fit for your application.
  }

  size_t count = 0;
  Node *current = store->head;
  while (current)
  {
    count++;
    current = current->next;
  }
  return count;
}

size_t countAllMotifHitsInStore(NodeStore *store)
{
  Node *current = store->head;
  if (current == NULL)
  {
    fprintf(stderr, "Error: The provided Node pointer is NULL.\n");
    return 0; // 返回0或其他适当的错误代码
  }

  size_t totalCount = 0; // 用于累计所有MotifHit的计数

  // 遍历链表
  while (current != NULL)
  {
    if (current->value != NULL)
    { // 检查MotifHitVector是否为NULL
      totalCount += current->value->size;
    }
    else
    {
      fprintf(stderr, "Warning: Encountered a Node with a NULL MotifHitVector. Skipping.\n");
    }
    current = current->next;
  }

  return totalCount;
}

bool deleteNodeByKeyStore(NodeStore *store, const char *key)
{
  if (store == NULL || key == NULL || store->head == NULL)
    return false; // 返回false表示没有删除节点

  Node *current = store->head;
  Node *prev = NULL;

  while (current != NULL)
  {
    if (strcmp(current->key, key) == 0)
    {
      // 当前节点的key与给定的key匹配
      if (prev == NULL)
      {
        // 我们正在删除头结点
        store->head = current->next;
      }
      else
      {
        prev->next = current->next;
      }

      // 清除资源
      deleteMotifHitVectorContents(current->value); // 假设MotifHitVector有一个free函数
      free(current->key);
      free(current);
      return true; // 返回true表示节点已被删除
    }

    prev = current;
    current = current->next;
  }

  return false; // 如果循环结束还没返回，说明没有找到匹配的节点
}

void writeMotifHitsToFile(const NodeStore *store, const char *filename)
{
  if (store == NULL || filename == NULL)
  {
    fprintf(stderr, "Invalid parameters provided to writeMotifHitsToFile.\n");
    return;
  }
  FILE *file = fopen(filename, "w");
  if (file == NULL)
  {
    fprintf(stderr, "Failed to open the file for writing.\n");
    return;
  }

  Node *currentNode = store->head;
  while (currentNode)
  {
    MotifHitVector *vec = currentNode->value;
    for (size_t i = 0; i < vec->size; i++)
    {
      MotifHit hit = vec->hits[i];

      // Assuming you want to write each field of MotifHit to the file.
      // Adjust the format as needed.
      // fprintf(file, "%s\t%s\t%s\t%ld\t%ld\t%c\t%f\t%f\t%s\t%f\n",
      //         hit.motif_id,
      //         hit.motif_alt_id,
      //         hit.sequence_name,
      //         hit.startPos,
      //         hit.stopPos,
      //         hit.strand,
      //         hit.score,
      //         hit.pVal,
      //         hit.sequence,
      //         hit.binScore);
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
    currentNode = currentNode->next;
  }

  if (fclose(file) != 0)
  {
    fprintf(stderr, "Error closing the file %s.\n", filename);
  }
}
