#ifndef PMET_INDEX_UTILS_H
#define PMET_INDEX_UTILS_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

/**
 * Concatenate two strings using a specified separator.
 *
 * @param sep The separator used to concatenate the strings.
 * @param string1 First string for concatenation.
 * @param string2 Second string for concatenation.
 * @return A new string that is the result of the concatenation.
 */
char *paste2(const char *sep, const char *string1, const char *string2);

/**
 * Concatenate an arbitrary number of strings using a specified separator.
 *
 * @param numStrings The number of strings to concatenate.
 * @param sep The separator used to concatenate the strings.
 * @param ... Variable number of strings for concatenation.
 * @return A new string that is the result of the concatenation.
 */
char *paste(int numStrings, const char *sep, ...);

/**
 * Extract the filename (without the extension) from a given file path.
 *
 * @param path The full path of the file.
 * @return A new string containing the filename without its extension.
 */
char *getFilenameNoExt(const char *path);

/**
 * Remove the trailing slash from a path string, if it exists.
 *
 * This function directly modifies the passed-in string.
 *
 * @param path The path string to be modified.
 */
void removeTrailingSlash(char *path);

/**
 * Remove the trailing slash from a path string, if it exists, and return a new string.
 *
 * The original string remains unchanged.
 *
 * @param path The path string from which the trailing slash should be removed.
 * @return A new string with the trailing slash removed.
 */
char *removeTrailingSlashAndReturn(const char *path);


#endif /* PMET_INDEX_UTILS_H */
