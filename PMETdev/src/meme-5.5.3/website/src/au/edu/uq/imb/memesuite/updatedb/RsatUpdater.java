package au.edu.uq.imb.memesuite.updatedb;

import au.edu.uq.imb.memesuite.data.Alph;
import au.edu.uq.imb.memesuite.data.AlphStd;
import au.edu.uq.imb.memesuite.util.JsonWr;
import au.edu.uq.imb.memesuite.util.MultiSourceStatus;
import org.apache.commons.io.IOUtils;
import org.sqlite.SQLiteDataSource;

import java.io.*;
import java.sql.SQLException;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReentrantReadWriteLock;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Pattern;
import java.util.regex.Matcher;

/**
 * Download promoters from RSA Tools for specified groupings.
 */
public class RsatUpdater extends SequenceUpdater {
  private int ageMin;
  private int start;
  private int end;
  private int retain;
  private String categoryName;
  private String dbSubdir;
  private String ftpSubdir;
  private String server;
  private String group;
  private Pattern taxare;
  private Logger logger;

  //private static Logger logger = Logger.getLogger("au.edu.uq.imb.memesuite.updatedb.rsat");
  private static final int RSAT_RETRIEVER_ID = 4;

  public RsatUpdater(String division, SQLiteDataSource dataSource, ReentrantReadWriteLock dbLock,
      File binDir, File dbDir, ExecutorService worker, MultiSourceStatus multiStatus) {
    super("RSAT Upstream Downloader", dataSource, dbLock, binDir, dbDir, worker, multiStatus);

    // Set global group.
    group = division.substring(4);

    // Determine directory for WSDL files.
    String wsdlDir = binDir.getPath().replace("libexec", "share");

    Properties conf = SequenceUpdater.loadConf(RsatUpdater.class, dbDir, "RsatUpdater.properties");
    this.ageMin = getConfInt(conf, "age.min", 0, null, 30);
    this.start = getConfInt(conf, "start", null, null, -1000);
    this.end = getConfInt(conf, "end", null, null, 200);
    this.retain = getConfInt(conf, "retain", 1, null, 1);
    categoryName = conf.getProperty(division + "_categoryName", "unknown_categoryName").trim();
    dbSubdir = conf.getProperty(division + "_dbSubdir", "unknown_dbSubdir").trim();
    ftpSubdir = conf.getProperty(division + "_ftpSubdir", "unknown_ftpSubdir").trim();
    server = wsdlDir + "/" + conf.getProperty(division + "_server", "unknown_server").trim();
    taxare = Pattern.compile(conf.getProperty(division + "_taxa", "unknown_taxa").trim());
    logger = Logger.getLogger("au.edu.uq.imb.memesuite.updatedb.rsat." + ftpSubdir);
    String taxas = conf.getProperty(division + "_taxa", "unknown_taxa").trim();
    logger.log(Level.INFO, "RSAT division: " + division + " taxa: " + taxas);
    logger.log(Level.INFO, "wsdlDir: " + wsdlDir);

  }

  private class StoreErrorMessage extends Thread {
    private InputStream stream;
    private StringBuilder message;
    private boolean done;
    public StoreErrorMessage(InputStream stream) {
      this.stream = stream;
      message = new StringBuilder();
      done = false;
    }
    public void run() {
      BufferedReader in = null;
      try {
        in = new BufferedReader(new InputStreamReader(stream));
        String line;
        while ((line = in.readLine()) != null) {
          message.append(line);
          message.append("\n");
        }
        in.close(); in = null;
      } catch (IOException e) {
        logger.log(Level.SEVERE, "IO error reading output", e);
      } finally {
        synchronized (this) {
          done = true;
          this.notify();
        }
        if (in != null) {
          try {
            in.close();
          } catch (IOException e) {
            //ignore
          }
        }
      }
    }
    public String getMessage() throws InterruptedException {
      synchronized (this) {
        while(!done) {
          this.wait();
        }
      }
      return message.toString();
    }
  }

