#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/mman.h>
#include <stdbool.h>
#include "alphabet.h"
#include "array-list.h"
#include "config.h"
#include "hash_table.h"
#include "io.h"
#include "simple-getopt.h"
#include "string-builder.h"
#include "string-list.h"
#include "utils.h"

typedef struct {
  char *name;
  long start_offset;
  long length;
  long line_length;
  long line_length_bytes;
} INDEX_ENTRY;

// Structure for tracking bed2fasta command line parameters.
typedef struct options {
  bool rc;  // Emit reverse complement if feature strand is '-'
  bool use_bed_name_only; // Use BED name for FASTA header
  bool use_both; // Add BED name after coordinates in FASTA header
  char *bed_filename;
  char *genome_filename;
  char *fasta_filename;
  char *error_filename;
  const char* usage; // Usage statement
} BED_TO_FASTA_OPTIONS_T;

char* program_name = "bed2fasta";
FILE *error_file = NULL;
VERBOSE_T verbosity = NORMAL_VERBOSE;

// Look up a name in the hash table.
INDEX_ENTRY *find_index_entry(HASH_TABLE entry_hash_table, char *name) {
  INDEX_ENTRY *entry = NULL;
  HASH_TABLE_ENTRY *hte = hash_lookup_str(name, entry_hash_table);
  if (hte) {
    entry = hash_get_entry_value(hte);
  }
  return entry;
}

// Create a FASTA header for a sequence.
char *build_fasta_header(
  char *chrom, 
  long chrom_start, 
  long chrom_end, 
  char *bed_name, 
  char strand, 
  BED_TO_FASTA_OPTIONS_T *options
) {
  const int MIN_HEADER_SIZE = 80;
  STR_T *fasta_header = str_create(MIN_HEADER_SIZE);
  if (options->use_bed_name_only) {
    // Use only the BED name entry and NOT the BED coordinates
    str_appendf(
	fasta_header,
	">%s", 
	bed_name
      );
  } else {
    // Use the BED chromosome entry.
    str_appendf(
	fasta_header,
	">%s:%ld-%ld",
	chrom,
	chrom_start,
	chrom_end
      );
    // Include strand info after chromosome info.
    if (options->rc) str_appendf(fasta_header, "(%c)", strand);
  }
  // Use BED name entry and BED coordinates:
  //   add feature name as part of FASTA header
  if (options->use_both) {
    str_appendf(fasta_header, " %s", bed_name);
  }
  return str_destroy(fasta_header, 1);
}

// Print out a region.
void print_region_data(
FILE *output, 
char *data, 
INDEX_ENTRY *entry,
char* chrom,
long start, 		// region start
long end,		// region end
char* bed_name,
  char strand,
  BED_TO_FASTA_OPTIONS_T *options
) {
  // Extract region. 
  long region_len = end - start;
  char *seq = mm_calloc(region_len, sizeof(char));

  long num_lines = start / entry->line_length;
  long map_position = entry->start_offset 
    + (num_lines * entry->line_length_bytes)
    + (start % entry->line_length);

  // First line may be a partial line
  long length = MIN(region_len, entry->line_length - (start % entry->line_length));
  char *seq_position = seq;
  memmove(seq_position, data+map_position, length); 
  seq_position += length;
  map_position += (entry->line_length - (start % entry->line_length)) 
    + (entry->line_length_bytes - entry->line_length);

  // Middle lines.
  num_lines = end / entry->line_length;
  long final_position = entry->start_offset + num_lines * entry->line_length_bytes;
  //while (seq_position - seq < region_len && map_position < final_position) {
  while (seq_position - seq < region_len) {
    length = MIN(region_len - (seq_position - seq), entry->line_length);
    memmove(seq_position, data+map_position, length); 
    map_position += entry->line_length_bytes;
    seq_position += length;
  }

  // Possible partial last line
  //length = end % entry->line_length;
  length = MIN(region_len - (seq_position - seq), end % entry->line_length);
  if (length > 0) memmove(seq_position, data+map_position, length); 
  if (options->rc && strand == '-') {
    // Print reverse complement
    ALPH_T *alph = alph_dna();
    invcomp_seq(alph, seq, region_len, true);
    fwrite(seq, 1, region_len, output);
    alph_release(alph);
  } else {
    // Print direct region. 
    fwrite(seq, 1, region_len, output);
  }
  fputs("\n", output);
  myfree(seq);
}

/***********************************************************************
  Process command line options
 ***********************************************************************/
