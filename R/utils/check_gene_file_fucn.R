# Check the validity of a gene file
# Parameters:
#   - gene_file_path: Path to the gene file
#   - premade: Motif database
#   - mode: Sequence type mode ("intervals", "promoters_pre", "promoters")
# Returns:
#   - "NO_CONTENT": If the gene file is empty or the file path is not provided
#   - "GENE_WRONG_FORMAT": If the gene file cannot be read
#   - "WORNG_COLUMN_NUMBER": If the gene file does not have two columns
#   - "intervals_wrong_format": If the gene file contains invalid intervals (format should be "1:start-end")
#   - "no_valid_genes": If no valid genes are available in the uploaded file
#   - List(nrow(genes_not_found), nrow(genes_uploaded), genes_not_found): If there

CheckGeneFile <- function(gene_file_path = NULL, mode = NULL, premade = NULL) {

  if (is.null(gene_file_path)) {
    return("NO_FILE")
  }

  if(file.info(gene_file_path)$size == 0) {
    return("NO_CONTENT")
  }

  # read gene file uploaded
  genes_uploaded <- tryCatch({
      read.table(gene_file_path)},
    error = function(e) {
      return(NULL)
  })

  if (is.null(genes_uploaded))
    return("GENE_WRONG_FOMRAT")

  if (ncol(genes_uploaded) != 2)
    return("WORNG_COLUMN_NUMBER")

  colnames(genes_uploaded) <- c("cluster", "gene")
  # Perform checks based on the sequence type
  switch(mode,
    "intervals" = {
      # valid_rows <- grep("^\\d+_\\d+-\\d+$", genes_uploaded[, "gene"], invert = FALSE)  # 使用正则表达式匹配符合格式的行
      # if (length(valid_rows) != nrow(genes_uploaded)) {
      #   return("intervals_wrong_format")
      # } else {
      #   return("OK")
      # }
      return("OK")
    },
    "promoters_pre" = {
      # if motif DB selected, check the uploaded genes with the gene list in our folder, named universe.txt
      genes_universe <- file.path(premade, "universe.txt") %>% read.table() %>% `colnames<-`(c("gene"))

      genes_present <-  dplyr::inner_join(genes_uploaded, genes_universe, by = "gene")
      genes_not_found <- setdiff(genes_uploaded, genes_present)

      # no genes available in the uploaded file
      if (nrow(genes_not_found) == nrow(genes_uploaded)) {
        return("no_valid_genes")
      } else if (nrow(genes_uploaded) != nrow(genes_present)) {
        return(list(nrow(genes_not_found), nrow(genes_uploaded), genes_not_found))
      } else {
        return("OK")
      }
    },
    "promoters" = {
      return("OK")
    }) # end of switch
}