#include "pmet-index-HashTable.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* constructor of struct kv */
static void initKV(struct kv *kv)
{
  kv->next = NULL;
  kv->key = NULL;
  kv->value = NULL;
  kv->free_value = NULL;
}

/**
 * destructor of struct kv.
 * @param kv - A pointer to the struct kv that needs to be freed.
 * @note - Also calls the custom free_value function if it is not NULL.
 */
static void freeKV(struct kv *kv)
{
  if (kv)
  {
    if (kv->free_value)
    {
      kv->free_value(kv->value);
    }
    new_free(kv->key);
    kv->key = NULL;
    new_free(kv);
  }
}

/**
 * Calculates the hash value for a given key using the classic Times33 hash function.
 * @param key - The key for which the hash value is to be calculated.
 * @return - The hash value.
 * @note - This is a simple and fast hash function commonly used for string keys.
 */
static unsigned int hash33(char *key)
{
  unsigned int hash = 0;
  while (*key) // Loop through each character in the key string until the null-terminator
  {
    // Update the hash value:
    // Shift the current hash value 5 bits to the left
    // Add the previous hash value to it
    // Add the ASCII value of the next character in the key
    hash = (hash << 5) + hash + *key++;
  }
  return hash;
}
// ab

// 1. 初始化 hash = 0
// 2. 取第一个字符 'a'，ASCII 码是 97。
//     hash = (0 << 5) + 0 + 97 = 0 + 0 + 97 = 97
// 3. 取第二个字符 'b'，ASCII 码是 98。
//     hash = (97 << 5) + 97 + 98
//     hash = 3104 + 97 + 98 = 3299

/**
 * Create a new instance of HashTable.
 * @return - Pointer to the newly created HashTable; NULL if memory allocation failed.
 */
HashTable *createHashTable()
{
  HashTable *ht = new_malloc(sizeof(HashTable));
  if (NULL == ht)
  {
    deleteHashTable(ht);
    return NULL;
  }
  ht->table = new_malloc(sizeof(struct kv *) * TABLE_SIZE);
  if (NULL == ht->table)
  {
    deleteHashTable(ht);
    return NULL;
  }
  memset(ht->table, 0, sizeof(struct kv *) * TABLE_SIZE);

  return ht;
}

/**
 * Delete an instance of HashTable.
 * This function also removes all key-value pairs stored in the HashTable.
 * @param ht - Pointer to the HashTable to be deleted.
 */
void deleteHashTable(HashTable *ht)
{
  if (ht)
  {
    if (ht->table)
    {
      // Loop through each bucket in the hash table
      int i = 0;
      for (i = 0; i < TABLE_SIZE; i++)
      {
        struct kv *p = ht->table[i]; // Pointer to the head of the linked list at bucket 'i'
        struct kv *q = NULL;         // Temporary pointer for traversal
        // Traverse and free each node in the linked list at bucket 'i'
        while (p)
        {
          q = p->next; // Store the address of the next node, to q
          freeKV(p);   // Free the current node
          p = q;       // Move to the next node
        }
      }
      new_free(ht->table); // Free the hash table array
      ht->table = NULL;
    }
    new_free(ht); // Free the hash table struct
  }
}

/**
 * Inserts a new key-value pair into the HashTable, or updates the value of an existing key.
 *
 * @param ht - A pointer to the HashTable.
 * @param key - The key to insert or update.
 * @param value - The value to associate with the key.
 * @param free_value - A function pointer to the custom free function for the value; NULL if not applicable.
 * @return - 0 if successful; -1 if an error occurs (e.g., memory allocation failure).
 */
int putHashTable2(HashTable *ht, char *key, void *value, void (*free_value)(void *))
{
  // Basic error checks
  if (ht == NULL || key == NULL || value == NULL)
  {
    fprintf(stderr, "Invalid arguments to putHashTable2.\n");
    return -1;
  }

  // Calculate the bucket index
  int i = hash33(key) % TABLE_SIZE;
  // Pointer to the head node of the linked list in the bucket
  struct kv *p = ht->table[i];
  // Pointer to keep track of the previous node during traversal
  struct kv *prep = p;

  // Traverse the linked list to find if the key already exists
  while (p)
  { /* if key is already stroed, update its value */
    if (strcmp(p->key, key) == 0)
    {
      if (p->free_value)
      {
        p->free_value(p->value);
      }
      // Update the value and custom free function
      p->value = value;
      p->free_value = free_value;
      return 0; // Successfully updated
    }
    prep = p;
    p = p->next;
  }

  // Allocate memory for new key and kv struct
  char *kstr = new_strdup(key);
  if (kstr == NULL)
  {
    return -1;
  }

  struct kv *kv = new_malloc(sizeof(struct kv));
  if (kv == NULL)
  {
    new_free(kstr);
    return -1;
  }

  // Initialize the new kv struct
  initKV(kv);
  kv->next = NULL;
  kv->key = kstr;
  kv->value = value;
  kv->free_value = free_value;

  // Attach the new node to the linked list
  if (prep == NULL)
  {
    ht->table[i] = kv;
  }
  else
  {
    prep->next = kv;
  }
  return 0; // Successfully added
}

/**
 * Retrieves a value associated with a given key from the hash table.
 * @param ht - A pointer to the HashTable structure.
 * @param key - The key whose associated value needs to be retrieved.
 * @return - Pointer to the value if the key is found; NULL otherwise.
 */
void *getHashTable(HashTable *ht, char *key)
{
  // Calculate the bucket index by taking the hash of the key modulo TABLE_SIZE
  int i = hash33(key) % TABLE_SIZE;
  // Get the head of the linked list for this bucket
  struct kv *p = ht->table[i];
  // Traverse the linked list to find the key-value pair
  while (p)
  {
    // If the key matches, return the associated value
    if (strcmp(key, p->key) == 0)
    {
      return p->value;
    }
    // Move to the next element in the chain
    p = p->next;
  }
  return NULL;
}

/**
 * Removes a key-value pair associated with a given key from the hash table.
 * @param ht - A pointer to the HashTable structure.
 * @param key - The key whose associated value needs to be removed.
 */
void rmHashTable(HashTable *ht, char *key)
{
  int i = hash33(key) % TABLE_SIZE;
  // Get the head of the linked list for this bucket
  struct kv *p = ht->table[i];
  // Pointer to keep track of the previous node in the chain
  struct kv *prep = p;

  // Traverse the linked list to find the key-value pair
  while (p)
  {
    // If the key matches, remove the node and free it
    if (strcmp(key, p->key) == 0)
    {
      freeKV(p);
      // If this node was the head of the list, update the head
      if (p == prep)
      {
        ht->table[i] = NULL;
      }
      else
      {
        prep->next = p->next;
      }
    }
    // Move to the next element in the chain
    prep = p;
    p = p->next;
  }
}

void printHashTable(const HashTable *ht, void (*print_value)(void *))
{
  // Basic error checks
  if (ht == NULL || print_value == NULL)
  {
    fprintf(stderr, "Invalid arguments to printHashTable.\n");
    return;
  }

  // Iterate over each bucket in the hashtable
  int i;
  for (i = 0; i < TABLE_SIZE; i++)
  {
    struct kv *p = ht->table[i];
    while (p)
    {
      // Print key
      printf("Key: %s\n", p->key);
      // Use the passed function pointer to print the value
      print_value(p->value);
      p = p->next;
      printf("\n");
    }
  }
}
