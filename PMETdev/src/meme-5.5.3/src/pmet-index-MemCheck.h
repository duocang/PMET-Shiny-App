#ifndef _MEM_CHECK_H
#define _MEM_CHECK_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// // 取消malloc, calloc, free的宏定义
// #undef malloc
// #undef calloc
// #undef free

/**
 * 定义链表节点，表示一个内存泄漏信息
 */
typedef struct _mem_node
{
  void *ptr;              // 泄漏内存地址
  size_t block;           // 泄漏内存大小
  size_t line;            // 泄露发生的代码行
  char *filename;         // 泄漏发生的文件名
  struct _mem_node *next; // 下一个节点指针
} mem_node;

// // instead of malloc
// #define malloc(s) dbg_malloc(s, __FILE__, __LINE__)

// // instead of calloc
// #define calloc(c, s) dbg_calloc(c, s, __FILE__, __LINE__)

// // instead of free
// #define free(p) dbg_free(p)

// instead of malloc
#define new_malloc(s) dbg_malloc(s, __FILE__, __LINE__)

#define new_strdup(s) dbg_strdup(s, __FILE__, __LINE__)

// instead of calloc
#define new_calloc(c, s) dbg_calloc(c, s, __FILE__, __LINE__)

// instead of realloc
#define new_realloc(p, s) dbg_realloc(p, s, __FILE__, __LINE__)

// instead of free
#define new_free(p) dbg_free(p)

/**
 * allocation memory
 */
void *dbg_malloc(size_t elem_size, char *filename, size_t line);

char *dbg_strdup(const char *s, char *filename, size_t line);


/**
 * allocation and zero memory
 */
void *dbg_calloc(size_t count, size_t elem_size, char *filename, size_t line);

/**
 * The movement of memory and may return a different pointer address if the original
 * block cannot be extended.
*/
void *dbg_realloc(void *original_ptr, size_t new_size, char *filename, size_t line);

/**
 * deallocate memory
 */
void dbg_free(void *ptr);

/**
 * show memory leake report
 */
void show_block();

#endif // _MEM_CHECK_H
