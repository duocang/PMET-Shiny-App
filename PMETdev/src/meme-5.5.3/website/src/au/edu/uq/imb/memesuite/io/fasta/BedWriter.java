package au.edu.uq.imb.memesuite.io.fasta;

import au.edu.uq.imb.memesuite.data.LociStats;
import au.edu.uq.imb.memesuite.servlet.util.FeedbackHandler;

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.util.HashMap;
import java.math.BigDecimal;
import java.nio.charset.Charset;


public class BedWriter {
  private FileWriter out;
  private LociStats stats;

  public BedWriter(FileWriter output) {
    this.out = output;
    this.stats = new LociStats();
  }

  public void setStatsRecorder(LociStats stats) {
    this.stats = stats;
  }

  public LociStats getStatsRecorder() {
    return stats;
  }


  public void checkAndCopyBedFile(FeedbackHandler feedback, String indexPath, BufferedReader in) 
    throws BedException, FastaIndexException {

      // Read sequences index for genome
      HashMap<String, Long> fastaIndex = null;
      fastaIndex = FastaIndexParser.parse(indexPath);
      try {
        String line = in.readLine();
        long lociCount = 0;
        long lociLength = 0;
        long lineCount = 1;
        while (line != null) {
          ++lineCount;
          out.write(line + System.lineSeparator());
          lociLength = checkBEDFormat(line, lineCount, fastaIndex);
          stats.addSeq(lociLength);
          ++lociCount;
          line = in.readLine();
        }
      }
      catch (IOException e) {
        String message = "Error writing BED file: " + e.toString();
        throw new BedException(message);
      }
  }

  public void error(BedException e) throws BedException {
    throw e;
  }

  private long checkBEDFormat(String line, long lineNumber, HashMap<String, Long> fastaIndex) throws BedException {
    String[] fields = line.split("\t");
    if (fields.length < 3 || fields.length > 12) {
      String message = "BED format error at line " + lineNumber + ": found " + fields.length + 
        " fields. The number of fields should be 3 to 11.";
      throw new BedException(message);
    }
    String sequenceName = fields[0];
    Long start = Long.parseLong(fields[1]);
    Long end = Long.parseLong(fields[2]);
    Long seqLength = fastaIndex.get(sequenceName);
    if (seqLength == null) {
      String message = "BED format error at line " + lineNumber + ": the sequence " + sequenceName + 
        " was not found in the sequence file.";
      throw new BedException(message);
    }
    if (start <= 0) {
      String message = "BED format error at line " + lineNumber + ": starting coordinate for " + sequenceName + 
        " was less than 0 (" + start + ").";
      throw new BedException(message);
    }
    if (end <= 0) {
      String message = "BED format error at line " + lineNumber + ": ending coordinate for " + sequenceName + 
        " was less than 0 (" + end + ").";
      throw new BedException(message);
    }
    if (start > seqLength) {
      String message = "BED format error at line " + lineNumber + ": starting coordinate of " + start + 
        " for sequence " + sequenceName + " was greater than it's length (" + seqLength + ").";
      throw new BedException(message);
    }
    if (end > seqLength) {
      String message = "BED format error at line " + lineNumber + ": ending coordinate of " + end +
        " for sequence " + sequenceName + " was greater than it's length (" + seqLength + ").";
      throw new BedException(message);
    }
    return (end - start);
  }
}
