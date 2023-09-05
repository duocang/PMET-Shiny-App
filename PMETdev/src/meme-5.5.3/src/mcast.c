/**************************************************************************
 * FILE: mcast.c
 * AUTHOR: William Stafford Noble, Timothy L. Bailey, Charles Grant
 * CREATE DATE: 5/21/02
 * PROJECT: MEME Suite
 * COPYRIGHT: 1998-2002, WNG, 2001-2023, TLB
 * DESCRIPTION: Search a database of sequences using a motif-based
 * HMM with star topology.
 **************************************************************************/

#ifdef MAIN
#define DEFINE_GLOBALS
#endif

#include <assert.h>
#include <errno.h>
#include <float.h>
#include <inttypes.h>
#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include "../config.h"
#include "matrix.h"
#include "array.h"
#include "array-list.h"
#include "build-hmm.h"
#include "dir.h"
#include "dp.h"
#include "fasta-io.h"
#include "fitevd.h"
#include "gendb.h"
#include "heap.h"
#include "io.h"
#include "log-hmm.h"
#include "mcast-match.h"
#include "mhmm.h"
#include "mhmms.h"
#include "mhmm-state.h"
#include "mhmmscan.h"
#include "motif.h"
#include "motif-in.h"
#include "object-list.h"
#include "prior-reader-from-psp.h"
#include "prior-reader-from-wig.h"
#include "qvalue.h"
#include "red-black-tree.h"
#include "seq-reader-from-fasta.h"
#include "simple-getopt.h"
#include "transfac.h"
#include "macros.h"
#include "utils.h"

typedef enum { MEME_FORMAT, TRANSFAC_FORMAT } MOTIF_FORMAT_T;

const int IGNORE_QUERY_LENGTH = 1;

typedef struct mcast_options {
  char *motif_filename; 		// Name of file containg motifs.
  char *seq_filename;			// Name of file contaning sequences.
  char *output_dirname; 		// Name of the output directory
  bool allow_clobber;			// Allow overwritting of files in output directory.
  bool text_only; 			// Don't generate XML/HTML
  MOTIF_FORMAT_T motif_format;		// MEME or Transfac
  int max_total_width;			// Limit total width of motifs unless this is -1.
  bool hard_mask;			// Convert nucleotides in lower case to wildcard.
  bool parse_genomic_coord;		// Parse genomic coord. from seq. headers.
  char *bg_filename; 			// Name of file file containg background freq.
  char *psp_filename; 			// Path to file containing position specific priors (PSP)
  double alpha;				// Alpha parementer that was used for calculating PSPs.
  char *prior_distribution_filename; 	// Path to file containing prior distribution.
  double motif_pthresh;			// Minimum score for a motif to be a "hit".
  int max_gap;				// Longest distance between two "hits" in a "match".
  OUTPUT_THRESH_TYPE_T output_thresh_type;	// Choose E-, p- or q-value.
  double e_thresh;			// Only output matches with this or better.
  double p_thresh;			// Only output matches with this or better.
  double q_thresh;			// Only output matches with this or better.
  int max_stored_scores;		// Max # scores used for distribution estimation.
  uint32_t seed; 			// random number generator seed for random sequences
} MCAST_OPTIONS_T;

#define DEFAULT_ALPHA 1.0
#define DEFAULT_MOTIF_PTHRESH 0.0005
#define DEFAULT_MAX_GAP 50
#define DEFAULT_OUTPUT_ETHRESH 10.0
#define DEFAULT_MAX_STORED_SCORES 100000
#define DEFAULT_SEED 0

/*****************************************************************************
 * Print a usage message with an optional reason for failure.
 *****************************************************************************/
static void usage(char *format, ...) {
  va_list argp;
  char *usage =
    "Usage: mcast [options] <motifs> <sequence database>\n"
     "\n"
     "  --o <output dir>              Name of output directory. Existing files will not be\n"
     "                                  overwritten; (default: mcast_out).\n"
     "  --oc <output dir>             Name of output directory. Existing files will be\n"
     "                                  overwritten.\n"
     "  --text                        Plain text output only.\n"
     "  --transfac                    Motif file is in TRANSFAC format; (default: MEME format).\n"
     "  --max-total-width <value>     Maximum combined width of all motifs; (default: no limit).\n"
     "  --hardmask                    Nucleotides in lower case will be converted to 'N' \n"
     "                                   preventing them from being considered in motif matches.\n"
     "  --parse-genomic-coord         Parse genomic coordinates found in sequence headers.\n"
     "  --bfile <file>                File containing n-order Markov background model.\n"
     "  --psp <value>                 File containing position specific priors; (default: none).\n"
     "  --prior-dist <value>          File containing distribution of position specific priors.\n"
     "                                  Required if --psp is specified;\n"
     "                                  (default: none).\n"
     "  --alpha <value>               The fraction of all TF binding sites that are binding sites\n"
     "                                  for the TF of interest. Used in the calculation of PSP;\n"
     "                                  (default: %.1g).\n"
     "  --motif-pthresh <value>       p-value threshold for motif hits; (default: %g).\n"
     "  --max-gap <value>             Maximum allowed distance between adjacent hits;\n"
     "                                  (default: %d).\n"
     "  --output-ethresh <value>      Print only results with E-values less than <value>;\n"
     "                                  (default: %g).\n"
     "  --output-pthresh <value>      Print only results with p-values less than <value>;\n"
     "                                  (default: E-value threshold is used).\n"
     "  --output-qthresh <value>      Print only results with q-values less than <value>./\n"
     "                                  (default: E-value threshold is used).\n"
     "  --max-stored-scores <value>   Maximum number of matches that will be stored in memory;\n"
     "                                  (default: %d).\n"
     "  --seed <value>                MCAST uses this seed int the generation of the random sequences\n"
     "                                  that it uses to estimate the significance of matches;\n"
     "                                  (default: %d).\n"
     "  --version                     Print version and exit.\n"
     "  --verbosity <value>           Verbosity of error messages, with <value> in the range 0-5;\n"
     "                                  (default: %d).\n";

  // Parse the command line.

  if (format) {
    fprintf(stderr, "\n");
    va_start(argp, format);
    vfprintf(stderr, format, argp);
    va_end(argp);
    fprintf(stderr, "\n");
  }
  fprintf(stderr, usage, 
    DEFAULT_ALPHA, 
    DEFAULT_MOTIF_PTHRESH, 
    DEFAULT_MAX_GAP, 
    DEFAULT_OUTPUT_ETHRESH,
    DEFAULT_MAX_STORED_SCORES, 
    DEFAULT_SEED,
    NORMAL_VERBOSE
  );
  fflush(stderr);
  exit(EXIT_FAILURE);
} // usage

/***********************************************************************
 * process_command_line
 *
 * This functions translates the command line options into MCAST settings.
 ***********************************************************************/
