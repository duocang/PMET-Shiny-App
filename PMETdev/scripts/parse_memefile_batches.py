import argparse
import numpy as np
import os

def count_motifs_in_file(file_content):
    motif_count = 0
    for line in file_content:
        if 'MOTIF' in line:
            motif_count += 1
    return motif_count

parser = argparse.ArgumentParser()
parser.add_argument('file', type=argparse.FileType('r'))
parser.add_argument('outdir', type=str)
parser.add_argument('batch', type=int, default=8)
args = parser.parse_args()

#keeping this here in case the docker turns out to work different
#bigfile = np.asarray(args.file.read().splitlines())
bigfile = np.asarray(args.file.readlines())

motif_number = count_motifs_in_file(bigfile)

batches = int(motif_number / args.batch)

headind = 0
while bigfile[headind].find('MOTIF') == -1:
    headind += 1

ind1 = headind
motif_counter = 0  # Counter for motifs
file_counter = 1  # Counter for the output files
inds_to_write = []

for i in range((ind1 + 1), len(bigfile)):
    if bigfile[i].find('MOTIF') > -1 or i == len(bigfile) - 1:  # also check if we're at the end of the file
        if bigfile[i].find('MOTIF') > -1:
            ind2 = i
        else:
            ind2 = i + 1  # to include the last line

        inds_to_write.extend(np.arange(ind1, ind2))
        bigfile[ind1] = bigfile[ind1].upper()
        motif_counter += 1

        # When we have collected batches motifs, or we're at the end of the file, write them to a new file
        if motif_counter == batches or i == len(bigfile) - 1:
            inds_to_write = np.append(np.arange(headind), inds_to_write)
            writer = open(os.path.normcase(args.outdir + str(file_counter) + '.txt'), 'w')
            lines_to_write = bigfile[inds_to_write]
            writer.writelines(lines_to_write)
            writer.close()

            # Reset the indices and counters
            inds_to_write = []
            motif_counter = 0
            file_counter += 1

        ind1 = ind2



