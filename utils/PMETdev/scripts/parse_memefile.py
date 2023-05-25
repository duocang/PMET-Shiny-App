import argparse
import numpy as np
import os

parser = argparse.ArgumentParser()
parser.add_argument('file', type=argparse.FileType('r'))
parser.add_argument('outdir', type=str)
args = parser.parse_args()

#keeping this here in case the docker turns out to work different
#bigfile = np.asarray(args.file.read().splitlines())
bigfile = np.asarray(args.file.readlines())


#motcount = 0
#for i in range(len(bigfile)):
#    if bigfile[i].find('MOTIF')>-1:
#        motcount = motcount+1
##now let's transform it into the actual number of zeros
#motcount = int(np.floor(np.log10(motcount))+1)

#time to find the header
headind = 0
while bigfile[headind].find('MOTIF')==-1:
    headind += 1
#so ind is where the header ends and the MOTIFs start
ind1 = headind
counter = 1
for i in range((ind1+1),len(bigfile)):
    if bigfile[i].find('MOTIF')>-1:
        ind2 = i
        inds_to_write = np.append(np.arange(headind),np.arange(ind1,ind2))
        bigfile[ind1] = bigfile[ind1].upper()
        lines_to_write = bigfile[inds_to_write]
        motname = bigfile[ind1].split()[1]
        writer = open(os.path.normcase(args.outdir+motname+'.txt'),'w')
        writer.writelines(lines_to_write)
        #the start of the new motif is here
        ind1 = ind2
        counter = counter+1
#we have a motif at the end
ind2 = i+1
inds_to_write = np.append(np.arange(headind),np.arange(ind1,ind2))
bigfile[ind1] = bigfile[ind1].upper()
lines_to_write = bigfile[inds_to_write]
motname = bigfile[ind1].split()[1]
writer = open(os.path.normcase(args.outdir+motname+'.txt'),'w')
writer.writelines(lines_to_write)
