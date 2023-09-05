##
## Process this file with automake to produce Makefile.in
##
#####################################################################
## Note:
##
## To run comprehensive tests, use:
##	make check TFLAGS='--comprehensive'
##
## To run quicker tests, use:
##	make check
##
#####################################################################

AUTOMAKE_OPTIONS = no-dependencies

all: $(BUILT_TEST_FILES) test_driver

test_driver: test_driver.pl.in
	$(SED) -e 's%@WHICHPERL@%$(PERL)%' \
	       -e 's%@MYDISTDIR@%$(abs_top_srcdir)%' \
	       -e 's%@BUILDDIR@%$(abs_top_builddir)%' \
	       -e 's%@TESTDIR@%$(abs_top_builddir)%' $< > $@
	chmod +x $@

if HAVE_PYTHON_3
  python_type = 3
else
  python_type = 2
endif

fasta-dinucleotide-shuffle.test: fasta-dinucleotide-shuffle.test.in
	$(SED) -e 's%@PYTHON_TYPE@%$(python_type)%' $< > $@
	chmod +x $@

#SEDSPEC = \
#  -e 's%@DIR@%$($abs_top_src_dir/tests/)%' 

TEST_FILES = bed2fasta.test motif-in.test ama.test ame.test centrimo.test tgene.test \
  create_priors.test dreme.test fasta-center.test \
  fimo.test glam2.test \
  glam2scan.test gomo.test mast.test \
  mcast.test meme.test meme-chip.test momo.test \
  motiph.test pspgen.test qvalue.test sea.test spamo.test streme.test \
  tomtom.test xstreme.test

BUILT_TEST_FILES = fasta-dinucleotide-shuffle.test

# tests for programs that are not built by default
OBSOLETE_TEST_FILES = clustalw2fasta.test fasta-io.test mhmm_core.test \
  mhmm-io.test mhmms.test mhmmscan.test shadow.test 

# Broken tests
XFAIL_TESTS = 
 
check_SCRIPTS = test_driver 

TEST_LOG_DRIVER = $(PERL) -I $(abs_top_srcdir)/scripts $(top_builddir)/tests/scripts/test_driver $(TFLAGS)

TESTS = $(TEST_FILES) $(BUILT_TEST_FILES)
EXTRA_DIST = $(TEST_FILES) $(OBSOLETE_TEST_FILES) \
  test_driver.pl.in fasta-dinucleotide-shuffle.test.in

CLEANFILES = test_driver $(BUILT_TEST_FILES) 
