#!/bin/bash
set -e

# disable warnings
set -o errexit
set -o pipefail


function usage () {
    cat >&2 <<EOF
        USAGE: PMETindexgenome [options] <genome> <gff3> <memefile>

        Creates PMET index for Paired Motif Enrichment Test using genome files.
        Required arguments:
        -r <PMETindex_path>	: Full path of python scripts called from this file. Required.
        -i <gff3_identifier> : gene identifier in gff3 file e.g. gene_id=

        Optional arguments:
        -o <output_directory> : Output directory for results
        -n <topn>	: How many top promoter hits to take per motif. Default=5000
        -k <max_k>	: Maximum motif hits allowed within each promoter.  Default: 5
        -p <promoter_length>	: Length of promoter in bp used to detect motif hits default: 1000
        -v <include_overlaps> :  Remove promoter overlaps with gene sequences. AllowOverlap or NoOverlap, Default : AllowOverlap
        -u <include_UTR> : Include 5' UTR sequence? Yes or No, default : No
        -f <fimo_threshold> : Specify a minimum quality for hits matched by fimo. Default: 0.05
        -t <threads>: Number of threads : 8
EOF
}

function error_exit() {
    echo "ERROR: $1" >&2
    usage
    exit 1
}

# set up defaults
topn=5000
maxk=5
promlength=1000
fimothresh=0.05
overlap="AllowOverlap"
utr="No"
gff3id='gene_id'
pmetroot="scripts"
threads=4
icthreshold=24

# set up empty variables
outputdir=
genomefile=
gff3file=
memefile=
gene_input_file=
pmetoutput=
genefile=

# deal with arguments
# if none, exit
if [ $# -eq 0 ]; then
    echo "No arguments supplied"  >&2
    usage
    exit 1
fi

while getopts ":r:i:o:n:k:p:f:g:v:u:t:c:x:g:e:l:" options; do
    case $options in
        r) echo "Full path of PMET_index:  $OPTARG" >&2
        pmetroot=$OPTARG;;
        i) echo "GFF3 feature identifier: $OPTARG" >&2
        gff3id=$OPTARG;;
        o) echo "Output directory for results: $OPTARG" >&2
        outputdir=$OPTARG;;
        n) echo "Top n promoter hits to take per motif: $OPTARG" >&2
        topn=$OPTARG;;
        k) echo "Top k motif hits within each promoter: $OPTARG" >&2
        maxk=$OPTARG;;
        p) echo "Promoter length: $OPTARG" >&2
        promlength=$OPTARG;;
        f) echo "Fimo threshold: $OPTARG" >&2
        fimothresh=$OPTARG;;
        v) echo "Remove promoter overlaps with gene sequences: $OPTARG" >&2
        overlap=$OPTARG;;
        u) echo "Include 5' UTR sequence?: $OPTARG" >&2
        utr=$OPTARG;;
        t) echo "Number of threads: $OPTARG" >&2
        threads=$OPTARG;;
        c) echo "IC threshold: $OPTARG" >&2
        icthreshold=$OPTARG;;
        x) echo "Output directory for PMET results: $OPTARG" >&2
        pmetoutput=$OPTARG;;
        g) echo "gene: $OPTARG" >&2
        genefile=$OPTARG;;
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


# rm -rf $outputdir/binomial_thresholds.txt
# rm -rf $outputdir/fimo
# rm -rf $outputdir/rimohits
# rm -rf $outputdir/IC.txt
# rm -rf $outputdir/pmetindex.log
# rm -rf $outputdir/promoter_length_deleted.txt
# rm -rf $outputdir/promoter_lengths_all.txt
# rm -rf $outputdir/promoter_lengths.txt
# rm -rf $outputdir/promoters_before_filter.bed
# rm -rf $outputdir/universe.txt


shift $((OPTIND - 1))
genomefile=$1
gff3file=$2
memefile=$3
gene_input_file=$4

mkdir -p $outputdir
universefile=$outputdir/universe.txt
bedfile=$outputdir/genelines.bed

# start off by filtering the .gff3 to gene lines only
start=$SECONDS

echo "Preparing sequences...";
# --------------------------- sort annotaion by coordinates ----------------------------
$pmetroot/gff3sort/gff3sort.pl $gff3file > ${gff3file}temp


