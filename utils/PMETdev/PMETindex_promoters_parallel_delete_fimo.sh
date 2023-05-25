#!/bin/bash
set -e

# disable warnings
set -o errexit
set -o pipefail

# called when user selects Promoters on web UI
# Takes as inputs from web page : fasta file , gff3 file, meme file, gene clusters file
# gfff3 identifier, N, k, promoter length, overlap included?, utr included?, [fimo threshold]

#This version requires outputdir, the 3 input files will be put there

# ICdict.pickle file, binomial_thresholds.txt file
# a directory called fimohits contaning files called motifname.txt fo reach mtoif in meme file input

# This is all the input needed by pmet tool, along with genes list file (clusters) that user will provide via web UI



# 22.1.18 Charlotte Rich
# last edit: 7.2.18 - removed the make 1 big fimohits files
#Edited by PEB June 2020. Will be called by run_pmet_min.php to create inputs for call to pmet binary
#Take progress file from 1% to 95%

#PEB DEc 2020. Called by run_pmet.php with params
# -r ./scripts -o jobdir/indexoutput/ -i gene_id= -k k -n N -p promlength -u Yes|No -v NoOverlap|AllowOverlap  fastafile gtffile memefile 

# fimo threshold is default

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
progFile="progress/progress"
threads=8

# set up empty variables

outputdir=
genomefile=
gff3file=
memefile=
gene_input_file=

# deal with arguments
# if none, exit
if [ $# -eq 0 ]; then
    echo "No arguments supplied"  >&2
    usage
    exit 1
fi

while getopts ":r:i:o:n:k:p:f:g:v:u:t:" options; do
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
        g) echo "Progress file: $OPTARG" >&2
        progFile=$OPTARG;;
        v) echo "Remove promoter overlaps with gene sequences: $OPTARG" >&2
        overlap=$OPTARG;;
        u) echo "Include 5' UTR sequence?: $OPTARG" >&2
        utr=$OPTARG;;
        t) echo "Number of threads: $OPTARG" >&2
        threads=$OPTARG;;
        \?) echo "Invalid option: -$OPTARG" >&2
        exit 1;;
        :)  echo "Option -$OPTARG requires an argument." >&2
        exit 1;;
    esac
done

shift $((OPTIND - 1))
genomefile=$1
gff3file=$2
memefile=$3
gene_input_file=$4

[ ! -d $outputdir ] && mkdir $outputdir

# cd $outputdir
# will have a directory input_files wthat will contain genome fle, gff3 file and memefile

# start off by filtering the .gff3 to gene lines only
start=$SECONDS

# progress taken from 1% to 95%
echo -e "0.01\tPreparing sequences..." > $progFile
echo "Preparing sequences...";

universefile=$outputdir/universe.txt
bedfile=$outputdir/genelines.bed

if [[ ! -f "$universefile"  ||  ! -f "$bedfile" ]]; then
	### Make genelines.bed and universe.txt if validation script hasn't

	grep -P '\tgene\t' $gff3file > $outputdir/genelines.gff3
	#parse up the .bed for promoter extraction, 'gene_id'
	python3 $pmetroot/parse_genelines.py $gff3id $outputdir/genelines.gff3 $bedfile
	#the python script takes the genelines.gff3 file and makes a genelines.bed out of it
	rm $outputdir/genelines.gff3
	#list of all genes found
	cut -f 4 $bedfile > $universefile
fi


### Make bedgenome.genome and genome_stripped.fa

echo -e "0.02\tCreating genome file..." > $progFile
echo "Creating genome file...";


# strip the potential FASTA line breaks. creates genome_stripped.fa
# python3 $pmetroot/strip_newlines.py $genomefile $outputdir/genome_stripped.fa
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
echo -e "0.03\tPreparing promoter region information..." > $progFile



bedtools flank -l $promlength -r 0 -s -i $bedfile -g $outputdir/bedgenome.genome > $outputdir/promoters.bed
rm $outputdir/bedgenome.genome

# remove overlapping promoter chunks
if [ $overlap == 'NoOverlap' ]; then
    echo -e "0.03\tRemoving overlaps..." > $progFile
	echo "Removing overlaps";
	sleep 0.1
	bedtools subtract -a $outputdir/promoters.bed -b $bedfile > $outputdir/promoters2.bed
	mv $outputdir/promoters2.bed $outputdir/promoters.bed
fi
rm $bedfile


### Update promoters.bed using gff3file and universe file

# check that we have no split promoters. if so, keep the bit closer to the TSS
# Updates promoters.bed
python3 $pmetroot/assess_integrity.py $outputdir/promoters.bed
# possibly add 5' UTR
if [ $utr == 'Yes' ]; then
    echo "Adding UTRs...";
    echo -e "0.03\tAdding UTRs..."  > $progFile #updates promoters.bed, takes about 45sec (about 20 sec for 10 000 promoters)
	python3 $pmetroot/parse_utrs.py $outputdir/promoters.bed $gff3file $universefile
fi

duration=$(( SECONDS - start ))
echo $duration" secs"

start=$SECONDS
### Create promoter_lenfths file from promoters.bed

# create promoter_lengths.txt
python3 $pmetroot/parse_promoter_lengths.py $outputdir/promoters.bed $outputdir/promoter_lengths.txt

