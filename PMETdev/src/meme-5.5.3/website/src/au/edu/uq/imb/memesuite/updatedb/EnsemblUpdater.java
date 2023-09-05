package au.edu.uq.imb.memesuite.updatedb;

import au.edu.uq.imb.memesuite.util.MultiSourceStatus;

import org.apache.commons.net.PrintCommandListener;
import org.apache.commons.net.ftp.FTPClient;
import org.apache.commons.net.ftp.FTPFile;
import org.sqlite.SQLiteDataSource;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.util.*;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.ReentrantReadWriteLock;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * This updates the given Ensembl database division.
 */
public class EnsemblUpdater extends SequenceUpdater {
  private String rest_host;
  private String seq_host;
  private String ftpLog;
  private int retrieverId;
  private String Division;
  private boolean abinitio;
  private String categoryName;
  private String restSubdir;
  private String dbSubdir;
  private String ftpSubdir;
  private Logger logger;

  private Map<String, String> name2Subdir;

  private static final Pattern NUM_RE = Pattern.compile("^release-(\\d+)$");
  private static final Pattern ABINITIO_RE = Pattern.compile("^.*abinitio$");

  public EnsemblUpdater(String division, SQLiteDataSource dataSource,
      ReentrantReadWriteLock dbLock, File binDir, File dbDir,
      ExecutorService worker, MultiSourceStatus statusManager) {
    super("Ensembl Updater", dataSource, dbLock, binDir, dbDir, worker, statusManager);
    Division = division;

    // Get the common properties.
    Properties conf = loadConf(EnsemblUpdater.class, dbDir, "EnsemblUpdater.properties");
    rest_host = conf.getProperty("rest_host", "ftp.ebi.ac.uk").trim();
    Matcher m = ABINITIO_RE.matcher(Division);
    abinitio = m.matches();
    if (Division.equals("ensemblvertebrates") || Division.equals("ensemblvertebratesabinitio")) {
      seq_host = conf.getProperty("vert_host", "ftp.ensembl.org").trim();
    } else {
      seq_host = conf.getProperty("other_host", "ftp.ensemblgenomes.org").trim();
    }
    ftpLog = conf.getProperty("ftp.log", "").trim();
    // Get the properties specific to this division.
    retrieverId = Integer.valueOf(conf.getProperty(division + "_retrieverId", "3").trim());
    categoryName = conf.getProperty(division + "_categoryName", "unknown_categoryName").trim();
    restSubdir = conf.getProperty(division + "_restSubdir", "unknown_restSubdir").trim();
    dbSubdir = restSubdir + (abinitio ? "Abinitio" : "");
    ftpSubdir = conf.getProperty(division + "_ftpSubdir", "unknown_ftpSubdir").trim();
    logger = Logger.getLogger("au.edu.uq.imb.memesuite.updatedb.ensembl." + ftpSubdir);
    logger.log(Level.INFO, "Ensembl division: " + division);
  }

