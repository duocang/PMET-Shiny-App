package au.edu.uq.imb.memesuite.data;

import au.edu.uq.imb.memesuite.db.*;
import au.edu.uq.imb.memesuite.util.FileCoord;
import au.edu.uq.imb.memesuite.util.JsonWr;

import java.io.File;
import java.io.IOException;

/**
 * This class describes a loci file as a data source
 */
public class LociDataSource extends SequenceDataSource implements LociInfo, SequenceInfo {
  private LociStats stats;
  private SequenceDB fileDB;

  /**
   * Create a loci data source from a file, the name of the file that the
   * submitter used and some basic information about the locis in the file.
   */
  public LociDataSource(File file, FileCoord.Name name,
      LociStats stats) {
    super(file, name, stats);
    this.stats = stats;
  }

  public LociDataSource(File file, FileCoord.Name name, 
    SequenceDB fileDB, LociStats stats) {
    super(file, name, stats);
    this.fileDB = fileDB;
    this.stats = stats;
  }

  public String getGenomeFileName() {
    return fileDB.getSequenceName();
  }

  public String getGenomeIndexFileName() {
    return fileDB.getSeqIndexName();
  }

  public String getGenomeListingName() {
    return fileDB.getListingName();
  }

  public String getGenomeVersion() {
    return fileDB.getVersion();
  }

  public long getLociCount() {
    if (stats != null) {
      return this.stats.getLociCount();
    }
    else {
      return 0;
    }
  }

  @Override
  public AlphStd guessAlphabet() {
    return fileDB.guessAlphabet();
  }

  @Override
  public boolean checkAlphabet(Alph alph) {
    return true;
  }

  @Override
  public void outputJson(JsonWr out) throws IOException {
    out.startObject();
    if (getOriginalName() != null) {
      out.property("source", "file");
      out.property("safe-file", getName());
      out.property("orig-file", getOriginalName());
    } else {
      out.property("source", "text");
    }
    out.property("genome", getGenomeListingName() + " " + getGenomeVersion() 
      + " (" + getGenomeFileName() + ")");
    out.property("alphabet", guessAlphabet().getAlph());
    out.property("count", getSequenceCount());
    out.property("min", getMinLength());
    out.property("max", getMaxLength());
    out.property("avg", getAverageLength());
    out.property("total", getTotalLength());
    out.endObject();
  }
}
