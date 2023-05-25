#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Apr 27 12:40:03 2018
Calculate IC for motifs and save as dictionary - to be imported into colocalisationTest.py in PMET_tool
@author: lfuler
"""
import numpy as np
import math
import os
import re
import pickle
import csv

def getMotifLength(memefile):
    '''
    Works out the motif length from the meme file using regex to work out what number comes after 'w='
    returns an integer
    '''
    for i in range(len(memefile)):
        if memefile[i].find('letter-probability matrix')>-1:
            match=re.search('w= (\d+)',k[i])
            motif_length = int(match.group(1))
    return(motif_length)

def extractMatrixfromMeme(memefile,motif_length):
    '''
    extract matrix from awkward meme files. returns as np.array
    '''
    #work out where the matrix starts
    for i in range(len(memefile)):
        if memefile[i].find('letter-probability matrix')>-1:
            mat_start = i + 1
            mat_end = mat_start + motif_length
    # extract the lines with the letter-probability matrix
    mat = memefile[mat_start:mat_end]
    #all the reformatting
    for j in range(0,mat.shape[0]):
        thing = mat[j]
        newthing = thing.replace(" ","")
        newthing = newthing.replace("\n","")
        newthing = newthing.split('\t')
        newthing = newthing[0:4]
        if j==0:
            new_mat = np.asarray(newthing)
        else:
            new_mat = np.append(new_mat,newthing)
    #reformat strings to numbers (floats)
    new_list = [float(num) for num in new_mat]
    final_mat = np.asarray(new_list)
    #make it the right shape again
    final_mat = final_mat.reshape((motif_length,4))
    return(final_mat)

def calculateIC(meme_as_matrix):
    '''
    calculates the information content for each row of the motif matrix output from extractMatrixfromMeme
    returns as list.
    '''
    meme=meme_as_matrix
    motif_length=meme.shape[0]
    IC_vec = [None]*motif_length
    if np.isnan(meme).any():
        # np.nansum is slow compared to sum, so only use it when nans have been
        #introduced to the meme matrix
        # calculate fwd IC for each position
        for i in range(0,motif_length):
            meme_row_no_zeros = [j for j in meme[i,:] if j !=0]
            IC_vec[i] = 2 + np.nansum([x*math.log2(x) for x in meme_row_no_zeros])
    else:
        for i in range(0,motif_length):
            # remove any zeros from the row that we are looking at, zeros throw a math error in the subsequent line because of the log2
            meme_row_no_zeros = [j for j in meme[i,:] if j !=0]
            IC_vec[i] = 2 + sum([x*math.log2(x) for x in meme_row_no_zeros])
    return(IC_vec)

if __name__ == "__main__":
        #memefiles = os.listdir((args.pathToIndex+'/memefiles'))
    memefiles = os.listdir(('memefiles'))
    # remove (invisible) dot files from list
    memefiles = [f for f in memefiles if not f[0] == '.']

    IC_dict={}
    # GC_content={}
    for file in memefiles:
        #print(file)
        # read in the file
        with open('memefiles/'+file) as w:
            k = np.asarray(w.readlines())
        # calculate length and extarct meme matrix
        mot_length=getMotifLength(k)
        meme=extractMatrixfromMeme(k,mot_length)
        IC=calculateIC(meme)
        # save each IC list in dictionary
        IC_dict[file.replace('.txt','')]=IC
        # calculate GC content
        # mean_base=np.mean(meme, axis=0)
        # GC_content[file.replace('.txt','')]=mean_base[1]+mean_base[2]

    with open('ICdict.pickle', 'wb') as handle:
        pickle.dump(IC_dict, handle, protocol=pickle.HIGHEST_PROTOCOL)