  private class RsatSupportedOrganisms extends Thread {
    private String serverName;
    private String serverURL;
    private InputStream stream;
    private List<RsatSource> sources;
    private long timestamp;
    private boolean done;
    public RsatSupportedOrganisms(String serverName, String serverURL, InputStream stream) {
      this.serverName = serverName;
      this.serverURL = serverURL;
      this.stream = stream;
      sources = new ArrayList<RsatSource>();
      timestamp = System.currentTimeMillis();
      done = false;
    }
    public void run() {
      BufferedReader in = null;
      //System.out.println("\nIn RsatSupportedOrganisms serverName: " + serverName + " serverURL: " + serverURL + "\n");
      try {
        in = new BufferedReader(new InputStreamReader(stream));
        String line;
        while ((line = in.readLine()) != null) {
          String[] parts = line.trim().split("\\t");
          if (parts.length == 2) {
	    String organism = parts[0];
	    String taxonomy = parts[1];
            String taxon;
	    Pattern pattern = taxare;
	    Matcher matcher = pattern.matcher(taxonomy);
	    if (matcher.find()) {
	      taxon = group;
	      sources.add(new RsatSource(serverName, serverURL, organism, taxon, timestamp, start, end));
	    }
	  }
        }
        in.close(); in = null;
      } catch (IOException e) {
        logger.log(Level.SEVERE, "IO error reading output from rsat-supported-organisms", e);
      } finally {
        synchronized (this) {
          done = true;
          this.notify();
        }
        if (in != null) {
          try {
            in.close();
          } catch (IOException e) {
            //ignore
          }
        }
      }
    }
    public List<RsatSource> getSources() throws InterruptedException {
      synchronized (this) {
        while(!done) {
          this.wait();
        }
      }
      return sources;
    }
  }

  protected List<RsatSource> queryAvailableOrganisms(String serverName, String serverURL) throws IOException, InterruptedException {
    String exe = new File(binDir, "rsat-supported-organisms").getPath();
    ProcessBuilder processBuilder = new ProcessBuilder(exe, "--server", serverURL);
    processBuilder.redirectErrorStream(true);
    Process process = processBuilder.start();
    // log any error message that it outputs
    StoreErrorMessage stderr = new StoreErrorMessage(process.getErrorStream());
    stderr.start();
    // read the organisms that it outputs
    RsatSupportedOrganisms stdout = new RsatSupportedOrganisms(serverName, serverURL, process.getInputStream());
    stdout.start();
    // wait for process to exit
    try {
      process.waitFor();
    } catch (InterruptedException e) {
      // exit ASAP
      process.destroy();
      while (true) {
        try {
          process.waitFor();
          break;
        } catch (InterruptedException e2) {
          // ignore
        }
      }
      throw e;
    }
    // check if we failed
    if (process.exitValue() != 0) {
      //throw new IOException("rsat-supported-organisms failed:\n" + stderr.getMessage());
      logger.log(Level.WARNING, "Failed to retrieve any supported organisms from " + serverURL);
    }
    return stdout.getSources();
  }

  protected boolean downloadSequence(RsatSource source) throws IOException, InterruptedException {
    progress.setTask("Downloading " + source, 0, -1);
    // create the downloads directory if it does not exist
    File downloadDir = new File(dbDir, "downloads");
    if (downloadDir.exists()) {
      if (!downloadDir.isDirectory()) {
        throw new IOException("Unable to create download directory \"" +
            downloadDir + "\" as a file with that name already exists!");
      }
    } else if (!downloadDir.mkdirs()) {
      throw new IOException("Unable to create download directory \"" +
          downloadDir + "\" as the mkdirs command failed!");
    }
    File target = new File(downloadDir, source.getLocalName());
    logger.log(Level.INFO, "Downloading " + source + " from RSAT " + source.getServerName() +
        " to \"" + target + "\".");
    // create a process to download the sequence from RSAT
    String exe = new File(binDir, "rsat-retrieve-seq").getPath();
    ProcessBuilder processBuilder = new ProcessBuilder(exe,
        "--server", source.getServerURL(),
        "--start", Integer.toString(source.getStart()),
        "--end", Integer.toString(source.getEnd()),
        source.getOrganism());
    processBuilder.redirectErrorStream(true);
    Process process = processBuilder.start();
    StoreErrorMessage stderr = new StoreErrorMessage(process.getErrorStream());
    stderr.start();
    // copy the sequence to a file
    Writer out = null;
    try {
      out =  new OutputStreamWriter(new FileOutputStream(target), "UTF-8");
      IOUtils.copy(process.getInputStream(), out);
      out.close();
      out = null;
    } finally {
      if (out != null) {
        try {
          out.close();
        } catch (IOException e) { /* ignore */ }
      }
    }
    // wait for process to exit (since the file stream is closed I'm expecting this to happen right away)
    try {
      process.waitFor();
    } catch (InterruptedException e) {
      // exit ASAP
      process.destroy();
      while (true) {
        try {
          process.waitFor();
          break;
        } catch (InterruptedException e2) {
          // ignore
        }
      }
      throw e;
    }
    // check if we failed
    if (process.exitValue() != 0) {
      logger.log(Level.WARNING, "Failed to retrieve file: " + target);
      if (!target.delete()) logger.log(Level.WARNING, "Failed to cleanup file: " + target);
      //throw new IOException("rsat-retrieve-seq failed:\n" + stderr.getMessage());
      return false;
    }
    // we succeeded so store the file with the rest of the information
    source.setSourceFile(target);
    return true;
  }