  @Override
  public Void call() {
    int errorCount = 0;
    FTPClient rest_ftp = null;
    FTPClient seq_ftp = null;
    File dbTarget;
    int genomeRelease = 0;

    try {
      logger.log(Level.INFO, "categoryName: " + categoryName);

      // Create subdirectory.
      dbTarget = new File(dbDir + "/" + dbSubdir);
      logger.log(Level.INFO, "Creating subdirectory for genomes: " + dbTarget);
      if (!dbTarget.exists() && !dbTarget.mkdir()) {
        logger.log(Level.SEVERE, "Unable to create subdirectory " + dbTarget + "!");
        return null;
      }

      // Login to Ensembl REST FTP site.
      rest_ftp = new FTPClient();
      if (!ftpLog.isEmpty()) {
        rest_ftp.addProtocolCommandListener(new PrintCommandListener(new PrintWriter(new FileOutputStream(ftpLog)), true));
      }
      if (!loginFtp(rest_ftp, rest_host)) return null;

      // Login to Ensembl sequences FTP site.
      seq_ftp = new FTPClient();
      if (!ftpLog.isEmpty()) {
	seq_ftp.addProtocolCommandListener(new PrintCommandListener(new PrintWriter(new FileOutputStream(ftpLog)), true));
      }
      if (!loginFtp(seq_ftp, seq_host)) return null;

      // Get the current Ensembl Genome Release number (differs from Ensembl release number).
      progress.setTask("Getting current Ensembl Genome Release number", 0, -1);
      FTPFile[] directories = rest_ftp.listDirectories("/ensemblgenomes/pub");
      for (FTPFile dir : directories) {
        Matcher m = NUM_RE.matcher(dir.getName());
        if (!m.matches()) continue;
        int rel = Integer.parseInt(m.group(1), 10);
        if (rel > genomeRelease) genomeRelease = rel;
      }
      rest_ftp.logout();
      rest_ftp.disconnect();

      // Get paths to genomes in this Ensembl division.
      progress.setTask("Getting paths to genomes in this division for genome release " + genomeRelease, 0, -1);
      String rootDir;
      if (Division.equals("ensemblvertebrates") ||Division.equals("ensemblvertebratesabinitio")) { 
        rootDir = "/pub/current_fasta/";
      } else {
	rootDir = "/pub/release-" + genomeRelease + "/" + ftpSubdir + "/fasta/";
      }
      name2Subdir = makeMapName2Subdir(seq_ftp, rootDir);
      Set set=name2Subdir.entrySet();	// Converting to Set so that we can traverse  
      Iterator itr=set.iterator();  
      while(itr.hasNext()){  
	// Converting to Map.Entry so that we can get key and value separately  
	Map.Entry entry=(Map.Entry)itr.next();  
      }

      // Get the list of available genomes.
      List<EnsemblGenome> genomes = ensemblAvailableGenomes(String.valueOf(genomeRelease), abinitio, retrieverId, categoryName, seq_host, rootDir, restSubdir, name2Subdir);
      if (genomes.isEmpty()) {
        logger.log(Level.SEVERE, "Failed parsing the genome releases using the Ensembl REST interface... No genomes found!");
        return null;
      }

      // Query the database to see which genomes we already have
      // and remove them so we don't download them again
      progress.setTask("Excluding Pre-exisiting Genomes", 0, -1);
      int navailable_genomes = 0;
      int nremoved_genomes = 0;
      Iterator<EnsemblGenome> iterator = genomes.iterator();
      while (iterator.hasNext()) {
        EnsemblGenome genome = iterator.next();
        navailable_genomes++;
        if (sourceExists(genome, true)) {
          iterator.remove();
          logger.log(Level.INFO, "Already have " + genome);
          nremoved_genomes++;
        }
      }
      logger.log(Level.INFO, "Number of AVAILABLE genomes: " + navailable_genomes);
      logger.log(Level.INFO, "Number of genomes to UPDATE: " + (navailable_genomes - nremoved_genomes));
      if (genomes.isEmpty()) return null;

      for (EnsemblGenome genome : genomes) {
        try {
          checkWorkerTasks();
          if (!determineFtpSource(rest_host, seq_ftp, genome, RETRY_COUNT)) continue;
          checkWorkerTasks();
          if (!downloadFtpSource(seq_ftp, genome, true, RETRY_COUNT)) continue;
          enqueueSequences(new EnsemblSequenceProcessor(genome, dbTarget));
        } catch (IOException e) {
          logger.log(Level.WARNING, "Skipped " + genome + " due to ftp errors", e);
          errorCount++;
          if (errorCount >= ERROR_COUNT) throw new IOException("Too many IO Exceptions", e);
        }
      }
      seq_ftp.logout();
      seq_ftp.disconnect();
      progress.complete();
      waitForWorkerTasks();
      logger.log(Level.INFO, "Finished update of " + categoryName);
    } catch (ExecutionException e) { // only thrown by sequence processor
      cancelWorkerTasks();
      logger.log(Level.SEVERE, "Abandoning update of " + dbSubdir + " due to failure to process sequences!", e);
    } catch (SQLException e) {
      logger.log(Level.SEVERE, "Abandoning update of " + dbSubdir + "!", e);
    } catch (IOException e) {
      logger.log(Level.SEVERE, "Abandoning update of " + dbSubdir + "!", e);
    } catch (InterruptedException e) {
      logger.log(Level.WARNING, "Update of " + dbSubdir + " was interrupted!");
    } catch (RuntimeException e) {
      logger.log(Level.SEVERE, "RuntimeException!", e);
      throw e;
    } catch (Error e) {
      logger.log(Level.SEVERE, "Error!", e);
      throw e;
    } finally {
      if (seq_ftp != null && seq_ftp.isConnected()) {
        try {
          seq_ftp.logout();
        } catch (IOException e) { /* ignore */ }
        try {
          seq_ftp.disconnect();
        } catch (IOException e) { /* ignore */ }
      }
      progress.complete();
    }
    return null;
  }

  private class EnsemblSequenceProcessor extends SequenceProcessor {
    private EnsemblGenome genome;
    private File dbTarget;

    public EnsemblSequenceProcessor(EnsemblGenome genome, File dbTarget) {
      super(dataSource, dbLock, binDir, dbDir, status);
      this.genome = genome;
      this.dbTarget = dbTarget;
    }

    @Override
    public void process() throws IOException, SQLException, InterruptedException {
      if (!unpackSequences(genome, dbTarget)) return;
      processSequences(genome, dbTarget);
      recordSequences(genome, dbTarget, dbSubdir);
    }
  }

}
