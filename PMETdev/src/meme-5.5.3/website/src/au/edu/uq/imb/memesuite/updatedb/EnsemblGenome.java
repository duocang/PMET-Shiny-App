package au.edu.uq.imb.memesuite.updatedb;

import au.edu.uq.imb.memesuite.data.AlphStd;

import java.io.File;

import java.util.*;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class EnsemblGenome extends AbstractFtpSource {
  private int retrieverId;
  private String categoryName;
  private String commonName;
  private String scientificName;
  private AlphStd alphabet;
  private boolean abinitio;
  private String ftpDir;
  private String ftpName;
  private long ftpSize;
  private String host;
  private Pattern[] filePattern;
  private String version;
  private int edition;
  // files
  private File packedFile;
  private File sequenceFile;
  private File bgFile;
  // stats
  private long seqCount;
  private long seqMinLen;
  private long seqMaxLen;
  private double seqAvgLen;
  private double seqStdDLen;
  private long seqTotalLen;
  private Logger logger;

  public EnsemblGenome(String genomeRelease, int retrieverId, 
      String categoryName, String commonName, String scientificName,
      AlphStd alphabet, boolean abinitio, String path, String host, Pattern... filePattern) {
    this.retrieverId = retrieverId;
    this.categoryName = categoryName;
    this.commonName = commonName;
    this.scientificName = scientificName;
    this.alphabet = alphabet;
    this.abinitio = abinitio;
    this.ftpDir = path;
    this.host = host;
    this.filePattern = filePattern;
    version = genomeRelease;
    edition = Integer.parseInt(version, 10);
  }

  public String toString() {
    return "ENSEMBL v" + version + " " + commonName + " (" +
	(abinitio ? "Ab Initio Predicted " : "") + alphabet + ")";
  }

  public Pattern[] getFilePattern() {
    return filePattern;
  }

  @Override
  public String getRemoteHost() {
    return host;
  }

  public String getRemoteDir() {
    return ftpDir;
  }

  public void setRemoteInfo(String ftpName, long ftpSize) {
    this.ftpName = ftpName;
    this.ftpSize = ftpSize;
  }

  @Override
  public String getRemoteExt() {
    String ext;
    if (ftpName.endsWith(".fa.gz")) {
      ext = ".fa.gz";
    } else if (ftpName.endsWith(".tar.gz")) {
      ext = ".tar.gz";
    } else if (ftpName.endsWith(".zip")) {
      ext = ".zip";
    } else {
      ext = super.getRemoteExt();
    }
    return "." + alphabet.toString().toLowerCase() + ext;
  }

  @Override
  public String getRemoteName() {
    return ftpName;
  }

  @Override
  public long getRemoteSize() {
    return ftpSize;
  }

  @Override
  public int getRetrieverId() {
    return retrieverId;
  }

  @Override
  public String getCategoryName() {
    return categoryName;
  }

  @Override
  public String getListingName() {
    return commonName;
  }

  @Override
  public AlphStd guessAlphabet() {
    return alphabet;
  }

  @Override
  public long getSequenceEdition() {
    return edition;
  }

  @Override
  public String getSequenceVersion() {
    return version;
  }

  @Override
  public String getSequenceDescription() {
    String readmeURL = "http://" + getRemoteHost() + getRemoteDir() + "README";
    return "Downloaded from <a href=\"" + getRemoteHttpUrl() + "\">" +
	getRemoteHttpUrl() + "</a>. Refer to the dataset <a href=\"" +
	readmeURL + "\">README file</a> for further details.";
  }

  @Override
  public String getNamePrefix() {
    String name = scientificName;
    name = name.replaceAll("[^a-zA-Z0-9\\p{Z}\\s_\\.-]", "");
    name = name.replaceAll("[\\p{Z}\\s]+", "_");
    return name + "_" + version;
  }

  @Override
  public String getListingDescription() {
    return "Ensembl Protists Genomes - " + commonName + " (<i>" + scientificName + "</i>) - " + version;
  }

  public void setSourceFile(File file) {
    packedFile = file;
  }

  @Override
  public List<File> getSourceFiles() {
    return Collections.singletonList(packedFile);
  }

  @Override
  public void setSequenceFile(File file) {
    sequenceFile = file;
  }

  @Override
  public File getSequenceFile() {
    return sequenceFile;
  }

  @Override
  public void setBgFile(File file) {
    bgFile = file;
  }

  @Override
  public File getBgFile() {
    return bgFile;
  }

  @Override
  public void setStats(long count, long minLen, long maxLen, double avgLen,
      double stdDLen, long totalLen) {
    this.seqCount = count;
    this.seqMinLen = minLen;
    this.seqMaxLen = maxLen;
    this.seqAvgLen = avgLen;
    this.seqStdDLen = stdDLen;
    this.seqTotalLen = totalLen;
  }

  @Override
  public long getSequenceCount() {
    return seqCount;
  }


  @Override
  public long getTotalLength() {
    return seqTotalLen;
  }

  @Override
  public long getMinLength() {
    return seqMinLen;
  }

  @Override
  public long getMaxLength() {
    return seqMaxLen;
  }

  @Override
  public double getAverageLength() {
    return seqAvgLen;
  }

  @Override
  public double getStandardDeviationLength() {
    return seqStdDLen;
  }
}