## Make promoters.fa from promoters.bed and genome_stripped.fa

echo -e "0.04\tCreating promoters file..." >$progFile
echo "Creating promoters file";


# get promoters
bedtools getfasta -fi $outputdir/genome_stripped.fa -bed $outputdir/promoters.bed -s -fo $outputdir/promoters_rough.fa
rm $outputdir/genome_stripped.fa
rm $outputdir/genome_stripped.fa.fai


# creates promoters.fa
# replace the id of each seq with gene names
# python3 $pmetroot/parse_promoters.py $outputdir/promoters_rough.fa $outputdir/promoters.bed $outputdir/promoters.fa
# rm $outputdir/promoters.bed
# rm $outputdir/promoters_rough.fa
awk 'BEGIN{OFS="\t"} NR==FNR{a[NR]=$4; next} /^>/{$0=">"a[++i]} 1' \
    $outputdir/promoters.bed \
    $outputdir/promoters_rough.fa \
    > $outputdir/promoters.fa


### Make promoters.bg from promoters.fa


# now we can actually FIMO our way to victory
fasta-get-markov $outputdir/promoters.fa > $outputdir/promoters.bg
# FIMO barfs ALL the output. that's not good. time for individual FIMOs
# on individual MEME-friendly motif files too

duration=$(( SECONDS - start ))
echo $duration" secs"

start=$SECONDS

echo "Processing motifs...";
echo -e "0.05\tProcessing motifs..." >$progFile
# mkdir $outputdir/memefiles

### Make motif files from user's meme file
[ ! -d $outputdir/memefiles ] && mkdir $outputdir/memefiles



python3 $pmetroot/parse_memefile.py $memefile $outputdir/memefiles/

### creates IC.txt tsv file from, motif files
python3 $pmetroot/calculateICfrommeme_IC_to_csv.py $outputdir/memefiles/ $outputdir/IC.txt


### Create a fimo hits file form each motif file using promoters.bg and promoters.fa

[ ! -d $outputdir/fimo ] && mkdir $outputdir/fimo
[ ! -d $outputdir/fimohits ] && mkdir $outputdir/fimohits

shopt -s nullglob # prevent loop produncing '*.txt'
# 20 sec min per file, progress goes from 5% to 70%

numfiles=$(ls -l $outputdir/memefiles/*.txt | wc -l)
echo $numfiles" found"
n=0

for memefile in $outputdir/memefiles/*.txt; do
    let n=$n+1
    fimofile=`basename $memefile`
    echo $fimofile
    echo $n
    
    (
        mkdir -p $outputdir/fimo/$n && \
        fimo --no-qvalue \
            --text --thresh $fimothresh \
            --verbosity 1 \
            --bgfile $outputdir/promoters.bg\
            $memefile $outputdir/promoters.fa \
            > $outputdir/fimo/$n/$fimofile && \
        $pmetroot/pmetindex \
            -f $outputdir/fimo/$n \
            -k $maxk \
            -n $topn \
            -o $outputdir \
            -p $outputdir/promoter_lengths.txt \
            -g $progFile > $outputdir/pmetindx.log && \
        rm -rf $outputdir/fimo/$n
    ) & 
    [ `expr $n % $threads` -eq 0 ] && wait
done



# _fifofile="$$.fifo"
# mkfifo $_fifofile     # 创建一个FIFO类型的文件
# exec 6<>$_fifofile    # 将文件描述符6写入 FIFO 管道， 这里6也可以是其它数字
# rm $_fifofile         # 删也可以，
# threads=4 # 定义并行数量

# #根据并行度设置信号个数
# #事实上是在fd6中放置了$degree个回车符
# for ((i=0;i<${threads};i++));do
#     echo
# done >&6

# for memefile in $outputdir/memefiles/*.txt; do
#     # 从管道中读取（消费掉）一个字符信号
#     # 当FD6中没有回车符时，停止，实现并行度控制
#     read -u6
#     {
#         let n=$n+1
#         prog="0"$(bc <<< "scale=2;0.05+0.65*$n/$numfiles")
#         echo $prog
#         echo "  Processing motif $n of $numfiles"
#         # sleep 0.1
#         # bfid=`basename $memefile`
#         # fimofile=$bfid
        
#         # fimo --text --thresh $fimothresh --verbosity 1 --bgfile $outputdir/promoters.bg $memefile $outputdir/promoters.fa > $outputdir/fimo/$fimofile
#     } &
# done
# wait # 等待所有任务结束
# exec 6>&- # 关闭管道

echo "Delete unnecessary files"
rm -r $outputdir/memefiles
rm $outputdir/promoters.bg
rm $outputdir/promoters.fa


# For final pmet stage, promoter lengths file must have an entry for every gene in gene_input_file. It may not so here is a 
# convenient place to remove them and also remove from universe file
cut -f 1  $outputdir/promoter_lengths.txt > $universefile


exit 0;

# next stage needs the following inputs

#   promoter_lengths.txt        made by parse_promoter_lengths.py from .bed file
#   bimnomial_thresholds.txt    made by PMETindex
#   IC.txt                      made by calculateICfrommeme.py from meme file
#   gene input file             supplied by user