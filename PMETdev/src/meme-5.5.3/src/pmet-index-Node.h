#ifndef MOTIF_HIT_VECTOR_NODE_H
#define MOTIF_HIT_VECTOR_NODE_H

#include "pmet-index-MotifHitVector.h"

// Node structure for the linked list based store.
typedef struct Node
{
  char *key;
  MotifHitVector *value;
  struct Node *next;
} Node;

typedef struct
{
  Node *head;
} NodeStore;

/**
 * Initializes a KeyValueStore.
 * @param store - A pointer to the NodeStore structure to initialize.
 */
void initNodeStore(NodeStore *store);

/**
 * Finds a node with the given key in the store.
 * @param store - A pointer to the NodeStore structure.
 * @param key - The key to look for.
 * @return - Pointer to the Node if found; NULL otherwise.
 */
Node *findNodeInStore(NodeStore *store, const char *key);

/**
 * Compare two NodeStore.
 * @param store1 The source FimoFile.
 * @param store2 The destination FimoFile.
 * @return Boolean indicating equality.
 */
bool areNodeStoresEqual(NodeStore *store1, NodeStore *store2);

/**
 * Inserts a MotifHit into the store.
 * @param store - A pointer to the NodeStore structure.
 * @param hit - The MotifHit structure to insert.
 */
void insertIntoNodeStore(NodeStore *store, const MotifHit* hit);


/**
 * Inserts a MotifHitVector into the store.
 * @param store - A pointer to the NodeStore structure.
 * @param vec - The MotifHitVector structure to insert.
 */
void insertVectorIntoNodeStore(NodeStore *store, const char *key, MotifHitVector* vec);

/**
 * Frees memory allocated for the KeyValueStore.
 * @param store - A pointer to the NodeStore structure to free.
 */
void freeNodeStore(NodeStore *store);

/**
 * Prints the contents of the NodeStore.
 * @param Node* - A pointer to the Node structure.
 */
void printSingleNode(Node *node);

/**
 * Prints the contents of the NodeStore.
 * @param store - A pointer to the NodeStore structure.
 */
void printNodeStore(NodeStore *store);

/**
 * Counts the number of nodes in the store.
 * @param store - A pointer to the NodeStore structure.
 * @return - The total count of nodes in the store.
 */
size_t countNodesInStore(NodeStore *store);

/**
 * Counts the total number of MotifHits across all nodes in the store.
 * @param store - A pointer to the NodeStore structure.
 * @return - The total count of MotifHits in the store.
 */
size_t countAllMotifHitsInStore(NodeStore *store);

/**
 * Deletes a node associated with the given key from the store.
 * @param store - A pointer to the NodeStore structure.
 * @param key - The key of the node to delete.
 * @return  - True for deleting successfully
 */
bool deleteNodeByKeyStore(NodeStore *store, const char *key);

/**
 * Writes all the MotifHits in a node to a file.
 * @param node - A pointer to the NodeS structure.
 * @param filename - The name of the file where to write the MotifHits.
 */
void writeSingleNodeToFile(const Node *node, const char *filename);

/**
 * Writes all the MotifHits in the store to a file.
 * @param store - A pointer to the NodeStore structure.
 * @param filename - The name of the file where to write the MotifHits.
 */
void writeNodeStoreToFile(const NodeStore* store, const char* filename);


#endif /* MOTIF_HIT_VECTOR_NODE_H */
