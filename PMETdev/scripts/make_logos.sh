#!/bin/bash

#12/2/18

mkdir logos
for fid in memefiles/*.txt
do
bfid=$(basename ${fid/.txt/})

ceqlogo -i $fid -m 1 -o logos/$bfid.eps

done
