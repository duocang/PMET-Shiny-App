#ifndef FileReade_h
#define FileReade_h

#define ERR_OPEN_FILE 1


/**
 * Reads the content of a text file and counts its number of lines.
 * @param filename The name of the file to read from.
 * @param content A pointer to the buffer where the file content will be stored.
 * @return The number of lines in the file.
 */
size_t readFileAndCountLines(const char* filename, char** content);

#endif /* FileRead_h */