static void process_command_line(
  int argc,
  char* argv[],
  MCAST_OPTIONS_T *options
) {

  // Set default values for command line arguments
  options->motif_filename = NULL;
  options->seq_filename = NULL;
  options->output_dirname = "mcast_out";
  options->allow_clobber = true;
  options->text_only = false;
  options->motif_format = MEME_FORMAT;
  options->max_total_width = -1;
  options->hard_mask = false;
  options->parse_genomic_coord = false;
  options->bg_filename = NULL;
  options->psp_filename = NULL;
  options->alpha = DEFAULT_ALPHA;
  options->prior_distribution_filename = NULL;
  options->motif_pthresh = DEFAULT_MOTIF_PTHRESH;
  options->max_gap = DEFAULT_MAX_GAP;
  options->output_thresh_type = EVALUE;
  options->e_thresh = DEFAULT_OUTPUT_ETHRESH;
  options->p_thresh = 1.0;
  options->q_thresh = 1.0;
  options->max_stored_scores = DEFAULT_MAX_STORED_SCORES;
  options->seed = DEFAULT_SEED;

  int option_index = 0;

  cmdoption const mcast_options[] = {
    {"o", REQUIRED_VALUE},
    {"oc", REQUIRED_VALUE},
    {"text", NO_VALUE},
    {"transfac", NO_VALUE},
    {"max-total-width", REQUIRED_VALUE},
    {"hardmask", NO_VALUE},
    {"parse-genomic-coord", NO_VALUE},
    {"bfile", REQUIRED_VALUE},
    {"bgfile", REQUIRED_VALUE},
    {"psp", REQUIRED_VALUE},
    {"alpha", REQUIRED_VALUE},
    {"prior-dist", REQUIRED_VALUE},
    {"motif-pthresh", REQUIRED_VALUE},
    {"max-gap", REQUIRED_VALUE},
    {"output-ethresh", REQUIRED_VALUE},
    {"output-pthresh", REQUIRED_VALUE},
    {"output-qthresh", REQUIRED_VALUE},
    {"max-stored-scores", REQUIRED_VALUE},
    {"seed", REQUIRED_VALUE},
    {"version", NO_VALUE},
    {"verbosity", REQUIRED_VALUE}
  };
  const int num_options = sizeof(mcast_options) / sizeof(cmdoption);
  simple_setopt(argc, argv, num_options, mcast_options);

  while (1) { 
    int c = 0;
    char* option_name = NULL;
    char* option_value = NULL;
    const char* message = NULL;

    // Read the next option, and break if we're done.
    c = simple_getopt(&option_name, &option_value, &option_index);
    if (c == 0) {
      break;
    } else if (c < 0) {
      simple_getopterror(&message);
      usage("Error processing command line options: %s\n", message);
    }

    // Assign the parsed value to the appropriate variable
    if (strcmp(option_name, "bfile") == 0 || strcmp(option_name, "bgfile") == 0) {
      options->bg_filename = option_value;
    } else if (strcmp(option_name, "hardmask") == 0) {
      options->hard_mask = true;
    } else if (strcmp(option_name, "max-gap") == 0) {
      options->max_gap = atoi(option_value);
      if (options->max_gap < 0) {
        die("max_gap must be positve!");
      }
    } else if (strcmp(option_name, "max-stored-scores") == 0) {
      options->max_stored_scores = atoi(option_value);
      if (options->max_stored_scores < 0) {
        die("max-stored-scores must be positve!");
      }
    } else if (strcmp(option_name, "max-total-width") == 0) {
      options->max_total_width = atoi(option_value);
      if (options->max_total_width < 1) {
        die("max-total-width must be positve!");
      }
    } else if (strcmp(option_name, "motif-pthresh") == 0) {
      options->motif_pthresh = atof(option_value);
      if (options->motif_pthresh < 0.0 || options->motif_pthresh > 1.0) {
        die("Motif p-value threshold must be between 0.0 and 1.0!");
      }
    } else if (strcmp(option_name, "o") == 0){
      // Set output directory with no clobber
      options->output_dirname = option_value;
      options->allow_clobber = false;
    } else if (strcmp(option_name, "oc") == 0){
      // Set output directory with clobber
      options->output_dirname = option_value;
      options->allow_clobber = true;
    } else if (strcmp(option_name, "output-ethresh") == 0) {
      options->output_thresh_type = EVALUE;
      options->e_thresh = atof(option_value);
      if (options->e_thresh <= 0.0) {
        die("E-value threshold must be positve!");
      }
      options->p_thresh = 1.0;
      options->q_thresh = 1.0;
    } else if (strcmp(option_name, "output-pthresh") == 0) {
      options->output_thresh_type = PVALUE;
      options->e_thresh = DBL_MAX;
      options->p_thresh = atof(option_value);
      if (options->p_thresh < 0.0 || options->p_thresh > 1.0) {
        die("p-value threshold must be between 0.0 and 1.0!");
      }
      options->q_thresh = 1.0;
    } else if (strcmp(option_name, "alpha") == 0) {
      options->alpha = atof(option_value);
      if (options->alpha < 0.0 || options->alpha > 1.0) {
        die("alpha must be between 0.0 and 1.0!");
      }
    } else if (strcmp(option_name, "output-qthresh") == 0) {
      options->output_thresh_type = QVALUE;
      options->e_thresh = 1.0;
      options->p_thresh = 1.0;
      options->q_thresh = atof(option_value);
      if (options->q_thresh < 0.0 || options->q_thresh > 1.0) {
        die("q-value threshold must be between 0.0 and 1.0!");
      }
    } else if (strcmp(option_name, "parse-genomic-coord") == 0) {
      options->parse_genomic_coord = true;
    } else if (strcmp(option_name, "psp") == 0) {
      options->psp_filename = option_value;
    } else if (strcmp(option_name, "prior-dist") == 0) {
      options->prior_distribution_filename = option_value;
    } else if (strcmp(option_name, "seed") == 0) {
      if (sscanf(option_value, "%" SCNu32, &(options->seed)) != 1) {
        die("Seed \"%s\" could not be interpreted as an unsigned 32bit integer", option_value);
      }
    } else if (strcmp(option_name, "text") == 0) {
      options->text_only = true;
    } else if (strcmp(option_name, "transfac") == 0) {
      options->motif_format = TRANSFAC_FORMAT;
    } else if (strcmp(option_name, "verbosity") == 0) {
      verbosity = atoi(option_value);
    } else if (strcmp(option_name, "version") == 0) {
      fprintf(stdout, VERSION "\n");
      exit(EXIT_SUCCESS);
    }
  }

  // Read and verify the two required arguments.
  if (option_index + 2 != argc) {
    usage("");
    exit(1);
  }
  options->motif_filename = argv[option_index];
  options->seq_filename = argv[option_index+1];
     
  if (options->motif_filename == NULL) {
    usage("No motif file given.\n");
  }
  if (options->seq_filename == NULL) {
    usage("No sequence file given.\n%s");
  }

  // Check that position specific priors options are consistent
  if (options->psp_filename != NULL 
      && options->prior_distribution_filename == NULL) {
    die(
      "Setting the --psp option requires that the"
      " --prior-dist option be set as well.\n"
    );
  }
  if (options->psp_filename == NULL 
      && options->prior_distribution_filename != NULL) {
    die(
      "Setting the --prior-dist option requires that the"
      " --psp option be set as well.\n");
  }
}

/******************************************************************************
 * build_scan_options_from_mcast_options
 *
 * This function builds the mhmmscan settings from the provided MCAST settings
 *****************************************************************************/
static void build_scan_options_from_mcast_options(
  int argc,
  char *argv[],
  MCAST_OPTIONS_T *mcast_options,
  ALPH_T *alph,
  MHMMSCAN_OPTIONS_T *scan_options
) {

  init_mhmmscan_options(scan_options);
  scan_options->alphabet = alph_hold(alph);
  scan_options->bg_filename = mcast_options->bg_filename;
  scan_options->command_line = get_command_line(argc, argv);
  scan_options->motif_filename = mcast_options->motif_filename;

  // Set up output file paths

  scan_options->output_dirname = mcast_options->output_dirname;
  scan_options->program = "mcast";
  scan_options->mhmmscan_filename = "mcast.xml";
  scan_options->mhmmscan_path 
    = make_path_to_file(
        mcast_options->output_dirname, 
        scan_options->mhmmscan_filename
      );
  scan_options->cisml_path 
    = make_path_to_file(
        mcast_options->output_dirname, 
        scan_options->CISML_FILENAME
      );
  const char *etc_dir = get_meme_data_dir();
  scan_options->html_path
    = make_path_to_file(mcast_options->output_dirname, "mcast.html");
  scan_options->gff_path
    = make_path_to_file(mcast_options->output_dirname, "mcast.gff");
  scan_options->text_path
    = make_path_to_file(mcast_options->output_dirname, "mcast.tsv");

  scan_options->seq_filename = mcast_options->seq_filename;
  scan_options->allow_weak_motifs = true;
  scan_options->beta = 4.0;
  scan_options->egcost = 1;
  scan_options->hard_mask = mcast_options->hard_mask;
  scan_options->max_gap = mcast_options->max_gap;
  scan_options->max_gap_set = true;
  scan_options->max_total_width = mcast_options->max_total_width;
  scan_options->motif_pthresh = mcast_options->motif_pthresh;
  scan_options->motif_scoring = true;
  scan_options->e_thresh = mcast_options->e_thresh;
  scan_options->p_thresh = mcast_options->p_thresh;
  scan_options->q_thresh = mcast_options->q_thresh;
  scan_options->output_thresh_type = mcast_options->output_thresh_type;
  scan_options->text_only = mcast_options->text_only;
  scan_options->use_pvalues = true;
} // build_scan_options_from_mcast_options

