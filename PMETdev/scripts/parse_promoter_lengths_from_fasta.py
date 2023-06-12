from Bio import SeqIO
import csv
import argparse
 
def get_args():
    #get the arguments
    parser = argparse.ArgumentParser()
    #input file
    parser.add_argument('filepath',type=str)
    parser.add_argument('outfilepath',type=str)
    args = parser.parse_args()
    return args


 
args = get_args()


 
#prom = pd.read_csv(args.filepath,header=None,index_col=None,sep='\t').values
#fid = open('promoter_lengths.txt','w')
#toggle = ''
#
#for i in np.arange(prom.shape[0]):
#      fid.write(toggle+prom[i,3]+'\t'+str(int(prom[i,2])-int(prom[i,1])))
#      toggle='\n'
#
#fid.close()
 
input_file = open(args.filepath)
my_dict = SeqIO.to_dict(SeqIO.parse(input_file, "fasta"))
peak_size = {}
 
for x in my_dict:
   peak_size[x]=len(my_dict[x])
 
# This truncated the dictionary so that it lost some regions
# w = csv.writer(open("promoter_lengths_coreprom.txt", "w"), delimiter='\t')
# for key, val in peak_size.items():
#     w.writerow([key, val])
 
# This worked for a fast file with 33602 genomic regions
with open(args.outfilepath, 'w') as f:
            w = csv.writer(f, delimiter='\t', lineterminator='\n')
            w.writerows(peak_size.items())
 
 
