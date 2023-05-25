import argparse
import numpy as np
import pandas as pd
import scipy.stats as sps
import sys


def get_args():
    #get the arguments
    parser = argparse.ArgumentParser()
    # fimo file
    parser.add_argument('fimofile',type=str)
    #number of hits within a promoter, k
    parser.add_argument('tar',type=int)
    # topn promotres to write out, n
    parser.add_argument('n',type=int)
    args = parser.parse_args()
    return args

def overlapcheck(span1, span2):
    #helper function to assess whether span1 and span2 overlap
    if span1[0] >= span2[0] and span1[0] <= span2[1]:
        return True
    if span1[1] >= span2[0] and span1[1] <= span2[1]:
        return True
    return False

def geo_mean(iterable):
    a = np.array(iterable)
    return a.prod()**(1.0/len(a))

def geom_binom_test(coin,promsize,mot_len):
    binom_p=[]
    flips = 2*(promsize - mot_len + 1)
    
    for k in range(0,len(coin)):
        vals=np.array(coin[:k+1],dtype=float) #elements 0 to k
        geom = geo_mean(vals)
        #binom_p.append(sps.binom.sf(k,flips,geom))
        binom_p.append(1-binomial_cdf(k,flips,geom))
    binom_p = np.asarray(binom_p)
    #print(binom_p)
    return(binom_p)

def binomial_cdf(x,n,p):
    """
    calculates the binomial-pvalue much more efficiently than sps.binom.sf
    """
    cdf = 0
    b = 0
    for k in range(x+1):
        if k > 0:
            b += + np.log(n-k+1) - np.log(k)
        log_pmf_k = b + k * np.log(p) + (n-k) * np.log(1-p)
        cdf += np.exp(log_pmf_k)
    return cdf


def write_threshold_results(writer, topN):
    row=topN.shape[0]-1
    writer.write(topN[row][2]+'\t'+topN[row][0]+'\n')

#let the command line arguments flow in
args = get_args()

#import data. same old pandas into non pandas trick, now with a "header"
#(the first line of the file is pretty useless)
# t0=time.time()
fimo = pd.read_csv(args.fimofile, sep='\t', index_col=None, header=0)
#fimo = pd.read_csv('fimo_SPL1.txt', sep='\t', index_col=None, header=0)

fimo = fimo.values
# print(fimo[0,0])
#just check if the file is empty. some motifs hit nothing
if not fimo.size:
    sys.exit(0)

#and now let's import the parsed promoter sizes to do the binomial properly
promsize = {}
with open('promoter_lengths.txt','r') as fid:
    for line in fid:
        line=line.split()
        promsize[line[0]] = int(line[1])

# d = time.time() - t0
# print("load files: %.2f s." % d)

#let's kick out the potential overlapping motif instances
# t0=time.time()

#here motif hits are checked within gene. If 2 overlap, remove one with worse pval

##Kates version has done this loop. This is k-independent so can just be done once for any k
del_inds = []
prev_ind = 0
##print(fimo.shape[0])
for i in range(1,fimo.shape[0]):
    #case number one - the motifs are for the same gene
    if (fimo[i,1] == fimo[prev_ind,1]):
        #so we need to check if we gots ourselves an overlap
        if overlapcheck(fimo[i,[2,3]],fimo[prev_ind,[2,3]]):
            #if we're in here, we have an overlap
            if fimo[i,6] < fimo[prev_ind,6]:
                #if we're in here, our current motif outranks the previous one on p-value
                del_inds.append(prev_ind)
                prev_ind = i
            else:
                #if we're in here, the previous one's p-value was stronger
                del_inds.append(i)
        else:
            #if we're in here, then there's no overlap
            prev_ind = i
    else:
        #shift index to the next gene
        prev_ind = i




#so, the digging for redundant motifs has completed. let's see what we found
fimo = np.delete(fimo,del_inds,0)

start_pos = 0
hitdict = []
allmotifhits=[]

#t0=time.time()

#here taker all the hits for 1 gene and sort on pval KATES VERSION HAS DONE THIS ALREADY
#take the top k pvals
#calculate binomial value for each
#best (lowest) binomial value, and its pos in this list will be written to binomial thresholds file
#appenb to list of all hits, hits for this gene up to the on with lowest binomial val