/***********************************************************************
 * motif_num_cmp
 *
 * This function compares motifs by motif number.
 * It's a utility function for use with red-black tree structure
 ***********************************************************************/
static int motif_num_cmp(const void *p1, const void *p2) {
  int i1, i2, abs_i1, abs_i2;
  i1 = *((int*)p1);
  i2 = *((int*)p2);
  abs_i1 = (i1 < 0 ? -i1 : i1);
  abs_i2 = (i2 < 0 ? -i2 : i2);
  if (abs_i1 < abs_i2) { // sort motifs ascending
    return -1;
  } else if (abs_i1 > abs_i2) {
    return 1;
  } else {
    if (i1 > i2) { // put reverse complements second
      return -1;
    } else if (i1 == i2) {
      return 0;
    } else {
      return 1;
    }
  }
}

/******************************************************************************
 * read_motifs
 *
 * This function reads the motifs from a MEME motif file into an array of 
 * motif data structures.
 *****************************************************************************/
void read_motifs(
  MCAST_OPTIONS_T *options, // IN
  ARRAY_T **background,     // OUT
  int *num_motifs,          // OUT
  MOTIF_T **motif_array,    // OUT
  ALPH_T **alph             // OUT
) {

  ARRAYLST_T *meme_motifs;
  double pseudocount = 0.0;
  int total_width = 0;
  int max_total_width = options->max_total_width;
  int n_skipped_total = 0;
  int n_skipped_width = 0;

  MOTIF_T *motif;
  RBTREE_T *motifs = NULL;
  RBTREE_T *ids2nums = NULL; // mapping of motif IDs to numbers

  /**********************************************
   * READING THE MOTIFS
   **********************************************/

  if (options->motif_format == MEME_FORMAT) {
    MREAD_T *mread = mread_create(options->motif_filename, OPEN_MFILE | CALC_AMBIGS, true);
    //mread_set_bg_source(mread, "motif-file");
    mread_set_bg_source(mread, options->bg_filename, NULL);	// TLB; 13-Feb-2017
    mread_set_pseudocount(mread, pseudocount);

    // Check the alphabet
    // Note that we may be able to relax this constraint to any alphabet that has
    // 2 complementary pairs.
    *alph = alph_hold(mread_get_alphabet(mread));
    ALPH_T *dna_alph = alph_dna();
    if (!alph_equal(dna_alph, *alph)) {
      die("The provided motifs don't seem to be in the DNA alphabet.");
    }
    alph_release(dna_alph);
    motifs = rbtree_create(motif_num_cmp, rbtree_intcpy, free, NULL, destroy_motif);

    int motif_i, rc_motif_i;
    for (motif_i = 1, rc_motif_i = -1; mread_has_motif(mread); ++motif_i, --rc_motif_i) {
      motif = mread_next_motif(mread);
      int width = get_motif_length(motif);
      if (width < 2) {
        DEBUG_FMT(NORMAL_VERBOSE,
          "Skipping motif %s because its width (%d) is less than 2.\n", 
	  get_motif_id(motif), width);
        n_skipped_width++;
        continue;
      }
      total_width += width;
      if (max_total_width == -1 || total_width <= max_total_width) {
	set_motif_strands(motif);		// needed if strands line was missing or bad
	rbtree_make(motifs, &motif_i, motif);
	rbtree_make(motifs, &rc_motif_i, dup_rc_motif(motif));
      } else {
        DEBUG_FMT(QUIET_VERBOSE,
          "Skipping motif %s because the total combined widths of your motifs exceeds the allowed maximum (%d).\n", 
	  get_motif_id(motif), max_total_width);
        n_skipped_total++;
      }
    }
    *background = mread_get_background(mread);
    mread_destroy(mread);

    // Check that the size of the motifs is not too large.
    if (n_skipped_width > 0) {
      fprintf(stderr, "Skipped %d motif(s) because they were too short.\n", n_skipped_width);
    }
    if (max_total_width != -1 && total_width > max_total_width) {
      fprintf(stderr, "Skipped %d motif(s) because the combined widths of your valid motifs exceeds the allowed maximum (%d > %d).\n", 
	n_skipped_total, total_width, max_total_width);
    }

    // Turn tree into simple array
    motif_tree_to_array(motifs, motif_array, num_motifs);
    rbtree_destroy(motifs);
  }
  else if (options->motif_format == TRANSFAC_FORMAT) {
    ARRAYLST_T *tfac_motifs = read_motifs_from_transfac_file(options->motif_filename);
    *alph = alph_dna();
    *background = get_background(*alph, options->bg_filename);
    ARRAYLST_T *meme_motifs = convert_transfac_motifs_to_meme_motifs(
        true, 
        pseudocount, 
        *background, 
        tfac_motifs
      );
    add_reverse_complements(meme_motifs);
    motif_list_to_array(meme_motifs, motif_array, num_motifs);
    arraylst_destroy(NULL, meme_motifs);
    arraylst_destroy(free_transfac_motif, tfac_motifs);
  }
  else {
    die("Unrecognized motif format. MCAST only supports MEME and TRANSFAC formats.");
  }

  if (*num_motifs <= 0) {
    die("No valid motifs could be read from %s.", options->motif_filename);
  }
} // read_motifs

/******************************************************************************
 * build_hmm_from_motifs
 *
 * This function builds a star topology HMM from an dynamic array of MEME
 * motif data structures.
 *****************************************************************************/
static void build_hmm_from_motifs(
  MCAST_OPTIONS_T *options, // IN
  ARRAY_T *background,      // IN
  int num_motifs,           // IN
  MOTIF_T *motif_array,     // IN
  MHMM_T **hmm              // OUT
) {

  if (verbosity >= NORMAL_VERBOSE) {
    fprintf(stderr, "Creating HMM from motif array.\n");
  }

  // Build the motif-based HMM.
  build_star_hmm(
    background,
    DEFAULT_SPACER_STATES,
    motif_array,
    num_motifs,
    false, // fim
    hmm
  );
  copy_string(&((*hmm)->motif_file), options->motif_filename);

}

/**************************************************************************
 * purge_mcast_match_heap
 *
 * This function purges half of the items in the heap in
 * order of increasing pvalue. It may purge more than half
 * of the items in order to make sure that all remaining items
 * have p-values less than the minimum pvalue of the matches discarded.
 *
 * It returns the minimum pvalue discarded.
 **************************************************************************/
static double purge_match_heap(HEAP *match_heap) {

  // How many matches do we need to delete?
fprintf(stderr, "Size of heap: %d\n", get_num_nodes(match_heap));
  int num_matches_to_delete = get_num_nodes(match_heap) / 2;
  if (verbosity >= NORMAL_VERBOSE) {
    fprintf(
      stderr,
      "%d matches stored. Need to delete at least %d matches.\n",
      get_num_nodes(match_heap),
      num_matches_to_delete
    );
  }

  // Delete the matches scoring in the bottom half
  double min_pvalue_discarded = 1.0;
  MCAST_MATCH_T *victim = NULL;
  int deletion_count = 0;
  for (deletion_count = 0; deletion_count < num_matches_to_delete; ++deletion_count) {
    victim = pop_heap_root(match_heap);
    min_pvalue_discarded = get_mcast_match_pvalue(victim);
    free_mcast_match(victim);
  }

  if (get_num_nodes(match_heap) > 0) {
    // Peek at lowest score in heap
    victim = (MCAST_MATCH_T *) get_node(match_heap, 1);
    double max_pvalue_retained = get_mcast_match_pvalue(victim);
    // Keep deleting matches until we find a match that 
    // scores better then the ones we've already deleted.
    while (max_pvalue_retained >= min_pvalue_discarded) {
      victim = pop_heap_root(match_heap);
      free_mcast_match(victim);
      if (get_num_nodes(match_heap) == 0) {
        // All the matches have been deleted!
        break;
      }
      victim = get_node(match_heap, 1);
      max_pvalue_retained = get_mcast_match_pvalue(victim);
    }
  }

  if (verbosity > NORMAL_VERBOSE) {
    fprintf(
      stderr,
      "%d matches deleted from storage. %d matches remaining.\n", 
      deletion_count,
      get_num_nodes(match_heap)
    );
  }

  return min_pvalue_discarded;
}

