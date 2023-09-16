#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "pmet-index-FileRead.h"
#include "pmet-index-MemCheck.h"


size_t readFileAndCountLines(const char *filename, char **content)
{
  long flength;
  size_t numLines = 0;
  FILE *file = fopen(filename, "r"); // Open the file in text mode.

  if (!file)
  {
    perror("Error opening file");
    exit(ERR_OPEN_FILE);
  }

  // Get the file length.
  fseek(file, 0, SEEK_END);
  flength = ftell(file);

  if (flength == -1L)
  { // Check for ftell error
    perror("Error determining file size");
    fclose(file);
    exit(ERR_OPEN_FILE);
  }

  fseek(file, 0, SEEK_SET);

  // Allocate memory for the buffer.
  *content = (char *)new_malloc(flength + 1);
  if (!*content)
  {
    perror("Error allocating memory");
    fclose(file);
    exit(1);
  }

  // Read the file content into the buffer.
  size_t bytesRead = fread(*content, 1, flength, file);
  if (bytesRead != flength)
  { // Check if read was successful
    perror("Error reading file");
    new_free(*content);
    fclose(file);
    exit(ERR_OPEN_FILE);
  }

  (*content)[flength] = '\0'; // Null-terminate the string.

  if (fclose(file) != 0)
  { // Check fclose for errors
    perror("Error closing the file");
  }

  // Count the number of lines in the buffer.
  for (long i = 0; i < flength; i++)
  {
    if ((*content)[i] == '\n')
    {
      numLines++;
    }
  }

  // Check for the last line without a newline character.
  if (flength > 0 && (*content)[flength - 1] != '\n')
  {
    numLines++;
  }

  return numLines;
}