  @Override
  public Void call() throws Exception {
    File dbTarget;

    try {
      logger.log(Level.INFO, "categoryName: " + categoryName);

      // Create subdirectory.
      dbTarget = new File(dbDir + "/" + dbSubdir);
      logger.log(Level.INFO, "Creating subdirectory for genomes: " + dbTarget);
      if (!dbTarget.exists() && !dbTarget.mkdir()) {
        logger.log(Level.SEVERE, "Unable to create subdirectory " + dbTarget + "!");
        return null;
      }

      logger.log(Level.INFO, "Querying RSAT " + group + " server at URL " + server);
      List<RsatSource> serverGenomes = queryAvailableOrganisms(group, server);
      if (serverGenomes.isEmpty()) {
	logger.log(Level.WARNING, "Empty supported organism list from RSAT " + group +
	  " at URL " + server);
      } else {
	logger.log(Level.INFO, "RSAT " + group + " at URL " + server + " lists " +
	    serverGenomes.size() + " supported organisms; the last one is " +
	    serverGenomes.get(serverGenomes.size() - 1).getOrganism());
      }
      progress.setTask("Excluding Pre-exisiting " + group + " upstream sequences", 0, -1);
      // Query the database to see which organisms we already have
      // and remove them so we don't download them again.
      long updateDelayMillis = TimeUnit.DAYS.toMillis(ageMin);
      Iterator<RsatSource> iterator = serverGenomes.iterator();
      while (iterator.hasNext()) {
	RsatSource genome = iterator.next();
	if (sourceExists(genome, true, false, updateDelayMillis)) {
	  iterator.remove();
	  logger.log(Level.INFO, "Already updated " + genome + " within " + ageMin + " day(s) ago.");
	}
      }

      for (RsatSource source : serverGenomes) {
	if (Thread.currentThread().isInterrupted()) throw new InterruptedException();
	checkWorkerTasks();
	if (downloadSequence(source)) enqueueSequences(new RsatSequenceProcessor(source, dbTarget));
      }
      progress.complete();
      waitForWorkerTasks();
      logger.log(Level.INFO, "Finished RSAT update");
    } catch (ExecutionException e) { // only thrown by sequence processor
      cancelWorkerTasks();
      logger.log(Level.SEVERE, "Abandoning RSAT update due to failure to process sequences!", e);
    } catch (SQLException e) {
      logger.log(Level.SEVERE, "Abandoning RSAT update!", e);
    } catch (IOException e) {
      logger.log(Level.SEVERE, "Abandoning RSAT update!", e);
    } catch (InterruptedException e) {
      logger.log(Level.WARNING, "RSAT update interrupted!");
    } catch (RuntimeException e) {
      logger.log(Level.SEVERE, "RuntimeException!", e);
      throw e;
    } catch (Error e) {
      logger.log(Level.SEVERE, "Error!", e);
      throw e;
    } finally {
      progress.complete();
    }
    return null;
  }

  private class RsatSequenceProcessor extends SequenceProcessor {
    private RsatSource source;
    private File dbTarget;