# ----------------------------------- promoters.bed ------------------------------------
# extract annotation only for gene, no mran, exon etc.
if [[ ! -f "$universefile"  ||  ! -f "$bedfile" ]]; then
    if [[ "$(uname)" == "Linux" ]]; then
        grep -P '\tgene\t' ${gff3file}temp > $outputdir/genelines.gff3
    elif [[ "$(uname)" == "Darwin" ]]; then
        grep '\tgene\t' ${gff3file}temp > $outputdir/genelines.gff3
    else
        echo "Unsupported operating system."
    fi
	# grep -P '\tgene\t' ${gff3file}temp > $outputdir/genelines.gff3

	# parse up the .bed for promoter extraction, 'gene_id'
    # the python script takes the genelines.gff3 file and makes a genelines.bed out of it
	python3 $pmetroot/parse_genelines.py $gff3id $outputdir/genelines.gff3 $bedfile
	rm $outputdir/genelines.gff3

	# list of all genes found
	cut -f 4 $bedfile > $universefile
fi

### Make bedgenome.genome and genome_stripped.fa
echo "Creating genome file...";

# strip the potential FASTA line breaks. creates genome_stripped.fa
# python3 $pmetroot/strip_newlines.py $genomefile $outputdir/genome_stripped_py.fa
awk '/^>/ { if (NR!=1) print ""; printf "%s\n",$0; next;} \
    { printf "%s",$0;} \
    END { print ""; }'  $genomefile > $outputdir/genome_stripped.fa

# produces ouputdir/genome_stripped.fa
# create the .genome file which contains coordinates for each chromosome start
samtools faidx $outputdir/genome_stripped.fa
cut -f 1-2 $outputdir/genome_stripped.fa.fai > $outputdir/bedgenome.genome


duration=$(( SECONDS - start ))
echo $duration" secs"
start=$SECONDS

### Use genelines.bed and bedgenome.genome to make promoters.bed
echo "Preparing promoter region information...";

# 在bedtools中，flank是一个命令行工具，用于在BED格式的基因组坐标文件中对每个区域进行扩展或缩短。
# 当遇到负链（negative strand）时，在区域的右侧进行扩展或缩短，而不是左侧。
bedtools flank \
    -l $promlength \
    -r 0 -s -i $bedfile \
    -g $outputdir/bedgenome.genome \
    > $outputdir/promoters.bed
rm $outputdir/bedgenome.genome

# remove overlapping promoter chunks
if [ $overlap == 'NoOverlap' ]; then
	echo "Removing overlaps";
	sleep 0.1
	bedtools subtract -a $outputdir/promoters.bed -b $bedfile > $outputdir/promoters2.bed
	mv $outputdir/promoters2.bed $outputdir/promoters.bed
fi
rm $bedfile


# Update promoters.bed using gff3file and universe file

# check that we have no split promoters. if so, keep the bit closer to the TSS
# Updates promoters.bed
python3 $pmetroot/assess_integrity.py $outputdir/promoters.bed
# possibly add 5' UTR
if [ $utr == 'Yes' ]; then
    echo "Adding UTRs...";
	python3 $pmetroot/parse_utrs.py $outputdir/promoters.bed ${gff3file}temp $universefile
fi

duration=$(( SECONDS - start ))
echo $duration" secs"
start=$SECONDS

# -------------------- promoter_lenfths file from promoters.bed ----------------------------
# python3 $pmetroot/parse_promoter_lengths.py $outputdir/promoters.bed $outputdir/promoter_lengths.txt
awk '{print $4 "\t" ($3 - $2)}' $outputdir/promoters.bed > $outputdir/promoter_lengths_all.txt

# filters out the rows with NEGATIVE lengths
# Process the data line by line
while read -r gene length; do
    # Check if the length is a positive number
    if (( length >= 0 )); then
        # Append rows with positive length to the output file
        echo "$gene $length" >> $outputdir/promoter_lengths.txt
    else
        # Append rows with negative length to the deleted file
        echo "$gene $length" >> $outputdir/promoter_length_deleted.txt
    fi
done < $outputdir/promoter_lengths_all.txt

# remove rows from "promoters.bed" that contain NEGATIVE genes (promoter_length_deleted.txt)
# get genes with negative length
cut -d " " -f1  $outputdir/promoter_length_deleted.txt > $outputdir/genes_negative.txt

grep -v -w -f \
    $outputdir/genes_negative.txt \
    $outputdir/promoters.bed \
    > $outputdir/filtered_promoters.bed

mv $outputdir/promoters.bed $outputdir/promoters_before_filter.bed
mv $outputdir/filtered_promoters.bed $outputdir/promoters.bed
rm $outputdir/genes_negative.txt

# update gene list (no NEGATIVE genes)
cut -d " " -f1  $outputdir/promoter_lengths.txt > $universefile

# ----------------------------------- promoters.fa -----------------------------------
# Make promoters.fa from promoters.bed and genome_stripped.fa
echo "Creating promoters file";

