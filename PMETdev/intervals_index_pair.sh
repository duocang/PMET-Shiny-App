#!/usr/bin/bash
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

print_red(){
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    printf "${RED}$1${NC}\n"
}

print_green(){
    BOLD_GREEN='\033[1;32m'
    NC='\033[0m' # No Color
    printf "${BOLD_GREEN}$1${NC}\n"
}

print_orange(){
    ORANGE='\033[38;5;214m'
    NC='\033[0m' # No Color
    printf "${ORANGE}$1${NC}\n"
}

print_light_blue(){
    ORANGE='\033[0;33m'
    NC='\033[0m' # No Color
    printf "${ORANGE}$1${NC}\n"
}

print_fluorescent_yellow(){
    FLUORESCENT_YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
    printf "${FLUORESCENT_YELLOW}$1${NC}\n"
}

print_light_blue(){
    LIGHT_BLUE='\033[1;34m'
    NC='\033[0m' # No Color
    printf "${LIGHT_BLUE}$1${NC}\n"
}

print_white(){
    WHITE='\033[1;37m'
    NC='\033[0m' # No Color
    printf "${WHITE}$1${NC}"
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
        r) print_white "Directory of PMET_index                   : "; print_orange "$OPTARG" >&2
        pmetroot=$OPTARG;;
        o) print_white "Directory of homotypic motif hits         : "; print_orange "$OPTARG" >&2
        indexingOutputDir=$OPTARG;;
        n) print_white "Top n promoter hits to take per motif     : "; print_orange "$OPTARG" >&2
        topn=$OPTARG;;
        k) print_white "Top k motif hits within each promoter     : "; print_orange "$OPTARG" >&2
        maxk=$OPTARG;;
        f) print_white "Fimo threshold                            : "; print_orange "$OPTARG" >&2
        fimothresh=$OPTARG;;
        t) print_white "Number of threads                         : "; print_orange "$OPTARG" >&2
        threads=$OPTARG;;
        x) print_white "Output directory of heterotypic motif hits: "; print_orange "$OPTARG" >&2
        pairingOutputDir=$OPTARG;;
        g) print_white "Path of gene files                        : "; print_orange "$OPTARG" >&2
        genefile=$OPTARG;;
        c) print_white "IC threshold                              : "; print_orange "$OPTARG" >&2
        icthreshold=$OPTARG;;
        e) print_white "Email                                     : "; print_orange "$OPTARG" >&2
        email=$OPTARG;;
        l) print_white "Output directory for results              : "; print_orange "$OPTARG" >&2
        resultlink=$OPTARG;;
        \?) print_red "Invalid option: -$OPTARG" >&2
        exit 1;;
        :)  print_red "Option -$OPTARG requires an argument." >&2
        exit 1;;
    esac
done

# rename input file variable
shift $((OPTIND - 1))
genomefile=$1
memefile=$2

[ ! -d $indexingOutputDir ] && mkdir $indexingOutputDir
# cd $indexingOutputDir


Rscript R/utils/send_mail.R "wangxuesong29@gmail.com" $email

Rscript R/utils/send_mail.R $email

print_green "Preparing sequences...";

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

print_light_blue "Processing motifs...";

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

print_green "Runing FIMO and PMET index..."
# Run fimo and pmetindex on each mitif (parallel version)
runFimoIndexing () {
    memefile=$1
    indexingOutputDir=$2
    fimothresh=$3
    pmetroot=$4
    maxk=$5
    topn=$6
    filename=`basename $memefile .txt`

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
print_green "Runing PMET pairing..."
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
    -t $threads

cat $pairingOutputDir/temp*.txt > $pairingOutputDir/motif_output.txt
rm -rf  $pairingOutputDir/temp*.txt
zip -j ${pairingOutputDir}.zip $pairingOutputDir/*
# rm -rf $pairingOutputDir
# touch ${pairingOutputDir}_FLAG

Rscript R/utils/send_mail.R $email $resultlink
