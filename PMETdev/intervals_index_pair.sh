#!/bin/bash
set -e

# disable warnings
set -o errexit
set -o pipefail

# 22.1.18 Charlotte Rich
# last edit: 7.2.18 - removed the make 1 big fimohits files

# cl_index_wrapper.sh
# mac -> server Version differences
# ggrep = grep

# Called when user selects 'Genomic Intervals'
# Input files are genomic intevals fasta file, meme file location, gene clusters file
# Other inputs N and k

function usage () {
    cat >&2 <<EOF
        USAGE: PMETindexgenome [options] <genome> <gff3> <memefile>

        Creates PMET index for Paired Motif Enrichment Test using genome files.
        Required arguments:
        -r <index_dir>	: Full path of python scripts called from this file. Required.
        -i <gff3_identifier> : gene identifier in gff3 file e.g. gene_id=

        Optional arguments:
        -o <output_directory> : Output directory for results.
        -n <topn>	: How many top promoter hits to take per motif. Default=5000
        -k <max_k>	: Maximum motif hits allowed within each promoter.  Default: 5
        -f <fimo_threshold> : Specify a minimum quality for hits matched by fimo. Default: 0.05
        -t <threads>: Number of threads. Default: 4
EOF
}

function error_exit() {
    echo "ERROR: $1" >&2
    usage
    exit 1
}

# set up arguments
topn=5000
maxk=5
fimothresh=0.05
pmetroot="scripts"
threads=4
icthreshold=24

indexingOutputDir=
pairingOutputDir=
genomefile=
memefile=

# check if arguments have been specified
if [ $# -eq 0 ]
then
    echo "No arguments supplied"  >&2
    usage
    exit 1
fi

# bring in arguments
while getopts ":r:o:k:n:f:t:x:g:c:e:l:" options; do
    case $options in
        r) echo "Full path of PMET_index:  $OPTARG" >&2
        pmetroot=$OPTARG;;
        o) echo "Output directory for results: $OPTARG" >&2
        indexingOutputDir=$OPTARG;;
        n) echo "Top n promoter hits to take per motif: $OPTARG" >&2
        topn=$OPTARG;;
        k) echo "Top k motif hits within each promoter: $OPTARG" >&2
        maxk=$OPTARG;;
        f) echo "Fimo threshold: $OPTARG" >&2
        fimothresh=$OPTARG;;
        t) echo "Number of threads: $OPTARG" >&2
        threads=$OPTARG;;
        x) echo "Output directory for PMET results: $OPTARG" >&2
        pairingOutputDir=$OPTARG;;
        g) echo "gene: $OPTARG" >&2
        genefile=$OPTARG;;
        c) echo "IC threshold: $OPTARG" >&2
        icthreshold=$OPTARG;;
        e) echo "Output directory for results: $OPTARG" >&2
        email=$OPTARG;;
        l) echo "Output directory for results: $OPTARG" >&2
        resultlink=$OPTARG;;
        \?) echo "Invalid option: -$OPTARG" >&2
        exit 1;;
        :)  echo "Option -$OPTARG requires an argument." >&2
        exit 1;;
    esac
done

# rename input file variable
shift $((OPTIND - 1))
genomefile=$1
memefile=$2

[ ! -d $indexingOutputDir ] && mkdir $indexingOutputDir
# cd $indexingOutputDir

echo "Preparing sequences...";

# final pmet binary requires the universe file. Need to create this if validation scrip didnt.
# In promoters version, this is initially all genes in gff3 file. This version is used to add UTRs if
# requested, but any genes not in promoter_lengths file are filtered out before we get to PMET binary stage
# In this version we can just take a copy of all IDs in promoter lengths as we dont to UTR stuff

universefile=$indexingOutputDir/universe.txt

if [[ ! -f "$universefile" || ! -f "$indexingOutputDir/promoter_lengths.txt" ]]; then
    # should have been done by consistency checker
    # *** ADD THE DEPUPLICATION OF THE FASTA FILE HERE ****
    python3 $pmetroot/deduplicate.py \
            $genomefile \
            $indexingOutputDir/no_duplicates.fa

    # generate the promoter lengths file from the fasta file
    python3 $pmetroot/parse_promoter_lengths_from_fasta.py \
            $indexingOutputDir/no_duplicates.fa \
            $indexingOutputDir/promoter_lengths.txt
    # rm -f $indexingOutputDir/no_duplicates.fa

    cut -f 1  $indexingOutputDir/promoter_lengths.txt > $universefile
