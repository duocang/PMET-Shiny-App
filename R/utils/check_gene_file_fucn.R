# Check the validity of a gene file
# Parameters:
#   - gene_file_size: Size of the gene file
#   - gene_file_path: Path to the gene file
#   - motif_db: Motif database
#   - mode: Sequence type mode ("intervals", "promoters_pre", "promoters")
# Returns:
#   - "no_content": If the gene file is empty or the file path is not provided
#   - "gene_wrong_format": If the gene file cannot be read
#   - "wrong_column": If the gene file does not have two columns
#   - "intervals_wrong_format": If the gene file contains invalid intervals (format should be "1:start-end")
#   - "no_valid_genes": If no valid genes are available in the uploaded file
#   - List(nrow(genes_skipped), nrow(genes_uploaded), genes_skipped): If there

CheckGeneFile <- function(gene_file_size = NULL, gene_file_path = NULL, motif_db = NULL, mode = NULL) {

  if (gene_file_size== 0 |is.null(gene_file_path) )
    return("no_content")

  # read gene file uploaded
  genes_uploaded <- tryCatch({
      read.table(gene_file_path)},
    error = function(e) {
      return(NULL)
  })

  if (is.null(genes_uploaded))
    return("gene_wrong_format")

  if (ncol(genes_uploaded) != 2)
    return("wrong_column")

  colnames(genes_uploaded) <- c("cluster", "gene")
  # Perform checks based on the sequence type
  switch(mode,
    "intervals" = {
      pattern <- "^1:\\d+-\\d+$" # # Define the pattern for valid interval format
      num_invalid_intervals <- (!grepl(pattern, genes_uploaded[, "gene"])) %>% sum()
      if (num_invalid_intervals != 0) {
        return("intervals_wrong_format")
      } else {
        return("OK")
      }
    },
    "promoters_pre" = {
        # if motifs selected, check the uploaded genes with the gene list in our folder, named universe.txt
        genes_universe <- file.path("data/PMETindex",
                                    str_split(motif_db, "-")[[1]][1],
                                    motif_db, "universe.txt") %>% read.table() %>% `colnames<-`(c("gene"))

        genes_present <-  dplyr::inner_join(genes_uploaded, genes_universe, by = "gene")
        genes_skipped <- setdiff(genes_uploaded, genes_present)

        # no genes available in the uploaded file
        if (nrow(genes_skipped) == nrow(genes_uploaded)) {
          return("no_valid_genes")
        } else if (nrow(genes_uploaded) != nrow(genes_present)) {
          return(list(nrow(genes_skipped), nrow(genes_uploaded), genes_skipped))
        } else {
          return("OK")
        }
    },
    "promoters" = {
      return("OK")
    }) # end of switch
}