/**************************************************************************
 * calc_init_distr
 *
 * Calculate the initial fit of the scores to an exponential dist.
 * This will be called after the minimum number of matches have been 
 * computed, and will continue to be called until a complete set
 * of EVD has been created.
 *
 * Returns a flag indicating whether EVD distribution has been computed.
 **************************************************************************/
bool calc_init_distr(
    SCORE_SET* score_set,
    EVD_SET* evd_set,
    HEAP* mcast_match_heap,
    double dp_threshold
  ) {
  int i;
  bool got_init_evd = false;

  // Calculate the initial distribution from the scores in the score_set.
  *evd_set = calc_distr(
    *score_set,			// Set of scores
    D_EXP,			// Exponential score distribution
    false			// No effect with D_EXP
  );
  got_init_evd = (evd_set->n > 0);	// Successful?

  // Assign provisional p-values to all the matches in the heap.
  if (got_init_evd) {
    int num_matches = get_num_nodes(mcast_match_heap);
    MCAST_MATCH_T **mcast_matches = mm_malloc(num_matches * sizeof(MCAST_MATCH_T *));
    for (i = 0; i < num_matches; ++i) {
      mcast_matches[i] = pop_heap_root(mcast_match_heap);
      double score = get_mcast_match_score(mcast_matches[i]) - dp_threshold;
      double gc = get_mcast_match_gc(mcast_matches[i]);
      int gc_bin = evd_set_bin(gc, *evd_set);
      set_mcast_match_gc_bin(mcast_matches[i], gc_bin);
      double pvalue = evd_set_pvalue(score, gc, IGNORE_QUERY_LENGTH, *evd_set);
      set_mcast_match_pvalue(mcast_matches[i], pvalue);
    }
    // Put the matches back on the heap.
    for (i= 0; i < num_matches; ++i) {
      add_node_heap(mcast_match_heap, mcast_matches[i]);
    }
    myfree(mcast_matches);
  }

  return got_init_evd;
} // calc_init_distr

/**************************************************************************
 * mcast_read_and_score
 *
 * This function provides the outer wrapper for the dynamic programming 
 * algorithm at the core of MCAST algorithm. Modified from 
 * mhmmscan.c:read_and_score() for use in MCAST.
 *
 * Returns a double indicating the minimum p-value discarded
 **************************************************************************/