# get promoters
bedtools getfasta -fi \
    $outputdir/genome_stripped.fa \
    -bed $outputdir/promoters.bed \
    -s -fo $outputdir/promoters_rough.fa
rm $outputdir/genome_stripped.fa
rm $outputdir/genome_stripped.fa.fai

# replace the id of each seq with gene names
# python3 $pmetroot/parse_promoters.py $outputdir/promoters_rough.fa $outputdir/promoters.bed $outputdir/promoters.fa
awk 'BEGIN{OFS="\t"} NR==FNR{a[NR]=$4; next} /^>/{$0=">"a[++i]} 1' \
    $outputdir/promoters.bed \
    $outputdir/promoters_rough.fa \
    > $outputdir/promoters.fa
rm $outputdir/promoters.bed
rm $outputdir/promoters_rough.fa


#------------------------- promoters.bg from promoters.fa ----------------------------
fasta-get-markov $outputdir/promoters.fa > $outputdir/promoters.bg

duration=$(( SECONDS - start ))
echo $duration" secs"
start=$SECONDS
echo "Processing motifs...";

# Make individual motif files from user's meme file
[ ! -d $outputdir/memefiles ] && mkdir $outputdir/memefiles
python3 $pmetroot/parse_memefile.py $memefile $outputdir/memefiles/

# ----------------------------------- IC.txt ---------------------------------------
python3 $pmetroot/calculateICfrommeme_IC_to_csv.py $outputdir/memefiles/ $outputdir/IC.txt

# -------------------------------- Run fimo and pmetindex --------------------------
# Create a fimo hits file form each motif file using promoters.bg and promoters.fa
[ ! -d $outputdir/fimo     ] && mkdir $outputdir/fimo
[ ! -d $outputdir/fimohits ] && mkdir $outputdir/fimohits

# shopt -s nullglob # prevent loop produncing '*.txt'

# Run fim and pmetindex on each mitif (parallel version)
runFimoIndexing () {
    memefile=$1
    outputdir=$2
    fimothresh=$3
    pmetroot=$4
    maxk=$5
    topn=$6
    # echo $memefile
    filename=`basename $memefile .txt`
    # echo $filename

    mkdir -p $outputdir/fimo/$filename

    fimo \
        --no-qvalue \
        --text \
        --thresh $fimothresh \
        --verbosity 1 \
        --bgfile $outputdir/promoters.bg\
        $memefile \
        $outputdir/promoters.fa \
        > $outputdir/fimo/$filename/$filename.txt
    $pmetroot/pmetindex \
        -f $outputdir/fimo/$filename \
        -k $maxk \
        -n $topn \
        -o $outputdir \
        -p $outputdir/promoter_lengths.txt > $outputdir/pmetindex.log
    rm -rf $outputdir/fimo/$filename
}
export -f runFimoIndexing

find $outputdir/memefiles -name \*.txt \
    | parallel \
        --jobs=$threads \
        "runFimoIndexing {} $outputdir $fimothresh $pmetroot $maxk $topn"

numfiles=$(ls -l $outputdir/memefiles/*.txt | wc -l)
echo $numfiles" motifs found"

echo "Delete unnecessary files"
rm -r $outputdir/memefiles
rm $outputdir/promoters.bg
rm $outputdir/promoters.fa
touch ${outputdir}_FLAG



# next stage needs the following inputs

#   promoter_lengths.txt        made by parse_promoter_lengths.py from .bed file
#   bimnomial_thresholds.txt    made by PMETindex
#   IC.txt                      made by calculateICfrommeme.py from meme file
#   gene input file             supplied by user

# ------------------------------------ Run pmet ----------------------------------

mkdir -p $pmetoutput

# 定义输入文件路径
universe_file=$outputdir/universe.txt
gene_file=$genefile


grep -vwFf $outputdir/universe.txt $genefile > $pmetoutput/genes_skipped.txt
grep -wFf  $outputdir/universe.txt $genefile > $pmetoutput/genes_used_PMET.txt


PMETdev/scripts/pmetParallel_linux \
    -d $outputdir \
    -g $pmetoutput/genes_used_PMET.txt \
    -i $icthreshold \
    -p promoter_lengths.txt \
    -b binomial_thresholds.txt \
    -c IC.txt \
    -f fimohits \
    -t $threads \
    -o $pmetoutput > $pmetoutput/PMET_OUTPUT.log

cat $pmetoutput/temp*.txt > $pmetoutput/PMET_OUTPUT.txt
rm -rf  $pmetoutput/temp*.txt
zip -j ${pmetoutput}.zip $pmetoutput/*
rm -rf $pmetoutput
touch ${pmetoutput}_FLAG

Rscript R/utils/send_mail.R $email $resultlink

exit 0;