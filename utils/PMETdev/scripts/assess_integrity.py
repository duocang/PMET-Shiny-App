import numpy as np
import pandas as pd
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('infile',type=str)

args = parser.parse_args()

infile = args.infile
outfile = infile

bedfile = pd.read_csv(infile, sep='\t', index_col=None, header=None).values
dels = []
ind = 0
for i in range(1,bedfile.shape[0]):
	if bedfile[ind,3] == bedfile[i,3]:
		#split promoter found! find part of promoter closer to TSS
		if bedfile[ind,5] == '+':
			#it's going down the DNA strand, so keep the latter part
			dels.append(ind)
			ind = i
		else:
			#it's in the opposite direction, so the TSS is closer to the former part
			dels.append(i)
	else:
		#no split promoter. the norm
		ind = i
bedfile = np.delete(bedfile, dels, axis=0)

#export the integrity checked promoter file
np.savetxt(outfile, bedfile, fmt='%s\t%i\t%i\t%s\t%i\t%s')