static double mcast_read_and_score(
  double *serial_no,			// for sorting scores
  HEAP *mcast_match_heap,		// Store for mcast matches
  SCORE_SET *score_set,			// Set of scores.
  EVD_SET *initial_evd_set,		// Initial EVD set.
  DATA_BLOCK_READER_T *fasta_reader,	// sequence source
  DATA_BLOCK_READER_T *psp_reader,	// priors source
  bool use_default_prior,		// use the default (median) prior if true
  MHMM_T* log_hmm,			// The HMM, with probs converted to logs.
  MHMMSCAN_OPTIONS_T *options,		// MHMMSCAN options
  double alpha,				// Alpha parmeter for calculation of log ratio priors
  int *num_seqs,			// Number of sequences read.
  mt_state *prng  			// pseudo-random number generator
) {
  int num_segments = 0;			// Number of sequence segments processed.
  int num_matches = 0;			// Number of matches found.
  int start_pos = 0;			// Search from here.
  double min_pvalue_discarded = 1.0;	// Threshold of scores to retain.
  bool got_init_evd = initial_evd_set->n > 0;	// Have initial distribution?

  // Allocate memory.
  // Note these are GLOBALS decared in mhmmscan.c however 
  // I have no idea why it was done this way...
  complete_match = allocate_match();
  partial_match = allocate_match();

  *num_seqs = 0;

  SEQ_T *sequence = get_next_seq_from_readers(
    fasta_reader,
    psp_reader,
    use_default_prior,
    options->max_chars
  );

  // Track length of sequence.
  if (sequence != NULL) {
    score_set->total_length += get_seq_length(sequence);
  }

  while (sequence != NULL) {

    bool is_complete_seq = is_complete(sequence);

    // Let the user know what's going on.
    if (verbosity > HIGHER_VERBOSE) {
      fprintf(
        stderr, 
        "Scoring %s (length=%u) at position %u.\n",
        get_seq_name(sequence), 
        get_seq_length(sequence),
        get_seq_offset(sequence)
      );
    }

    // Convert the sequence to alphabet-specific indices. 
    prepare_sequence(sequence, log_hmm->alph, options->hard_mask);

    // Compute the motif scoring matrix.
    MATRIX_T* motif_score_matrix = NULL;
    if (options->motif_scoring) {
      motif_score_matrix = allocate_matrix(
        log_hmm->num_motifs,
        get_seq_length(sequence)
      );
      compute_motif_score_matrix(
        options->use_pvalues,
        options->motif_pthresh,
        get_int_sequence(sequence),
        get_seq_length(sequence),
        get_seq_priors(sequence),
        alpha,
        log_hmm,
        &motif_score_matrix
      );
    }

    /* Allocate the dynamic programming matrix. Rows correspond to
       states in the model, columns to positions in the sequence. */
    if ( (dp_rows < log_hmm->num_states) 
      || (dp_cols < get_seq_length(sequence))
    ) {
      free_matrix(dp_matrix);
      free_matrix(trace_matrix);
      if (dp_rows < log_hmm->num_states) {
        dp_rows = log_hmm->num_states;
      }
      if (dp_cols < get_seq_length(sequence)) {
        dp_cols = get_seq_length(sequence);
      }
      // (Add one column for repeated match algorithm.)
      dp_matrix = allocate_matrix(dp_rows, dp_cols + 1);
      trace_matrix = allocate_matrix(dp_rows, dp_cols + 1);
    }

    // Fill in the DP matrix.
    repeated_match_algorithm(
      options->dp_thresh,
      get_int_sequence(sequence),
      get_seq_length(sequence),
      log_hmm,
      motif_score_matrix,
      dp_matrix,
      trace_matrix,
      complete_match
    );

    // Find all matches in the matrix.
    while (
      find_next_match(
        is_complete_seq,
        start_pos,
        dp_matrix, 
        log_hmm,
        complete_match,
        partial_match
      )
    ) {

      // If this match starts in the overlap region, put if off until
      // the next segment.
      if (!is_complete_seq && (get_start_match(partial_match) 
          > (get_seq_length(sequence) - OVERLAP_SIZE))
      ) {
        break;
      }

      // If this match starts at the beginning, then it's part of a
      // longer match from the previous matrix.  Skip it.  
      if (get_start_match(partial_match) == start_pos) {
        // Change the starting position so that next call to find_next_match
        // will start to right of last match.
        start_pos = get_end_match(partial_match) + 1;
        continue;
      }
      start_pos = get_end_match(partial_match) + 1;

      int length = get_match_seq_length(partial_match);
      double gc = 0.0;
      double viterbi_score = get_score(partial_match) - options->dp_thresh;
      int span = get_end_match(partial_match) - get_start_match(partial_match) + 1;
      int nhits = get_nhits(partial_match);
      char *seq_name = get_seq_name(sequence);
      size_t seq_length = get_seq_length(sequence);
      //
      // Save the score and sequence length. Keep track of maximum length
      // and smallest score.
      //
      if (viterbi_score > LOG_SMALL) {          /* don't save tiny scores */

        int score_index = 0;
        bool sample_score = false;
        ++score_set->num_scores_seen;

        if (score_set->n < score_set->max_scores_saved) {
          // The first samples go directly into the reservoir
          // until it is filled.
          sample_score = true;
          score_index = score_set->n;
          ++score_set->n;
        }
        else {
          // Now we're sampling
          score_index = score_set->num_scores_seen * mts_drand(prng);
          if (score_index < score_set->max_scores_saved) {
            sample_score = true;
          }
        }

        // Compute GC-content around match.
        const int GC_WIN_SIZE = 500;        // Size of GC window left and right of match.
        int start = MAX(0, get_start_match(partial_match)-GC_WIN_SIZE);
        int end = MIN(get_seq_length(sequence)-1, get_end_match(partial_match)+GC_WIN_SIZE);
        double n = end - start;
        gc = (get_seq_gc(end, sequence) - get_seq_gc(start, sequence)) / n;

        if (sample_score) {
          score_set->scores[score_index].s = viterbi_score;     /* unscaled score */
          score_set->scores[score_index].t = length;
          score_set->scores[score_index].nhits = nhits;
          score_set->scores[score_index].span = span;
          score_set->scores[score_index].gc = gc; 
          if (length > score_set->max_t) {
            score_set->max_t = length;
          }
          score_set->scores[score_index].serial_no = (*serial_no)++; 
        }
      }

      /* Calculate the initial p-value distribution once the
       * needed number of sequences has been saved.  This will allow the
       * descriptions of low-scoring sequences not to be stored.  The
       * distribution will be recomputed using all scores when all
       * sequences have been read.  */
      if (mcast_match_heap && score_set->n >= score_set->max_scores_saved && got_init_evd == false) {
        fputs("Initial distribution calculation\n", stderr);
        got_init_evd = calc_init_distr(
          score_set,
          initial_evd_set,
          mcast_match_heap,
          options->dp_thresh
        );
      }

      double pvalue = NAN;
      int gc_bin = -1;
      if (got_init_evd == true) {
        gc_bin = evd_set_bin(gc, *initial_evd_set);
        pvalue = evd_set_pvalue(viterbi_score, gc, 1, *initial_evd_set);
      }

      // Save match.
      if (mcast_match_heap && (pvalue < min_pvalue_discarded || isnan(pvalue))) {
        char* raw_seq = get_raw_sequence(sequence);
        long seq_offset =  get_seq_offset(sequence);
        MCAST_MATCH_T *mcast_match = allocate_mcast_match();

        // Find all the motif hits in the match
        int i_match = 0;
        int start_match = get_start_match(partial_match);
        int end_match = get_end_match(partial_match);
        for (i_match = start_match; i_match < end_match; i_match++) {

          int i_state = get_trace_item(i_match, partial_match);
          MHMM_STATE_T* this_state = &((log_hmm->states)[i_state]);

          // Are we at the start of a motif?
          if (this_state->type == START_MOTIF_STATE) {
            char *motif_id = get_state_motif_id(false, this_state);
            int start = seq_offset + i_match - 1; // subtract 1 to account for the X added at the front of the sequence
            int stop = start + this_state->w_motif - 1;
            char strand = get_strand(this_state);
            double s = get_matrix_cell(this_state->i_motif, i_match, motif_score_matrix);
            double pvalue = pow(2.0, -s) * options->motif_pthresh;
            char* hit_seq = mm_malloc((this_state->w_motif + 1) * sizeof(char));
            strncpy(hit_seq, raw_seq + i_match, this_state->w_motif);
            hit_seq[this_state->w_motif] = 0;
            int motif_index = this_state->i_motif / 2 + 1;
            MOTIF_HIT_T *motif_hit = allocate_motif_hit(
              motif_id, 
              motif_index,
              hit_seq, 
              strand, 
              start, 
              stop, 
              pvalue
            );
            myfree(hit_seq);
            add_mcast_match_motif_hit(mcast_match, motif_hit);
          }
        }

        // Extract the matched sub-sequence from the full sequence.
        const int preferred_flank_size = 10;
        int match_length = end_match - start_match + 1;
        char* match_seq = mm_malloc((match_length + 1) * sizeof(char));
        strncpy(match_seq, raw_seq + start_match, match_length);
        match_seq[match_length] = '\0';
        // adjust the length to avoid the X at the start
        int lflank_length = ((start_match - 1) >= preferred_flank_size ? preferred_flank_size : (start_match - 1));
        char* lflank_seq = mm_malloc((lflank_length + 1) * sizeof(char));
        strncpy(lflank_seq, raw_seq + (start_match - lflank_length), lflank_length);
        lflank_seq[lflank_length] = '\0';
        // adjust the length to avoid the X at the end
        int rflank_length = ((seq_length - end_match - 2) >= preferred_flank_size ? preferred_flank_size : (seq_length - end_match - 2));
        char* rflank_seq = mm_malloc((rflank_length + 1) * sizeof(char));
        strncpy(rflank_seq, raw_seq + (end_match + 1), rflank_length); 
        rflank_seq[rflank_length] = '\0';
        // Build the mcast match object
        set_mcast_match_seq_name(mcast_match, seq_name);
        set_mcast_match_seq_length(mcast_match, seq_length - 2); // subtract 2 to account for the Xs added at the ends of the sequence
        set_mcast_match_seq_start(mcast_match, seq_offset);
        set_mcast_match_sequence(mcast_match, match_seq);
        set_mcast_match_lflank(mcast_match, lflank_seq);
        set_mcast_match_rflank(mcast_match, rflank_seq);
        // Add the minimum score back into the viterbi score
        set_mcast_match_score(mcast_match, viterbi_score + options->dp_thresh);
        set_mcast_match_pvalue(mcast_match, pvalue);
        set_mcast_match_gc(mcast_match, gc);
        set_mcast_match_gc_bin(mcast_match, gc_bin);
        set_mcast_match_start(mcast_match, seq_offset + start_match - 1); // subtract 1 to account for the X added at the front of the sequence
        set_mcast_match_stop(mcast_match, seq_offset + end_match - 1); // subtract 1 to account for the X added at the front of the sequence
        add_node_heap(mcast_match_heap, mcast_match);
        myfree(match_seq);
        myfree(lflank_seq);
        myfree(rflank_seq);

        int num_nodes = get_num_nodes(mcast_match_heap);
        int max_nodes = get_max_size(mcast_match_heap);
        if (num_nodes == max_nodes) {
          fprintf(
            stderr,
            "Purging matches. score_set->n = %d score_set->max_scores_saved = %d num_nodes %d max_nodes %d\n",
            score_set->n, score_set->max_scores_saved, num_nodes, max_nodes
          );
          min_pvalue_discarded = purge_match_heap(mcast_match_heap);
          fprintf(stderr, "Smallest p-value discarded is %0.3g\n", min_pvalue_discarded);
        }

        num_matches++;
        user_update(
          num_matches, 
          *num_seqs, 
          num_segments, 
          num_matches, 
          get_num_nodes(mcast_match_heap),
          options->progress_every
        );
      } // save match
    } // find all matches

    // Does the input file contain more of this sequence?
    if (!is_complete_seq) {
      int size_to_remove;

      // Adjust the sequence accordingly.
      // remove_flanking_xs(sequence);
      remove_flanking_xs(sequence);

      // Compute the width of the buffer.
      size_to_remove = get_seq_length(sequence) - OVERLAP_SIZE;
      shift_sequence(size_to_remove, sequence);
      if (SHIFT_DEBUG) {
        fprintf(stderr, "Retained %d bases.\n", get_seq_length(sequence));
      }

      // Next time, start looking for a match after the buffer.
      start_pos -= size_to_remove;
      if (start_pos < 0) {
        start_pos = 0;
      }
      read_one_fasta_segment_from_reader(
        fasta_reader,
        options->max_chars, 
        OVERLAP_SIZE,
        sequence
      );
      score_set->total_length += (get_seq_length(sequence) - OVERLAP_SIZE); 
      if (psp_reader) {
	read_one_priors_segment_from_reader(
	  psp_reader,
	  use_default_prior,			// use the default prior if true
	  options->max_chars, 
	  OVERLAP_SIZE,
	  sequence
	);
      }
    } else {
      free_seq(sequence);
      sequence = get_next_seq_from_readers(fasta_reader, psp_reader, use_default_prior, options->max_chars);
      if (sequence != NULL) {
        score_set->total_length += get_seq_length(sequence); 
      }
      start_pos = 0;
      *num_seqs += 1;
    }

    free_matrix(motif_score_matrix);
    num_segments++;
    user_update(
      num_segments, 
      *num_seqs, 
      num_segments, 
      num_matches,
      mcast_match_heap ? get_num_nodes(mcast_match_heap) : 0,
      options->progress_every
    );
  }

  free_matrix(dp_matrix);
  dp_matrix = NULL;
  dp_rows = 0;
  dp_cols = 0;
  free_matrix(trace_matrix);
  trace_matrix = NULL;
  free_match(complete_match);
  free_match(partial_match);

  return min_pvalue_discarded;
} // mcast_read_and_score