fi

# now we can actually FIMO our way to victory
fasta-get-markov $genomefile > $indexingOutputDir/genome.bg
# FIMO barfs ALL the output. that's not good. time for individual FIMOs
# on individual MEME-friendly motif files too

echo "Processing motifs...";

### Make motif  files from user's meme file
[ ! -d $indexingOutputDir/memefiles ] && mkdir $indexingOutputDir/memefiles

python3 $pmetroot/parse_memefile.py \
        $memefile \
        $indexingOutputDir/memefiles/

### creates IC.txt tsv file from, motif files
python3 $pmetroot/calculateICfrommeme_IC_to_csv.py \
        $indexingOutputDir/memefiles/ \
        $indexingOutputDir/IC.txt

### Create a fimo hits file form each motif file
[ ! -d $indexingOutputDir/fimo ] && mkdir $indexingOutputDir/fimo
[ ! -d $indexingOutputDir/fimohits ] && mkdir $indexingOutputDir/fimohits

# shopt -s nullglob # prevent loop produncing '*.txt'

# numfiles=$(ls -l $indexingOutputDir/memefiles/*.txt | wc -l)
# echo $numfiles" found"
# n=0
# # paralellise this loop
# for memefile in $indexingOutputDir/memefiles/*.txt; do
#     let n=$n+1
#     fimofile=`basename $memefile`
#     echo $fimofile

#     fimo    --text \
#             --thresh $fimothresh \
#             --verbosity 1 \
#             --bgfile $indexingOutputDir/genome.bg \
#             $memefile \
#             $genomefile \
#             > $indexingOutputDir/fimo/$fimofile &
#     [ `expr $n % $threads` -eq 0 ] && wait
# done

echo "Runing FIMO and PMET index..."
# Run fimo and pmetindex on each mitif (parallel version)
runFimoIndexing () {
    memefile=$1
    indexingOutputDir=$2
    fimothresh=$3
    pmetroot=$4
    maxk=$5
    topn=$6
    # echo $memefile
    filename=`basename $memefile .txt`
    # echo $filename

    mkdir -p $indexingOutputDir/fimo/$filename

    fimo \
        --no-qvalue \
        --text \
        --thresh $fimothresh \
        --verbosity 1 \
        --bgfile $indexingOutputDir/genome.bg\
        $memefile \
        $indexingOutputDir/no_duplicates.fa \
        > $indexingOutputDir/fimo/$filename/$filename.txt
    $pmetroot/pmetindex \
        -f $indexingOutputDir/fimo/$filename \
        -k $maxk \
        -n $topn \
        -o $indexingOutputDir \
        -p $indexingOutputDir/promoter_lengths.txt > $indexingOutputDir/pmetindex.log
    rm -rf $indexingOutputDir/fimo/$filename
}
export -f runFimoIndexing

find $indexingOutputDir/memefiles -name \*.txt \
    | parallel \
        --jobs=$threads \
        "runFimoIndexing {} $indexingOutputDir $fimothresh $pmetroot $maxk $topn"

echo "Delete unnecessary files"

# rm -r $indexingOutputDir/memefiles
# rm $indexingOutputDir/genome.bg

touch ${indexingOutputDir}_FLAG
# next stage needs the following inputs

#   promoter_lengths.txt        made by parse_promoter_lengths.py from .bed file
#   bimnomial_thresholds.txt    made by PMETindex
#   IC.txt                      made by calculateICfrommeme.py from meme file
#   gene input file             supplied by user

# ------------------------------------ Run pmet ----------------------------------
echo "Runing PMET pairing..."
mkdir -p $pairingOutputDir

PMETdev/scripts/pmetParallel_linux \
    -d $indexingOutputDir \
    -g $genefile \
    -i $icthreshold \
    -p promoter_lengths.txt \
    -b binomial_thresholds.txt \
    -c IC.txt \
    -f fimohits \
    -o $pairingOutputDir \
    -t 1

cat $pairingOutputDir/temp*.txt > $pairingOutputDir/motif_output.txt
rm -rf  $pairingOutputDir/temp*.txt
zip -j ${pairingOutputDir}.zip $pairingOutputDir/*
rm -rf $pairingOutputDir
touch ${pairingOutputDir}_FLAG

Rscript R/utils/send_mail.R $email $resultlink

exit 0;
