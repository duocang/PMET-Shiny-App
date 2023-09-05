package au.edu.uq.imb.memesuite.io.fasta;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.io.IOException;
import java.util.HashMap;


public class FastaIndexParser {

  public static HashMap<String, Long> parse(String indexFile) throws FastaIndexException {
    
    HashMap<String, Long> fastaIndex = new HashMap<String, Long>();

    try {
      BufferedReader br = new BufferedReader(new FileReader(indexFile));
      String line;
      long lineNumber = 0;
      while ((line = br.readLine()) != null) {
        lineNumber += 1;
        if (line.charAt(0) == '#') {
          continue;
        }
        String[] values = line.split("\t");
        if (values.length != 5) {
          throw new FastaIndexException(
            "Error trying to read sequence index file " + indexFile + 
            ": line " + lineNumber + " has " + values.length + " fields, " +
            " should have 5."
          );
        }
        String chrom = values[0];
        Long length;
        try {
          length = Long.parseLong(values[1]);
        } catch (NumberFormatException e) {
          throw new FastaIndexException(
            "Error trying to read sequence index file " + indexFile + 
            ": line " + lineNumber + ", 2nd field (length) must be a positive integer, was " + values[1] + "."
          );
        }
        if (length < 0) {
          throw new FastaIndexException(
            "Error trying to read sequence index file " + indexFile + 
            ": line " + lineNumber + ", 2nd field (length) must be a positive integer, was " + length + "."
          );
        }
        fastaIndex.put(chrom, length);
      }
    }
    catch (IOException e) {
          throw new FastaIndexException(
            "Error trying to read sequence index file " + indexFile + ": " + e.toString()
          );
    }
    return fastaIndex;
  }
}