/*************************************************************************
* Calculate the p-, E- and q-values of sequence scores and store them in the
* matches.
*************************************************************************/
void calc_pq_values (
  int num_matches,   
  MCAST_MATCH_T **matches,	// Sorted array storing retained matches
  EVD_SET *evd_set,		// EVD parameters.
  SCORE_SET *score_set,		// Score collection
  double dp_thresh,		// Mininum allowed score
  int n				// Number of sequences or matches.
)    
{
  int i;
  double gc;

  if (evd_set->n <= 0) return;                  // no EVD available 

  // Get min(E-value) and sum of log(E).
  evd_set->outliers = 0;                        // Number with E < 1.
  evd_set->min_e = BIG;                         // Smallest E-value.
  evd_set->sum_log_e = 0;                       // Sum of log(E < 1).

  // Calculate p-values for the sampled scores.
  // This array does not come to us sorted.
  ARRAY_T *sampled_pvalues = allocate_array(score_set->n);
  for (i = 0; i < score_set->n; ++i) {
    double score = score_set->scores[i].s;
    gc = score_set->scores[i].gc;
    double pvalue = evd_set_pvalue(score, gc, IGNORE_QUERY_LENGTH, *evd_set);
    set_array_item(i, pvalue, sampled_pvalues);
  }
  sort_array(false, sampled_pvalues);

  // Calculate p-values for the stored scores.
  for (i = 0; i < num_matches; ++i) {
    if (matches[i]) {
      // We fit the score distribution using (score - dp_thresh)
      // but the scores reported in the match are not adusted,
      // so when evaluating p-values and E-values we have
      // subtract the dp_thresh (minimum allowed score).
      double score = get_mcast_match_score(matches[i]) - dp_thresh;
      double gc = get_mcast_match_gc(matches[i]);
      int gc_bin = evd_set_bin(gc, *evd_set);
      set_mcast_match_gc_bin(matches[i], gc_bin);
      double pvalue = evd_set_pvalue(score, gc, IGNORE_QUERY_LENGTH, *evd_set);
      set_mcast_match_pvalue(matches[i], pvalue);
      set_mcast_match_evalue(matches[i], n * pvalue);
    }
  }

  // The match pvalues may have changed, so we need to resort them
  qsort(matches, num_matches, sizeof(MCAST_MATCH_T*), compare_mcast_match_pvalues);

  // Create a simple array of pvalues in the same order as the matches.
  ARRAY_T *pvalues = allocate_array(num_matches);
  for (i = 0; i < num_matches; ++i) {
    if (matches[i]) {
      double pvalue = get_mcast_match_pvalue(matches[i]);
      set_array_item(i, pvalue, pvalues);
    }
  }

  // Calculate q-values.
  compute_qvalues(
    false, // Don't stop with FDR
    true, // Try to esimate pi0
    NULL, // Don't store pi-zero in a file.
    NUM_BOOTSTRAPS,
    NUM_BOOTSTRAP_SAMPLES,
    NUM_LAMBDA,
    MAX_LAMBDA,
    score_set->num_scores_seen,
    pvalues,
    sampled_pvalues
  );

  // The pvalues array now contains the qvalues
  // Transfer them to the matches.
  for (i = 0; i < num_matches; ++i) {
    if (matches[i]) {
      double qvalue = get_array_item(i, pvalues);
      set_mcast_match_qvalue(matches[i], qvalue);
    }
  }

  free_array(sampled_pvalues);
  free_array(pvalues);

} // calc_pq_values

/******************************************************************************
 * get_min_max_pvalue
 *
 * This function scans the pvalues for all the matches
 * and finds the minimum of the maximum p-value for each GC bin
******************************************************************************/
double get_min_max_pvalue(
    EVD_SET evd_set,
    int num_matches,
    MCAST_MATCH_T** mcast_matches
) {

  // Create an array of max pvalues (one for each GC bin)
  int num_gc_bins = evd_set.n;
  double* max_pvalues = mm_malloc(num_gc_bins * sizeof(double));
  int i;
  for (i = 0; i < num_gc_bins; ++i) {
    max_pvalues[i] = 0.0;
  }

  // Find the maximum p-value for each bin.
  for (i = 0; i < num_matches; ++i) {
    int gc_bin = get_mcast_match_gc_bin(mcast_matches[i]);
    double pvalue = get_mcast_match_pvalue(mcast_matches[i]);
    max_pvalues[gc_bin] = MAX(pvalue, max_pvalues[gc_bin]);
  }

  // Find the minimum of the maximum p-values.
  double min_max_pvalue = 1.0;
  for (i = 0; i < num_gc_bins; ++i) {
    min_max_pvalue = MIN(max_pvalues[i], min_max_pvalue);
  }

  return min_max_pvalue;
}

/******************************************************************************
 * mcast_print_results
 *
 * This function writes out the MCAST results as XML, text, gff, and HTML.
******************************************************************************/
static void mcast_print_results(
  int argc,
  char **argv,
  time_t *start,
  SCORE_SET *score_set, 
  EVD_SET evd_set,
  int num_matches,
  MCAST_MATCH_T **mcast_matches,
  MHMM_T *hmm, 
  int num_motifs, 
  MOTIF_T *motifs,
  int num_seqs,
  double duration,
  MCAST_OPTIONS_T *mcast_options,
  MHMMSCAN_OPTIONS_T *options 
) {

  bool stats_available = evd_set.n > 0 ? true : false;

  if (!options->text_only) {
    // Create output directory
    if (create_output_directory(
         options->output_dirname,
         options->allow_clobber,
         false /* Don't print warning messages */
        )
      ) {
      // Failed to create output directory.
      die("Couldn't create output directory %s.\n", options->output_dirname);
    }
  }

  mcast_print_results_as_text(stats_available, num_matches, mcast_matches, options);
  if (options->text_only) {
    return;
  }

  // Output BED/GFF
  mcast_print_results_as_gff(stats_available, num_matches, mcast_matches, options);

  // Output HTML
  mcast_print_results_as_html(
    argc,
    argv,
    start,
    duration,
    hmm->background,
    mcast_options->psp_filename,
    mcast_options->prior_distribution_filename,
    num_motifs, 
    motifs, 
    num_matches,
    mcast_matches, 
    num_seqs,
    (long) score_set->total_length,
    mcast_options->max_stored_scores,
    mcast_options->motif_pthresh,
    mcast_options->alpha,
    mcast_options->seed,
    mcast_options->parse_genomic_coord,
    stats_available,
    options
  );

  // Output the  MHMMSCAN XML file for MCAST
  print_mhmmscan_xml_file(
    options,
    score_set,
    evd_set,
    hmm->alph,
    num_motifs,
    motifs,
    hmm->background,
    num_seqs,
    score_set->total_length
  );

  // Output CisML XML
  mcast_print_results_as_cisml(
    stats_available,
    num_matches,
    mcast_matches,
    options
  );

} // mcast_print_results

