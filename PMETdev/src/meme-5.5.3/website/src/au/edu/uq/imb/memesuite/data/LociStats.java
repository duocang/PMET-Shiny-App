package au.edu.uq.imb.memesuite.data;

import au.edu.uq.imb.memesuite.util.JsonWr;
import au.edu.uq.imb.memesuite.util.SampleStats;

import java.io.IOException;
import java.util.Arrays;
import java.util.Collection;

/**
 * Calculate statistics on the loci
 */
public class LociStats extends SequenceStats implements SequenceInfo, LociInfo {

  /**
   * Class constructor
   */
  public LociStats() {
    super();
  }

  /**
   * Process the sequence and update the statistics
   * @param sequence the complete sequence
   * @see #addSeqPart(CharSequence)
   * @see #endSeq()
   */
  public void addSeq(long length) {
    stats.update(length);
  }

  /**
   * Return the total count of loci
   * @return The total count of loci
   */
  public long getLociCount() {
    return stats.getCount();
  }

  @Override
  public void outputJson(JsonWr out) throws IOException {
    out.startObject();
    out.property("type", "loci");
    out.property("count", getLociCount());
    out.property("min", getMinLength());
    out.property("max", getMaxLength());
    out.property("avg", getAverageLength());
    out.property("total", getTotalLength());
    out.endObject();
  }
}
