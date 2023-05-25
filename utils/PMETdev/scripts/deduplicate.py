from Bio import SeqIO
import csv
import argparse

def get_args():
    #get the arguments
    parser = argparse.ArgumentParser()
    #input file
    parser.add_argument('infilepath',type=str)
    parser.add_argument('outfilepath',type=str)
    args = parser.parse_args()
    return args

 
args = get_args()

	
with open(args.outfilepath, 'a') as outFile:
    	record_ids = list()
    	for record in SeqIO.parse(args.infilepath, 'fasta'):
        	if record.id not in record_ids:
            		record_ids.append( record.id )
            		SeqIO.write(record, outFile, 'fasta')