/**************************************************************************
* Generate random sequences and score them and compute the distribution.
*
* Generates sequences until enough matches are found
* so that the standard error of mu1 will be 3% (std err = 100 * 1/sqrt(n))
* in each of 100 bins or the maximum database size is reached.
***************************************************************************/
EVD_SET mcast_generate_synth_seq(
  SCORE_SET *score_set, 		// Set of scores.
  DATA_BLOCK_READER_T *psp_reader,	// psp_reader for default prior
  MHMM_T *log_hmm,
  EVD_SET evd_set,
  MCAST_OPTIONS_T *mcast_options,
  MHMMSCAN_OPTIONS_T *scan_options, 	// MHMMSCAN options
  mt_state *prng  			// pseudo-random number generator
) {

  DATA_BLOCK_READER_T *synth_fasta_reader;
  SCORE_SET *synth_score_set = NULL;
  int i;
  double want = 1e5;		// Desired number of matches (for mu1 std err= 3%).
  int seqlen = 1e6;		// Length of each random sequence.
  double maxbp = 1e9;		// Maximum number of bp to generate.
  double db_size = 0;		// Number of bp generated. 
  int found = 0;		// Matches found.
  double min_gc, max_gc;	// Min and Max observed GC-contents.
  ARRAY_T *background_for_gc;	// 0-order Markov model
  EVD_SET synth_evd_set;	// EVD set.
  synth_evd_set.n = 0;		// Flag as empty.
  synth_evd_set.evds = NULL;	// Flag as empty.

  // Get the minimum and maximum GC-contents of match regions.
  min_gc = 1;
  max_gc = 0;
  for (i=0; i<score_set->n; i++) {
    double gc = score_set->scores[i].gc;
    if (gc < min_gc) min_gc = gc;
    if (gc > max_gc) max_gc = gc;
  }

  if (verbosity >= NORMAL_VERBOSE) {
    fprintf(stderr, "Generating and scoring random sequences...\n");
  }

  // Local variables. 
  ALPH_T*   alph = log_hmm->alph; // Alphabet
  int       num_seqs;    // Number of sequences processed. 
  int idx_A, idx_T, idx_G, idx_C; // indexes of complement pairs

  if (alph_size_core(alph) != 4 || alph_size_pairs(alph) != 2) {
    die("Unable to generate random sequences for %s because it requires an "
        "alphabet with 4 symbols made up of 2 complementary pairs.",
        alph_name(alph));
  }
  idx_A = 0;
  idx_T = alph_complement(alph, idx_A);
  idx_C = (idx_T != 1 ? 1 : 2);
  idx_G = alph_complement(alph, idx_C);
  background_for_gc = get_uniform_frequencies(alph, NULL);

  // Create filename for recording random sequences
  char *synth_seq_filename = make_path_to_file(mcast_options->output_dirname, "synth-seq.fa");
  FILE *synth_seq_file = NULL;

  // Set up for computing score distribution.
  synth_score_set = set_up_score_set(
    scan_options->motif_pthresh, 
    scan_options->dp_thresh, 
    scan_options->max_gap, 
    true, 			// Negative examples only
    log_hmm
  );
  // Set up storage for unscaled score and sequence length for calculating EVD.
  mm_resize(synth_score_set->scores, mcast_options->max_stored_scores, SCORE);
  synth_score_set->max_scores_saved = mcast_options->max_stored_scores;

  // Loop until enough matches found or we get tired.
  // Always try at least 100 values of GC content.
  int round = 1;
  double min_rounds = 100;
  double max_rounds = maxbp/seqlen;
  double serial_no = 0;
  while (round <= max_rounds) {

    // Create file for recording random sequences.
    errno = 0;
    synth_seq_file = fopen(synth_seq_filename, "w");
    if (!synth_seq_file) {
      die("Unable to create file for random sequences: %s", strerror(errno));
    }

    // Generate random sequences.
    // Select a GC content randomly and set background_for_gc.
    // Note that we are assuming that there are two complementary pairs
    // in this alphabet (or we should not be in this function!).
    double gc = min_gc + (mts_drand(prng) * (max_gc-min_gc));
    set_array_item(idx_A, (1 - gc)/2, background_for_gc);
    set_array_item(idx_T, (1 - gc)/2, background_for_gc);
    set_array_item(idx_C, gc/2, background_for_gc);
    set_array_item(idx_G, gc/2, background_for_gc);

    (void) gendb(
      synth_seq_file,		// output
      prng,			// pseudo random number generator
      alph,			// alphabet
      background_for_gc,	// background with gc content
      0.0,			// no ambiguity symbols
      1,			// create 1 sequence
      seqlen,			// min length
      seqlen			// max length
    );
    fclose(synth_seq_file);
    db_size += seqlen;		// Size of db so far.

    //
    // Read and score the random sequence.
    //
    DATA_BLOCK_READER_T *synth_fasta_reader = new_seq_reader_from_fasta(
      false, 			// no genomic coord
      alph,
      synth_seq_filename
    );
    unlink(synth_seq_filename);	// Delete the random sequence file.
    double min_pvalue_discarded = mcast_read_and_score(
      &serial_no,
      NULL,			// no heap needed for matches
      synth_score_set,
      &synth_evd_set,
      synth_fasta_reader,
      psp_reader,
      true,			// use default prior
      log_hmm,
      scan_options,
      mcast_options->alpha,
      &num_seqs,
      prng  			// pseudo-random number generator
    );
    close_seq_reader_from_fasta(synth_fasta_reader);

    // Show progress.
    found = synth_score_set->num_scores_seen;
    if (verbosity >= NORMAL_VERBOSE) {
      fprintf(
        stderr, 
        "Sequence %d total matches found %d progress %g%% min_progress %g%%.\n", 
          round, found, 100*found/want, 100*round/max_rounds
      );
    }

    // Quit if we have found the number of wanted matches and
    // have done a minimum number of random sequences.
    if (round >= min_rounds && found >= want) break;

    // Quit if we're not getting there.
    if (round >= 10 && found/want < round/max_rounds)
    {
      fprintf(
        stderr, 
        "\nGiving up generating random sequences: match probability too low!\n"
        "Try increasing the value of --motif-pthresh.\n\n"
      );
      break;
    }

    ++round;
  } // Generate random scores.

  if (verbosity >= NORMAL_VERBOSE) {
    fprintf(
      stderr, 
      "Generated random sequence (%g characters) with %d matches.\n",
      db_size, 
      found
    );
  }

  // Get the GC-binned distribution using the random sequence scores.
  synth_evd_set = calc_distr(
    *synth_score_set,		// Set of scores
    D_EXP,			// Exponential score distribution
    false			// No effect with D_EXP
  );

  // Free stuff.
  myfree(synth_seq_filename);
  myfree(synth_score_set->scores);
  myfree(synth_score_set);

  return synth_evd_set;
} // mcast_generate_synth_seq

