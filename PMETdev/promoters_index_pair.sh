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
        -r <index_dir>	: Full path of python scripts called from this file. Required.
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
indexingOutputDir=
genomefile=
gff3file=
memefile=
gene_input_file=
pairingOutputDir=
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
        indexingOutputDir=$OPTARG;;
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
        pairingOutputDir=$OPTARG;;
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


shift $((OPTIND - 1))
genomefile=$1
gff3file=$2
memefile=$3
gene_input_file=$4
universefile=$indexingOutputDir/universe.txt
bedfile=$indexingOutputDir/genelines.bed

mkdir -p $indexingOutputDir

start=$SECONDS


# -------------------------------------------------------------------------------------------
# 1. sort annotaion by gene coordinates
echo "1. Sorting annotation by gene coordinates"
$pmetroot/gff3sort/gff3sort.pl $gff3file > $indexingOutputDir/sorted.gff3


# -------------------------------------------------------------------------------------------
# 2. extract gene line from annoitation
echo "2. Extracting gene line from annoitation"
# grep -P '\tgene\t' $indexingOutputDir/sorted.gff3 > $indexingOutputDir/genelines.gff3
if [[ "$(uname)" == "Linux" ]]; then
    grep -P '\tgene\t' $indexingOutputDir/sorted.gff3 > $indexingOutputDir/genelines.gff3
elif [[ "$(uname)" == "Darwin" ]]; then
    grep '\tgene\t' $indexingOutputDir/sorted.gff3 > $indexingOutputDir/genelines.gff3
else
    echo "Unsupported operating system."
fi

# -------------------------------------------------------------------------------------------
# 3. extract chromosome , start, end, gene ('gene_id' for input) ...
echo "Extracting chromosome, start, end, gene ..."
python3 $pmetroot/parse_genelines.py $gff3id $indexingOutputDir/genelines.gff3 $bedfile

# -------------------------------------------------------------------------------------------
# 4. filter invalid genes: start should be smaller than end
invalidRows=$(awk '$2 >= $3' $bedfile)
if [[ -n "$invalidRows" ]]; then
    echo "$invalidRows" > $outputdir/invalid_genelines.bed
fi
# awk '$2 >= $3' $bedfile > $outputdir/invalid_genelines.bed
awk '$2 <  $3' $bedfile > temp.bed && mv temp.bed $bedfile
# 在BED文件格式中，无论是正链（+）还是负链（-），起始位置总是小于终止位置。
# 这是因为起始和终止位置是指定基因或基因组特性在基因组上的物理位置，而不是表达或翻译的方向。
# starting site < stopped site in bed file


# -------------------------------------------------------------------------------------------
# 5. list of all genes found
cut -f 4 $bedfile > $universefile

# -------------------------------------------------------------------------------------------
# 6. strip the potential FASTA line breaks. creates genome_stripped.fa
awk '/^>/ { if (NR!=1) print ""; printf "%s\n",$0; next;} \
    { printf "%s",$0;} \
    END { print ""; }'  $genomefile > $indexingOutputDir/genome_stripped.fa
# python3 $pmetroot/strip_newlines.py $genomefile $indexingOutputDir/genome_stripped_py.fa


# -------------------------------------------------------------------------------------------
# 7. create the .genome file which contains coordinates for each chromosome start
samtools faidx $indexingOutputDir/genome_stripped.fa
cut -f 1-2 $indexingOutputDir/genome_stripped.fa.fai > $indexingOutputDir/bedgenome.genome


duration=$(( SECONDS - start ))
echo $duration" secs"
start=$SECONDS

# -------------------------------------------------------------------------------------------
# 8. create promoters' coordinates from annotation
# 在bedtools中，flank是一个命令行工具，用于在BED格式的基因组坐标文件中对每个区域进行扩展或缩短。
# 当遇到负链（negative strand）时，在区域的右侧进行扩展或缩短，而不是左侧。
bedtools flank \
    -l $promlength \
    -r 0 -s -i $bedfile \
    -g $indexingOutputDir/bedgenome.genome \
    > $indexingOutputDir/promoters.bed

