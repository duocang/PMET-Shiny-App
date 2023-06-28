# Function to check the gene file provided by the user
# Parameters:
#   - input: Input of shiny server
# Returns:
#   - "no_content": If the gene file is empty or the data path is not specified
#   - "gene_wrong_format": If there was an error reading the gene file
#   - "wrong_column": If the gene file does not have exactly two columns
#   - "intervals_wrong_format": If the gene file contains invalid interval format
#   - "OK": If the gene file passes all the checks
check_gene_file_fucn <- function(input = NULL) {

  mode <- pmet_mode_func(input)


  if (input$gene_for_pmet$size== 0 |is.null(input$gene_for_pmet$datapath) )
    return("no_content")

  # read gene file uploaded
  genes_uploaded <- tryCatch({
      read.table(input$gene_for_pmet$datapath)},
    error = function(e) {
      return(NULL)
  })

  if (is.null(genes_uploaded))
    return("gene_wrong_format")

  if (ncol(genes_uploaded) != 2)
    return("wrong_column")

  colnames(genes_uploaded) <- c("cluster", "gene")
  # Perform checks based on the sequence type
  switch(input$sequence_type,
    "intervals" = {
      pattern <- "^1:\\d+-\\d+$" # # Define the pattern for valid interval format
      num_invalid_intervals <- (!grepl(pattern, genes_uploaded[, "gene"])) %>% sum()
      if (num_invalid_intervals != 0) {
        return("intervals_wrong_format")
      } else {
        return("OK")
      }
    },
    "promoters" = {
      if (input$motif_db != "uploaded_motif") {
        # if motifs selected, check the uploaded genes with the gene list in our folder, named universe.txt
        genes_universe <- file.path("data/PMETindex",
                                    str_split(input$motif_db, "-")[[1]][1],
                                    input$motif_db, "universe.txt") %>% read.table() %>% `colnames<-`(c("gene"))

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
      } else {
        return("OK")
      }
    }) # end of switch
}


check_gene_file_func_ <- function(gene_file_size = NULL, gene_file_path = NULL, motif_db = NULL, mode = NULL) {

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