/******************************************************************************
 * mcast
 *
 * This function is based on mhmmscan.c:mhmmscan(), but has been modifed to
 * use the CISML schema for writing the results as XML.
 * CONSIDER merging code back when we update beadstring.
 *
******************************************************************************/
static void mcast(
  int argc, 
  char* argv[], 
  MCAST_OPTIONS_T *mcast_options, 
  ALPH_T *alph,
  MHMM_T *hmm, 
  int num_motifs,
  MOTIF_T *motifs,
  DATA_BLOCK_READER_T *fasta_reader,
  DATA_BLOCK_READER_T *psp_reader,
  PRIOR_DIST_T *prior_dist,
  ARRAY_T *background
) {
  time_t start;
  mt_state prng;
  MHMM_T*   log_hmm;			// The HMM, with probs converted to logs. 
  EVD_SET   evd_set;			// EVD data structure 
  evd_set.n = 0;			// Flag as empty.
  evd_set.evds = NULL;			// Flag as empty.
  SCORE_SET *score_set = NULL;		// Set of scores for computing distribution.
  int num_seqs;				// Number of sequences processed. 

  // Set the mhmmscan options from the mcast options
  MHMMSCAN_OPTIONS_T scan_options;
  start = time(NULL);
  build_scan_options_from_mcast_options(argc, argv, mcast_options, alph, &scan_options);
  mts_seed32new(&prng, mcast_options->seed);

  if (!mcast_options->text_only) {
    // Create output directory
    if (create_output_directory(
         mcast_options->output_dirname,
         mcast_options->allow_clobber,
         false /* Don't print warning messages */
        )
      ) {
      // Failed to create output directory.
      die("Couldn't create output directory %s.\n", mcast_options->output_dirname);
    }
  }

  // Start system and user time clocks. 
  double total_user_time = 0.0;
  double start_user_time = myclock();
  double total_sys_time = 0.0;
  double start_sys_time = mysysclock();

  //
  // Update options with info from the HMM.
  //
  if (scan_options.max_gap_set) {

    scan_options.dp_thresh = 1e-6;  // Very small number.

    // 
    // If using egcost, we must get model statistics
    // in order to set dp_thresh.
    //
    if (scan_options.egcost > 0.0) {    // Gap cost a fraction of expected hit score.
      score_set = set_up_score_set(
        scan_options.motif_pthresh, 
        scan_options.dp_thresh, 
        scan_options.max_gap, 
        false,
        hmm
      );
      //scan_options.dp_thresh = 
      scan_options.dp_thresh = (score_set->egap == 0) ? 1e17 :
	(scan_options.egcost * scan_options.max_gap * score_set->e_hit_score) / score_set->egap;
      // This score set object is not used any further
      myfree(score_set->scores);
      myfree(score_set);
    } 

    //
    // Set gap costs.
    //
    scan_options.gap_extend = scan_options.dp_thresh/scan_options.max_gap;
    scan_options.gap_open = scan_options.gap_extend;
    scan_options.zero_spacer_emit_lo = true;
  }

  if (scan_options.pam_distance == -1) {
    scan_options.pam_distance 
      = (alph_is_builtin_protein(hmm->alph) ? DEFAULT_PROTEIN_PAM : DEFAULT_DNA_PAM);
  }
  if (!scan_options.beta_set)  {
    scan_options.beta 
      = (alph_is_builtin_protein(hmm->alph) ? DEFAULT_PROTEIN_BETA : DEFAULT_DNA_BETA);
  }

  free_array(hmm->background);
  //hmm->background = get_background(hmm->alph, scan_options.bg_filename);
  hmm->background = background;			// TLB 13-Feb-2017
  log_hmm = allocate_mhmm(hmm->alph, hmm->num_states);
  convert_to_from_log_hmm(
    true, // Convert to logs.
    scan_options.zero_spacer_emit_lo,
    scan_options.gap_open,
    scan_options.gap_extend,
    hmm->background,
    scan_options.sc_filename,
    scan_options.pam_distance,
    scan_options.beta,
    hmm, 
    log_hmm
  );

  // Set up PSSM matrices if doing motif_scoring
  // and pre-compute motif p-values if using p-values.
  // Set up the hot_states list.
  set_up_pssms_and_pvalues(
    scan_options.motif_scoring,
    scan_options.motif_pthresh,
    scan_options.both_strands,
    scan_options.allow_weak_motifs,
    log_hmm,
    prior_dist,
    mcast_options->alpha
  );

  // Set thow many characters to read in a block.
  scan_options.max_chars = (int) (MAX_MATRIX_SIZE / log_hmm->num_states);
  if (verbosity >= NORMAL_VERBOSE) {
    fprintf(
      stderr, 
      "Reading sequences in blocks of %d characters.\n", 
      scan_options.max_chars
    );
  }

  // Set up for computing score distribution.
  score_set = set_up_score_set(
    scan_options.motif_pthresh, 
    scan_options.dp_thresh, 
    scan_options.max_gap, 
    false, 			// Positives and negatives
    log_hmm
  );

  // Set up storage for unscaled score and sequence length for calculating EVD.
  mm_resize(score_set->scores, mcast_options->max_stored_scores, SCORE);
  score_set->max_scores_saved = mcast_options->max_stored_scores;

  // Create heap for storing matches we will report.
  HEAP *mcast_match_heap = create_heap(
    mcast_options->max_stored_scores,
    compare_mcast_matches,
    copy_mcast_match,
    free_mcast_match,
    NULL,
    print_mcast_match
  );

  //
  // Read and score the real sequences using the MCAST algorithm.
  //
  double serial_no = 0;
  double min_pvalue_discarded = mcast_read_and_score(
    &serial_no,
    mcast_match_heap,
    score_set,
    &evd_set,
    fasta_reader,
    psp_reader,
    false,			// don't use default prior
    log_hmm,
    &scan_options,
    mcast_options->alpha,
    &num_seqs,
    &prng  			// pseudo-random number generator
  );

  // Convert heap into an array of mcast matches, 
  int num_matches = get_num_nodes(mcast_match_heap);
  MCAST_MATCH_T **mcast_matches = mm_malloc(num_matches * sizeof(MCAST_MATCH_T *));
  int i;
  for (i = 0; i < num_matches; ++i) {
    mcast_matches[i] = pop_heap_root(mcast_match_heap);
  }
  destroy_heap(mcast_match_heap);

  // If there were any matches, compute their p-, E- and q-values.
  if (num_matches > 0) {
    evd_set = mcast_generate_synth_seq(
      score_set,
      psp_reader,
      log_hmm,
      evd_set,
      mcast_options,
      &scan_options,
      &prng
    );
    if (evd_set.n > 0) {
      // p-value multiplier for E-value.
      evd_set.N = score_set->num_scores_seen;
      // Get the p-, E- and q-values.
      calc_pq_values(
	num_matches, 
	mcast_matches, 
	&evd_set, 
	score_set, 
	scan_options.dp_thresh,
	evd_set.N 
      );
      if (min_pvalue_discarded < scan_options.p_thresh) {
	scan_options.p_thresh = min_pvalue_discarded;
      }
      if (scan_options.p_thresh < 1.0) {
	fprintf(stderr, "Smallest p-value discarded: %.3g\n", scan_options.p_thresh);
      }
    }
  } // matches found

  double end_user_time = myclock();
  double duration = (end_user_time - start_user_time) / 1E6;
  total_user_time += duration;
  fprintf(stderr, "User time for computation: %g seconds\n", duration);
  start_user_time = end_user_time;
  double end_sys_time = mysysclock();
  duration = (end_sys_time - start_sys_time) / 1E6;
  total_sys_time += duration;
  fprintf(stderr, "System time for computation: %g seconds\n", duration);
  start_sys_time = end_sys_time;

  mcast_print_results(
    argc,
    argv,
    &start,
    score_set, 
    evd_set,
    num_matches,
    mcast_matches, 
    hmm, 
    num_motifs, 
    motifs, 
    num_seqs,
    total_sys_time + total_user_time,
    mcast_options,
    &scan_options
  );

  // Print timing information
  end_user_time = myclock();
  duration = (end_user_time - start_user_time) / 1E6;
  total_user_time += duration;
  fprintf(stderr, "User time for output: %g seconds\n", duration);
  start_user_time = end_user_time;
  end_sys_time = mysysclock();
  duration = (end_sys_time - start_sys_time) / 1E6;
  total_sys_time += duration;
  fprintf(stderr, "System time for output: %g seconds\n", duration);
  start_sys_time = end_sys_time;
  fprintf(stderr, "Total user time: %g seconds\n", total_user_time);
  fprintf(stderr, "Total system time: %g seconds\n", total_sys_time);

  // Tie up loose ends.
  
  for (i = 0; i < num_matches; ++i) {
    free_mcast_match(mcast_matches[i]);
  }
  myfree(mcast_matches);
  myfree(score_set->scores);
  myfree(score_set);
  myfree(evd_set.evds);
  free_mhmm(log_hmm);
  cleanup_mhmmscan_options(&scan_options);
} // mcast


/***********************************************************************
 * main
 *
 * Entry point for the MCAST program.
 ***********************************************************************/
int main(int argc, char* argv[]) {

  // Fill in the MCAST options from the command line.
  MCAST_OPTIONS_T options;
  process_command_line(argc, argv, &options);

  // Read the motifs from the file.
  ALPH_T *alph;
  ARRAY_T *background;
  int num_motifs = 0;
  MOTIF_T *motifs = NULL;
  MHMM_T *hmm = NULL;
  read_motifs(&options, &background, &num_motifs, &motifs, &alph);

  // Build the HMM from the motifs.
  build_hmm_from_motifs(&options, background, num_motifs, motifs, &hmm);

  // Set up sequence input
  DATA_BLOCK_READER_T *fasta_reader = new_seq_reader_from_fasta(
    options.parse_genomic_coord,
    alph,
    options.seq_filename
  );

  // Set up priors input
  DATA_BLOCK_READER_T *psp_reader = NULL;
  PRIOR_DIST_T *prior_dist = NULL;
  if (options.psp_filename && options.prior_distribution_filename) {
    prior_dist = new_prior_dist(options.prior_distribution_filename);
    double default_prior = get_prior_dist_median(prior_dist);
    // If suffix for file is '.wig' assume it's a wiggle file
    size_t len = strlen(options.psp_filename);
    if (strcmp(options.psp_filename + len - 4, ".wig") == 0) {
      psp_reader = new_prior_reader_from_wig(options.psp_filename, default_prior);
    }
    else {
      psp_reader = new_prior_reader_from_psp(options.parse_genomic_coord, options.psp_filename, default_prior);
    }
  }

  // Read and score the sequences.
  mcast(
    argc, 
    argv, 
    &options, 
    alph,
    hmm, 
    num_motifs, 
    motifs, 
    fasta_reader, 
    psp_reader, 
    prior_dist,
    background
  );

  // Cleanup

  free_motif_array(motifs, num_motifs);
  //free_array(background); // Gets freed in free_mhmm
  free_mhmm(hmm);
  fasta_reader->close(fasta_reader);
  free_data_block_reader(fasta_reader);
  if (psp_reader) {
    psp_reader->close(psp_reader);
    free_data_block_reader(psp_reader);
  }

  if (prior_dist != NULL) {
    free_prior_dist(prior_dist);
  }

  return 0;

}
