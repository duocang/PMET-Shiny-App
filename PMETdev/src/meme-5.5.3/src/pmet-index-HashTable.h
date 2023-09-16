#ifndef HASH_TABLE
#define HASH_TABLE

// #include <stdlib.h>
// #include <stdio.h>
// #include <string.h>

#include "pmet-index-MemCheck.h"

// #pragma once
typedef struct HashTable HashTable;

#ifdef __cplusplus
extern "C"
{
#endif

/**
 * Defines the number of buckets in the HashTable.
 * This is not a limit on the number of key-value pairs that can be stored in the hash table.
 * Rather, it's a trade-off between memory usage and lookup efficiency.
 */
// #define TABLE_SIZE 175447
extern size_t TABLE_SIZE;

/* element of the hash table's chain list */
struct kv
{
  struct kv *next;
  char *key;
  void *value;
  void (*free_value)(void *);
};

// typedef struct kv
// {
//   struct kv *next;
//   char *key;
//   void *value;
//   void (*free_value)(void *);
// } kv;


/* HashTable */
struct HashTable
{
  struct kv **table;
};
// struct kv table: This is a pointer to a pointer, typically used for creating an array of struct pointers.
// table ----> [ptr1, ptr2, ptr3, ...]
//              |      |      |
//              V      V      V
//            [kv1]  [kv2]  [kv3]


/**
 * Create a new instance of HashTable.
 * @return - Pointer to the newly created HashTable; NULL if memory allocation failed.
 */
HashTable *createHashTable();

/**
 * Delete an instance of HashTable.
 * This function also removes all key-value pairs stored in the HashTable.
 * @param ht - Pointer to the HashTable to be deleted.
 */
void deleteHashTable(HashTable *ht);



/**
 * Convenience macro for putHashTable2 function.
 * Allows putting a key-value pair into the hash table without specifying a custom free_value function.
 * When this macro is used, putHashTable2 is called internally with NULL as the free_value argument.
 */
#define putHashTable(ht, key, value) putHashTable2(ht, key, value, NULL);

/*
add or update a value to ht,
free_value(if not NULL) is called automatically when the value is removed.
return 0 if success, -1 if error occurred.
*/
int putHashTable2(HashTable *ht, char *key, void *value, void (*free_value)(void *));

/* get a value indexed by key, return NULL if not found. */
void *getHashTable(HashTable *ht, char *key);

/* remove a value indexed by key */
void rmHashTable(HashTable *ht, char *key);

void printHashTable(const HashTable *ht, void (*print_value)(void *));

#ifdef __cplusplus
}
#endif

#endif /* MOTIF_HIT_H */