# -------------------------------------------------------------------------------------------
# 9. remove overlapping promoter chunks
if [ $overlap == 'NoOverlap' ]; then
	echo "9. Removing overlaps";
	sleep 0.1
	bedtools subtract \
        -a $indexingOutputDir/promoters.bed \
        -b $bedfile > $indexingOutputDir/promoters2.bed
	mv $indexingOutputDir/promoters2.bed $indexingOutputDir/promoters.bed
fi


# -------------------------------------------------------------------------------------------
# 10. check split promoters. if so, keep the bit closer to the TSS
python3 $pmetroot/assess_integrity.py $indexingOutputDir/promoters.bed

# -------------------------------------------------------------------------------------------
# 11. add 5' UTR
if [ $utr == 'Yes' ]; then
    echo "11. Adding UTRs...";
	python3 $pmetroot/parse_utrs.py \
        $indexingOutputDir/promoters.bed \
        $indexingOutputDir/sorted.gff3 $universefile
fi

# -------------------------------------------------------------------------------------------
# 12. promoter lenfths from promoters.bed
# python3 $pmetroot/parse_promoter_lengths.py \
#     $indexingOutputDir/promoters.bed \
#     $indexingOutputDir/promoter_lengths.txt
awk '{print $4 "\t" ($3 - $2)}' $indexingOutputDir/promoters.bed \
    > $indexingOutputDir/promoter_lengths_all.txt

# -------------------------------------------------------------------------------------------
# 13. filters out the rows with NEGATIVE lengths
while read -r gene length; do
    # Check if the length is a positive number
    if (( length >= 0 )); then
        # Append rows with positive length to the output file
        echo "$gene $length" >> $indexingOutputDir/promoter_lengths.txt
    else
        # Append rows with negative length to the deleted file
        echo "$gene $length" >> $indexingOutputDir/promoter_length_deleted.txt
    fi
done < $indexingOutputDir/promoter_lengths_all.txt

# -------------------------------------------------------------------------------------------
# 14. remove NEGATIVE genes
if [ -f "$indexingOutputDir/promoter_length_deleted.txt" ]; then
    echo "14. Removing NEGATIVE genes"
    cut -d " " \
        -f1  $indexingOutputDir/promoter_length_deleted.txt \
        > $indexingOutputDir/genes_negative.txt
fi

# -------------------------------------------------------------------------------------------
# 15. filter promoter annotation with negative length
echo "15. Filtering promoter with negative length"
if [ -f "$indexingOutputDir/promoter_length_deleted.txt" ]; then
    grep -v -w -f \
        $indexingOutputDir/genes_negative.txt \
        $indexingOutputDir/promoters.bed \
        > $indexingOutputDir/filtered_promoters.bed

    mv $indexingOutputDir/promoters.bed $indexingOutputDir/promoters_before_filter.bed
    mv $indexingOutputDir/filtered_promoters.bed $indexingOutputDir/promoters.bed
fi


# -------------------------------------------------------------------------------------------
# 16. update gene list (no NEGATIVE genes)
echo "16. Updating gene list (about NEGATIVE genes)";
cut -d " " -f1  $indexingOutputDir/promoter_lengths.txt > $universefile


# -------------------------------------------------------------------------------------------
# 17. create promoters fasta
echo "17. Creating promoters file";
bedtools getfasta -fi \
    $indexingOutputDir/genome_stripped.fa \
    -bed $indexingOutputDir/promoters.bed \
    -s -fo $indexingOutputDir/promoters_rough.fa


# -------------------------------------------------------------------------------------------
# 18. replace the id of each seq with gene names
echo "18. Replacing the id of each sequences' with gene names"
awk 'BEGIN{OFS="\t"} NR==FNR{a[NR]=$4; next} /^>/{$0=">"a[++i]} 1' \
    $indexingOutputDir/promoters.bed \
    $indexingOutputDir/promoters_rough.fa \
    > $indexingOutputDir/promoters.fa
# python3 $pmetroot/parse_promoters.py \
#     $indexingOutputDir/promoters_rough.fa \
#     $indexingOutputDir/promoters.bed \
#     $indexingOutputDir/promoters.fa

# -------------------------------------------------------------------------------------------
# 19. promoters.bg from promoters.fa
fasta-get-markov $indexingOutputDir/promoters.fa > $indexingOutputDir/promoters.bg

# duration=$(( SECONDS - start ))
# echo $duration" secs"
# start=$SECONDS
# echo "Processing motifs...";