static BED_TO_FASTA_OPTIONS_T process_bed_to_fasta_command_line(
  int argc,
  char* argv[]
) {

  BED_TO_FASTA_OPTIONS_T options;

  // Define command line options.
  cmdoption const bed_to_fasta_options[] = {
      {"name", NO_VALUE}, 
      {"both", NO_VALUE}, 
      {"help", NO_VALUE}, 
      { "o", REQUIRED_VALUE}, 
      { "e", REQUIRED_VALUE}, 
      { "s", NO_VALUE}, 
      {"version", NO_VALUE}
  };
  const int num_options = sizeof(bed_to_fasta_options) / sizeof(cmdoption);

  // Define the usage message.
  options.usage =
    "Usage: bed2fasta [options] <BED file> <genome file>\n"
    "   Options:\n"
    "     -o  <file name>    output the sequences to the named file; default: output\n"
    "                          the sequences to standard output\n"
    "     -s                 output reverse complement sequence if strand\n"
    "                          is '-'; default: ignore the strand information\n"
    "     -name              use just the name field from the BED file for the\n"
    "                          FASTA header; default: use just the coordinates\n"
    "     -both              include the name field from the BED file as comment\n"
    "                          after the coordinates in the FASTA header;\n"
    "                          default: use just the coordinates\n"
    "     -version           print the version number and exit\n"
    "     -help              display the usage message and exit\n"
    "\n";

  options.rc = false;
  options.use_both = false;
  options.use_bed_name_only = false;
  options.bed_filename = NULL;
  options.genome_filename = NULL;
  options.fasta_filename = NULL;
  options.error_filename = NULL;

  simple_setopt(argc, argv, num_options, bed_to_fasta_options);

  int option_index = 0;

  // Parse the command line.
  while (true) {
    int c = 0;
    char* option_name = NULL;
    char* option_value = NULL;
    const char* message = NULL;

    // Read the next option, and break if we're done.
    c = simple_getopt(&option_name, &option_value, &option_index);
    if (c == 0) {
      break;
    }
    else if (c < 0) {
      (void) simple_getopterror(&message);
      die("Error processing command line options: %s\n", message);
    }
    if (strcmp(option_name, "s") == 0){
      options.rc = true;
    }
    if (strcmp(option_name, "o") == 0){
      options.fasta_filename =  option_value;
    }
    if (strcmp(option_name, "e") == 0){
      options.error_filename =  option_value;
    }
    else if (strcmp(option_name, "name") == 0){
      options.use_bed_name_only = true;
    }
    else if (strcmp(option_name, "both") == 0){
      options.use_both = true;
    }
    else if (strcmp(option_name, "version") == 0) {
      fprintf(stdout, VERSION "\n");
      exit(EXIT_SUCCESS);
    }
    else if (strcmp(option_name, "help") == 0) {
      fprintf(stderr, "%s", options.usage);
      exit(EXIT_SUCCESS);
    }
  }

  if (argc != option_index + 2) {
    fprintf(stderr, "%s", options.usage);
    exit(EXIT_FAILURE);
  }

  options.bed_filename = argv[option_index];
  option_index++;
  options.genome_filename = argv[option_index];
  option_index++;

  return options;
}

