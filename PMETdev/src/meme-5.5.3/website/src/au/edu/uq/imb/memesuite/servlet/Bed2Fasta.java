package au.edu.uq.imb.memesuite.servlet;

import au.edu.uq.imb.memesuite.data.*;
import au.edu.uq.imb.memesuite.db.SequenceDB;
import au.edu.uq.imb.memesuite.servlet.util.*;
import au.edu.uq.imb.memesuite.template.HTMLSub;
import au.edu.uq.imb.memesuite.template.HTMLTemplate;
import au.edu.uq.imb.memesuite.util.FileCoord;
import au.edu.uq.imb.memesuite.util.JsonWr;

import java.io.*;
import java.util.*;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.activation.DataSource;
import javax.servlet.*;
import javax.servlet.http.*;

public class Bed2Fasta extends SubmitJob<Bed2Fasta.Data> {
  private HTMLTemplate tmplMain;
  private HTMLTemplate tmplVerify;
  private ComponentHeader header;
  private ComponentSequences sequences;
  private ComponentJobDetails jobDetails;
  private ComponentSubmitReset submitReset;
  private ComponentFooter footer;

  private static Logger logger = Logger.getLogger("au.edu.uq.imb.memesuite.web.bed2fasta");
  
  protected class Data extends SubmitJob.JobData {
    public String email;
    public String description;
    public SequenceInfo loci;

    @Override
    public void outputJson(JsonWr out) throws IOException {
      out.startObject();
      out.property("bedfile", loci);
      out.property("sequences", loci);
      out.property("genome", loci);
      out.endObject();
    }

    @Override
    public String email() {
      return email;
    }
  
    @Override
    public String description() {
      return description;
    }

    @Override
    public String emailTemplate() {
      return tmplVerify.getSubtemplate("message").toString();
    }
  
    @Override
    public String cmd() {
    //    bed2fasta_webservice <loci> <db seqs>
    //
      StringBuilder args = new StringBuilder();
      addArgs(args, ((LociDataSource)loci).getName());
      addArgs(args, ((LociDataSource)loci).getGenomeFileName());
      return args.toString();
    }
  
    @Override
    public List<DataSource> files() {
      ArrayList<DataSource> list = new ArrayList<DataSource>();
      if (loci != null) list.add((LociDataSource)loci);
      return list;
    }
  
    @Override
    public boolean immediateRun() {
      return false;
    }
  
    @Override
    public void cleanUp() {
      if (loci != null) {
        if (!((LociDataSource)loci).getFile().delete()) {
          logger.log(Level.WARNING, "Unable to delete temporary file " + ((LociDataSource)loci).getFile());
        }
      }
    }
  }

  public Bed2Fasta() {
    super("BED2FASTA", "BED2FASTA");
  }

  @Override
  public void init() throws ServletException {
    super.init();
    // load the templates
    tmplMain = cache.loadAndCache("/WEB-INF/templates/bed2fasta.tmpl");
    tmplVerify = cache.loadAndCache("/WEB-INF/templates/bed2fasta_verify.tmpl");
    header = new ComponentHeader(cache, msp.getVersion(), tmplMain.getSubtemplate("header"));
    sequences = new ComponentSequences(context, tmplMain.getSubtemplate("sequences"));
    jobDetails = new ComponentJobDetails(cache);
    submitReset = new ComponentSubmitReset(cache, jobTable.getCount(), jobTable.getDuration());
    footer = new ComponentFooter(cache, msp);
  }

  @Override
  public String title() {
    return tmplVerify.getSubtemplate("title").toString();
  }

  @Override
  public String subtitle() {
    return tmplVerify.getSubtemplate("subtitle").toString();
  }

  @Override
  public String logoPath() {
    return tmplVerify.getSubtemplate("logo").toString();
  }

  @Override
  public String logoAltText() {
    return tmplVerify.getSubtemplate("alt").toString();
  }

  @Override
  protected void displayForm(HttpServletRequest request, HttpServletResponse response, long quotaMinWait) throws IOException {
    HTMLSub main = tmplMain.toSub();
    main.set("help", new HTMLSub[]{header.getHelp(),
        sequences.getHelp(), jobDetails.getHelp(), submitReset.getHelp(), footer.getHelp()});
    main.set("header", header.getComponent());
    main.set("sequences", sequences.getComponent());
    main.set("job_details", jobDetails.getComponent());
    main.set("submit_reset", submitReset.getComponent(quotaMinWait));
    main.set("footer", footer.getComponent());
    response.setContentType("text/html; charset=UTF-8");
    main.output(response.getWriter());
  }

  @Override
  protected Data checkParameters(FeedbackHandler feedback,
      HttpServletRequest request) throws IOException, ServletException {
    FileCoord namer = new FileCoord();
    FileCoord.Name bedFileName = namer.createName("loci.bed");
    // setup default file names
    namer.createName("description");
    namer.createName("uuid");
    Alph alph = null;
    Data data = new Data();
    // get the job details
    data.email = jobDetails.getEmail(request, feedback);
    data.description = jobDetails.getDescription(request);
    // get the BED info
    data.loci = sequences.getSequences(bedFileName, request, feedback);
    return data;
  }
}