# -------------------------------------------------------------------------------------------
# 20. individual motif files from user's meme file
[ ! -d $indexingOutputDir/memefiles ] && mkdir $indexingOutputDir/memefiles
python3 $pmetroot/parse_memefile.py $memefile $indexingOutputDir/memefiles/

# -------------------------------------------------------------------------------------------
# 21. IC.txt
echo "21. Generating IC.txt"
python3 $pmetroot/calculateICfrommeme_IC_to_csv.py \
    $indexingOutputDir/memefiles/ \
    $indexingOutputDir/IC.txt

# -------------------------------- Run fimo and pmetindex --------------------------
[ ! -d $indexingOutputDir/fimo     ] && mkdir $indexingOutputDir/fimo
[ ! -d $indexingOutputDir/fimohits ] && mkdir $indexingOutputDir/fimohits

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
        --bgfile $indexingOutputDir/promoters.bg\
        $memefile \
        $indexingOutputDir/promoters.fa \
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
    | parallel  --jobs=$threads \
        "runFimoIndexing {} $indexingOutputDir $fimothresh $pmetroot $maxk $topn"

numfiles=$(ls -l $indexingOutputDir/memefiles/*.txt | wc -l)
echo $numfiles" motifs found"

echo "Delete unnecessary files"

echo "Delete unnecessary files"

rm $indexingOutputDir/genelines.gff3
rm $indexingOutputDir/bedgenome.genome
rm $bedfile
rm $indexingOutputDir/genome_stripped.fa
rm $indexingOutputDir/genome_stripped.fa.fai
rm $indexingOutputDir/promoters.bed
rm $indexingOutputDir/promoters_rough.fa
if [ -f "$indexingOutputDir/promoter_length_deleted.txt" ]; then
    rm $indexingOutputDir/genes_negative.txt
    rm $indexingOutputDir/promoter_length_deleted.txt
fi
rm -r $indexingOutputDir/memefiles
rm $indexingOutputDir/promoters.bg
rm $indexingOutputDir/promoters.fa
rm $indexingOutputDir/sorted.gff3
touch ${indexingOutputDir}_FLAG



# next stage needs the following inputs

#   promoter_lengths.txt        made by parse_promoter_lengths.py from .bed file
#   bimnomial_thresholds.txt    made by PMETindex
#   IC.txt                      made by calculateICfrommeme.py from meme file
#   gene input file             supplied by user

# ------------------------------------ Run pmet ----------------------------------

mkdir -p $pairingOutputDir

# 定义输入文件路径
universe_file=$indexingOutputDir/universe.txt
gene_file=$genefile


# grep -vwFf  $indexingOutputDir/universe.txt $genefile > $pairingOutputDir/genes_not_found.txt
# grep -wFf   $indexingOutputDir/universe.txt $genefile > $pairingOutputDir/genes_used_PMET.txt

if grep -wFf  $indexingOutputDir/universe.txt $genefile > $pairingOutputDir/genes_used_PMET.txt; then
    echo "Find valid gene(s)"
else
    echo "NO valid genes" > $outputdir/genes_used_PMET.txt
    echo "Search failed. Aborting further commands."
    exit 1
fi


if grep -vwFf $indexingOutputDir/universe.txt $genefile > $pairingOutputDir/genes_not_found.txt; then
    echo "Some gene(s) not found"
else
    echo "All genes found" > $pairingOutputDir/genes_not_found.txt
    echo "Search finished. Continuting further commands."
fi


PMETdev/scripts/pmetParallel_linux \
    -d $indexingOutputDir \
    -g $pairingOutputDir/genes_used_PMET.txt \
    -i $icthreshold \
    -p promoter_lengths.txt \
    -b binomial_thresholds.txt \
    -c IC.txt \
    -f fimohits \
    -t $threads \
    -o $pairingOutputDir > $pairingOutputDir/PMET_OUTPUT.log

cat $pairingOutputDir/temp*.txt > $pairingOutputDir/PMET_OUTPUT.txt
rm -rf  $pairingOutputDir/temp*.txt
zip -j ${pairingOutputDir}.zip $pairingOutputDir/*
rm -rf $pairingOutputDir
touch ${pairingOutputDir}_FLAG

Rscript R/utils/send_mail.R $email $resultlink

exit 0;