package au.edu.uq.imb.memesuite.io.fasta;

public class BedException extends Exception {
  public BedException() {
    super();
  }

  public BedException(String message) {
    super(message);
  }

  public BedException(String message, Throwable cause) {
    super(message, cause);
  }

  public BedException(Throwable cause) {
    super(cause);
  }
}

