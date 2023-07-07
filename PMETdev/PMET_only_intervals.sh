#!/bin/bash
set -e

# disable warnings
set -o errexit
set -o pipefail


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
    echo "No arguments supplied"  >&2
    exit 1
fi

while getopts ":d:g:i:t:o:e:l:" options; do
    case $options in
        d) echo "Full path of PMET_index:  $OPTARG" >&2
        pmetindex=$OPTARG;;
        g) echo "Gene file: $OPTARG" >&2
        genefile=$OPTARG;;
        i) echo "IC threshold: $OPTARG" >&2
        icthreshold=$OPTARG;;
        t) echo "Number of threads: $OPTARG" >&2
        threads=$OPTARG;;
        o) echo "Output directory for results: $OPTARG" >&2
        outputdir=$OPTARG;;
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

# ------------------------------------ Run pmet ----------------------------------
mkdir -p $outputdir

PMETdev/scripts/pmetParallel_linux \
    -d $pmetindex \
    -g $genefile \
    -i $icthreshold \
    -p promoter_lengths.txt \
    -b binomial_thresholds.txt \
    -c IC.txt \
    -f fimohits \
    -t $threads \
    -o $outputdir > $outputdir/PMET_OUTPUT.log

cat $outputdir/temp*.txt > $outputdir/motif_output.txt
rm -rf  $outputdir/temp*.txt
zip -j ${outputdir}.zip $outputdir/*
rm -rf $outputdir
touch ${outputdir}_FLAG

Rscript R/utils/send_mail.R $email $resultlink

exit 0;
