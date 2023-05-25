import argparse
import numpy as np
import pandas as pd
import sys

parser = argparse.ArgumentParser()
parser.add_argument('findstr',type=str)
parser.add_argument('infile',type=str)
parser.add_argument('outfile',type=str)

args = parser.parse_args()

#equal sign support! now disabled as fields are complicated!
findstr = args.findstr
infile = args.infile
outfile = args.outfile
#if findstr[-1]!='=':
#	findstr+='='
if findstr[-1]!='=':
	sys.stderr.write('WARNING: The field string does not end with an equal sign. This might be correct, depending on the GFF3 file, but double check your results')

#import using fancy pandas technology
#(and then immediately get rid of the fancy pandas technology)
genelines = pd.read_csv(infile, sep='\t', index_col=None, header=None)
genelines = genelines.values

#attempt to pull out the appropriate gene name and clump it into the final field
#(instead of the whole ;-separated shebang)
error_toggle = 0
for i in range(genelines.shape[0]):
	line = genelines[i,-1].split(';')
	local_toggle = 0
	for field in line:
		if findstr == field[:len(findstr)]:
			genelines[i,-1] = field[len(findstr):]
			local_toggle = 1
			break
	if local_toggle == 0:
		error_toggle = 1
		sys.stderr.write('Failed to find specified header ('+findstr[:-1]+') in GFF3 line: '+'\t'.join([str(x) for x in genelines[i,:]])+'\n')

#if our input is borked, we can't process it
if error_toggle == 1:
	sys.exit(1)

#okay then. have the processed thing ready. need to format it accordingly
genelines = genelines[:,[0,3,4,8,3,6]]
#for reasons I do not understand, the next to last column of the BED has to be a number.
for i in range(genelines.shape[0]):
	genelines[i,-2] = 1

#that's it. save it
np.savetxt(outfile,genelines,fmt='%s\t%i\t%i\t%s\t%i\t%s')