    public RsatSequenceProcessor(RsatSource source, File dbTarget) {
      super(dataSource, dbLock, binDir, dbDir, status);
      this.source = source;
      this.dbTarget = dbTarget;
    }

    private void moveSequence(RsatSource source, File dbTarget) throws IOException {
      File sourceFile = source.getSourceFiles().get(0);
      File sequenceFile = new File(dbTarget, source.getLocalName());
      if (!sourceFile.renameTo(sequenceFile)) {
        throw new IOException("Failed to rename \"" + sourceFile +
            "\" to \"" + sequenceFile + "\"");
      }
      source.setSequenceFile(sequenceFile);
    }

    @Override
    public void process() throws IOException, SQLException, InterruptedException {
      moveSequence(source, dbTarget);
      processSequences(source, dbTarget);
      obsoleteOldEditions(recordSequences(source, dbTarget, dbSubdir).listingId, source.guessAlphabet(), retain);
    }
  }

  private static class RsatSource implements Source {
    private String serverName;
    private String serverURL;
    private String organism;
    private String taxon;
    private int start;
    private int end;
    private long timestamp;
    private File sourceFile;
    private File sequenceFile;
    private File bgFile;
    private long seqCount;
    private long seqMinLen;
    private long seqMaxLen;
    private double seqAvgLen;
    private double seqStdDLen;
    private long seqTotalLen;

    public RsatSource(String serverName, String serverURL, String organism, String taxon, long timestamp, int start, int end) {
      this.serverName = serverName;
      this.serverURL = serverURL;
      this.organism = organism;
      this.taxon = taxon;
      this.timestamp = timestamp;
      this.start = start;
      this.end = end;
    }

    public String toString() {
      return "RSAT " + organism.replace('_', ' ') + " (Upstream " + start + " to " + end + ")";
    }

    public String getServerName() {
      return serverName;
    }

    public String getServerURL() {
      return serverURL;
    }

    public String getOrganism() {
      return organism;
    }

    public int getStart() {
      return start;
    }

    public int getEnd() {
      return end;
    }

    @Override
    public int getRetrieverId() {
      return RSAT_RETRIEVER_ID;
    }

    @Override
    public String getCategoryName() {
      return "Upstream Sequences: " + taxon.substring(0,1).toUpperCase() + taxon.substring(1);
    }

    @Override
    public String getListingName() {
      return organism.replace('_', ' ');
    }

    @Override
    public String getListingDescription() {
      String name = organism.replace('_', ' ');
      return "Upstream sequences (" + start + " to " + end + ") for <i>" + name + "</i>";
    }

    @Override
    public AlphStd guessAlphabet() {
      return AlphStd.DNA;
    }

    @Override
    public boolean checkAlphabet(Alph alph) {
      return guessAlphabet().getAlph().equals(alph);
    }

    @Override
    public long getSequenceEdition() {
      return timestamp;
    }

    @Override
    public String getSequenceVersion() {
      return DateFormat.getDateInstance(DateFormat.MEDIUM).format(new Date(timestamp));
    }

    @Override
    public String getSequenceDescription() {
      String when = DateFormat.getDateInstance(DateFormat.MEDIUM).format(new Date(timestamp));
      return "Downloaded from Regulatory Sequence Analysis Tools " + serverName +
          " retrieve_seq webservice retrieved on " + when + ".";
    }

    @Override
    public String getNamePrefix() {
      SimpleDateFormat df = new SimpleDateFormat("yyyy-MM-dd");
      String when = df.format(new Date(timestamp));
      return "upstream_" + start + "_" + end + "_" + organism + "_" + when;
    }

    public void setSourceFile(File file) {
      this.sourceFile = file;
    }

    @Override
    public List<File> getSourceFiles() {
      return Collections.singletonList(sourceFile);
    }

    public String getLocalName() {
      return getNamePrefix() + ".fna";
    }

    public void setSequenceFile(File sequenceFile) {
      this.sequenceFile = sequenceFile;
    }

    public File getSequenceFile() {
      return sequenceFile;
    }

    public void setBgFile(File bgFile) {
      this.bgFile = bgFile;
    }

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

    @Override
    public void outputJson(JsonWr out) throws IOException {
      out.value((JsonWr.JsonValue)null);
    }
  }
}