#at the end binomial value across all genes are sorted by pval and top N retained
#this last vlaue is appended to the thesholds file

for i in range(1,fimo.shape[0]):
    if (fimo[i,1] != fimo[start_pos,1]):
        print(i)
        #we've found a new gene to test
        
        ###THIS BIT DONE
        motif_hits = fimo[start_pos:i,]
        # extarct top 5 motif hits in this promoter
        motif_hits = motif_hits[np.argsort(motif_hits[:,6])]
        
        
        motif_hits = motif_hits[0:min(args.tar,motif_hits.shape[0]),:] #argument here, tar is k
        binom_p = []
        #how many "flips" will we be making
        motsize = fimo[start_pos,3] - fimo[start_pos,2] + 1
        binom_p = geom_binom_test(motif_hits[:,6],promsize[motif_hits[0,1]],motsize)
        # the minimum value of binom_p indicates how many motif hits should be saved
        hitdict.append([np.min(binom_p),np.argmin(binom_p),fimo[start_pos,0],fimo[start_pos,1]])
        # save top motif hits according to binom_p output
        allmotifhits.extend(motif_hits[range(0,np.argmin(binom_p)+1),:])
        #well, that's a wrap. set it up for the next one
        start_pos = i


#however, at the end, we need to process the last one
motif_hits = fimo[start_pos:,]
# if there is more than one row in the last entry
if (motif_hits.shape[0]!=1):
    motif_hits = motif_hits[np.argsort(motif_hits[:,6])]
    motif_hits = motif_hits[0:min(args.tar,motif_hits.shape[0]),:] #argument here, tar is k
    binom_p = []
    #how many "flips" will we be making
    motsize = fimo[start_pos,3] - fimo[start_pos,2] + 1
    binom_p = geom_binom_test(motif_hits[:,6],promsize[motif_hits[0,1]],motsize)
    # the minimum value of binom_p indicates how many motif hits should be saved
    hitdict.append([np.min(binom_p),np.argmin(binom_p),fimo[start_pos,0],fimo[start_pos,1]])
    # save top motif hits according to binom_p output
    allmotifhits.extend(motif_hits[range(0,np.argmin(binom_p)+1),:])


# d = time.time() - t0
# print("binomial testing: %.2f s." % d)
#write the results out at the end
# visualise binomial scores

# sort dictionary of binomial thresholds by p-value
hitdict.sort(key=lambda x:x[0])
#print(max(hitdict))
# subset top 5000
topN=hitdict[:args.n]
print(max(topN))
topN=np.asarray(topN)

# t0=time.time()
# using genes indicatted in by top n array eaxtract fimo lines

#topN col 3 is gene name
#np.in1d( allmotifhits[:,1], topN[:,3] ) selects genes that appear in topN list
#ie a gene with one of the best N binomial vals
#so we select from all hits, just motif hits on genes with an entry in topN binomial vals
#these written to fimohits file

allmotifhits=np.asarray(allmotifhits)
allmotifhits2=allmotifhits[np.nonzero(np.in1d(allmotifhits[:,1],topN[:,3]))[0],:]
#d = time.time() - t0
# print("extract top n promoters: %.2f s." % d)



# use pandas to write out to file
# t0=time.time()
df = pd.DataFrame(allmotifhits2)
df.to_csv(('fimohits/'+fimo[0,0]+'.txt'),sep='\t',header=False,index=False)
# d = time.time() - t0
# print("write file: %.2f s." % d)

#
writer2 = open('binomial_thresholds.txt','a')
write_threshold_results(writer2,topN)
writer2.close()

#
#
#write(hits[b,0]+'\t'+hits[b,1]+'\t'+str(hits[b,2])+'\t'+str(hits[b,3])+'\t'+hits[b,4]+'\t'+str(hits[b,5])+'\t'+str(hits[b,6])+'\t'+str(hits[b,7])+'\t'+hits[b,8]+'\n')

# #Sam trick again
# if __name__ == "__main__":
#     main()
