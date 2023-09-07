#!/bin/bash
set -e

# disable warnings
set -o errexit
set -o pipefail


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

# set up defaults
threads=4
icthreshold=24

# set up empty variables
pmetindex=
genefile=
outputdir=


# deal with arguments
# if none, exit
if [ $# -eq 0 ]; then
    print_red "No arguments supplied"  >&2
    exit 1
fi

while getopts ":d:g:i:t:o:e:l:" options; do
    case $options in
        d) print_white "Directory of PMET_index: "; print_orange "$OPTARG" >&2
        pmetindex=$OPTARG;;
        g) print_white "Gene file              : "; print_orange "$OPTARG" >&2
        genefile=$OPTARG;;
        i) print_white "IC threshold           : "; print_orange "$OPTARG" >&2
        icthreshold=$OPTARG;;
        t) print_white "Number of threads      : "; print_orange "$OPTARG" >&2
        threads=$OPTARG;;
        o) print_white "Output directory       : "; print_orange "$OPTARG" >&2
        outputdir=$OPTARG;;
        e) print_white "Email                  : "; print_orange "$OPTARG" >&2
        email=$OPTARG;;
        l) print_white "Download link          : "; print_orange "$OPTARG" >&2
        resultlink=$OPTARG;;
        \?) print_red "Invalid option: -$OPTARG" >&2
        exit 1;;
        :)  print_red "Option -$OPTARG requires an argument." >&2
        exit 1;;
    esac
done

# ------------------------------------ Run pmet ----------------------------------

mkdir -p $outputdir

universe_file=$pmetindex/universe.txt
gene_file=$genefile

print_light_blue "\nExtracting genes..."

if grep -wFf  $pmetindex/universe.txt $genefile > $outputdir/genes_used_PMET.txt; then
    print_fluorescent_yellow "      Valid genes found"
else
    print_red "      NO valid genes" > $outputdir/genes_used_PMET.txt
    print_red "      Search failed. Aborting further commands."
    exit 1
fi


if grep -vwFf $pmetindex/universe.txt $genefile > $outputdir/genes_not_found.txt; then
    print_orange "      Some genes not found"
else
    print_green "      All genes found" > $outputdir/genes_not_found.txt
    print_green "      Search finished. Continuting further commands."
fi


print_green "\nRuning PMET index..."

PMETdev/scripts/pmetParallel_linux \
    -d $pmetindex \
    -g $outputdir/genes_used_PMET.txt \
    -i $icthreshold \
    -p promoter_lengths.txt \
    -b binomial_thresholds.txt \
    -c IC.txt \
    -f fimohits \
    -t $threads \
    -o $outputdir #> $outputdir/PMET_OUTPUT.log

cat $outputdir/temp*.txt > $outputdir/PMET_OUTPUT.txt
rm -rf  $outputdir/temp*.txt
zip -j ${outputdir}.zip $outputdir/*
# rm -rf $outputdir
# touch ${outputdir}_FLAG

Rscript R/utils/send_mail.R $email $resultlink

print_green "DONE"