int main(int argc, char *argv[]) {
  // Get the program options
  BED_TO_FASTA_OPTIONS_T options = process_bed_to_fasta_command_line(argc, argv);

  // Open an error file if requested, otherwise use stderr.
  error_file = options.error_filename ? fopen(options.error_filename, "w") : stderr;

  // Open genome file as memory mapped 
  errno = 0; 
  FILE *genome_file = fopen(options.genome_filename, "r"); 
  if (genome_file == NULL) { 
    perror("Error:");
    die("Unable to open the genome FASTA file %s\n", options.genome_filename);
  }

  // Get length of file by fseeking to the EOF
  errno = 0;
  int status = fseek(genome_file,  0L, SEEK_END);
  if (status < 0) {
    perror("Error:");
    die("Unable to determine size of the genome FASTA file %s\n", options.genome_filename);
  }
  long file_size = ftell(genome_file);
  int genome_fd = fileno(genome_file);
  char *genome_data = mmap((caddr_t) 0, file_size, PROT_READ, MAP_PRIVATE, genome_fd, 0);

  // Open BED file for reading
  errno = 0;
  FILE *bed_file = fopen(options.bed_filename, "r");
  if (bed_file == NULL) {
    perror("Error:");
    die("Unable to open the BED file %s\n", options.bed_filename);
  }

  // Open index file for reading
  const int MIN_FILENAME_SIZE = 80;
  const char* INDEX_FILENAME_SUFFIX = ".fai";
  STR_T *index_filename_builder = str_create(MIN_FILENAME_SIZE);
  str_append2(index_filename_builder, options.genome_filename);
  str_append2(index_filename_builder, ".fai");
  char * index_filename = str_destroy(index_filename_builder, 1);
  errno = 0;
  FILE *index_file = fopen(index_filename, "r");
  if (index_file == NULL) {
    // TODO changes to create index file on the fly
    perror("Error:");
    die("Unable to open the index file %s\n", index_filename);
  }

  // Open FASTA file for writing
  FILE *fasta_file = stdout;
  if (options.fasta_filename != NULL) {
    errno = 0;
    fasta_file = fopen(options.fasta_filename, "w");
    if (fasta_file == NULL) {
      perror("Error:");
      die("Unable to open the FASTA file %s\n", options.fasta_filename);
    }
  }

  // Read the index into memory
  char* line = NULL;
  HASH_TABLE entry_hash_table = hash_create(10000, free);
  while ((line = getline2(index_file)) != NULL) {
    STRING_LIST_T* entry_values  = new_string_list_char_split('\t', line);
    INDEX_ENTRY *entry = calloc(1, sizeof(INDEX_ENTRY));
    entry->name = strdup(get_nth_string(0, entry_values));
    entry->length = strtol(get_nth_string(1, entry_values), NULL, 10);
    entry->start_offset = strtol(get_nth_string(2, entry_values), NULL, 10);
    entry->line_length = strtol(get_nth_string(3, entry_values), NULL, 10);
    entry->line_length_bytes = strtol(get_nth_string(4, entry_values), NULL, 10);
    hash_insert_str_value(entry->name, (void *) entry, entry_hash_table);
    myfree(line);
    free_string_list(entry_values);
  }

  // Iterate through the BED file
  while ((line = getline2(bed_file)) != NULL) {
    if (line[0] == '#') {
      myfree(line);
      continue;
    }
    int length = strlen(line);
    // Trim trailing newline
    if (line[length - 1] == '\n') line[length - 1] = 0;
    STRING_LIST_T* bed_values  = new_string_list_char_split('\t', line);
    int num_fields = get_num_strings(bed_values);
    char *chrom = get_nth_string(0, bed_values);
    long chrom_start = strtol(get_nth_string(1, bed_values), NULL, 10);
    long chrom_end = strtol(get_nth_string(2, bed_values), NULL, 10);
    char *bed_name = get_nth_string(3, bed_values);
    char strand = '\0';
    if (chrom_start < 0) {
      fprintf(error_file, "WARNING: Feature (%s:%ld-%ld) has start < 0. Skipping.\n", 
        chrom, chrom_start, chrom_end);
      continue;
    }
    if (chrom_end < 0) {
      fprintf(error_file, "WARNING: Feature (%s:%ld-%ld) has end < 0. Skipping.\n", 
        chrom, chrom_start, chrom_end);
      continue;
    }
    if (chrom_end - chrom_start < 0) {
      fprintf(error_file, "WARNING: Feature (%s:%ld-%ld) has length < 0. Skipping.\n", 
        chrom, chrom_start, chrom_end);
      continue;
    }
    if (chrom_end - chrom_start == 0) {
      fprintf(error_file, "WARNING: Feature (%s:%ld-%ld) has length = 0. Skipping.\n", 
        chrom, chrom_start, chrom_end);
      continue;
    }
    // Get the strand field.
    if (num_fields >= 5) {
      strand = get_nth_string(5, bed_values)[0];
    }
    // Allow funky strand fields like fastaFromBed and assume positive strand.
    if (strand != '-') strand = '+';
    if (0) {
      if (strand != '+' && strand != '-' && strand != '.') {
        fprintf(error_file, "WARNING: Feature (%s:%ld-%ld) has unrecognized strand '%c'. Skipping.\n", 
          chrom, chrom_start, chrom_end, strand);
        continue;
      }
    }
    
    char *fasta_header = build_fasta_header(
      chrom, chrom_start, chrom_end, 
      bed_name, strand, &options
    );
    INDEX_ENTRY *entry = find_index_entry(entry_hash_table, chrom);
    if (entry) {
      if (chrom_end <= entry->length) {
        fprintf(fasta_file, "%s\n", fasta_header);
        print_region_data(
            fasta_file, 
            genome_data, 
            entry,
            chrom,
            chrom_start, 
            chrom_end,
            bed_name,
            strand,
            &options
        );
      }
      else {
        fprintf(
          error_file, 
          "WARNING: Feature (%s:%ld-%ld) beyond length of %s size (%ld bp). Skipping.\n", 
          chrom, chrom_start, chrom_end, 
          entry->name, entry->length
        );
      }
    }
    else {
        fprintf(
          error_file, 
          "WARNING: Feature (%s:%ld-%ld) not found in genome file %s. Skipping.\n", 
          chrom, chrom_start, chrom_end, options.genome_filename
        );
    }
    myfree(line);
    myfree(fasta_header);
    free_string_list(bed_values);
  }

  hash_destroy(entry_hash_table);
  fclose(fasta_file);
  fclose(genome_file);
  fclose(index_file);

  return 0;
}
