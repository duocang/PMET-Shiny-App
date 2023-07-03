
ReadPmetResult <- function(filepath) {

  dat_first_row <- readLines(filepath, n = 1)
  pmet_result_rowname <- "Cluster\tMotif 1\tMotif 2\tNumber of genes in cluster with both motifs\tTotal number of genes with both motifs\tNumber of genes in cluster\tRaw p-value\tAdjusted p-value (BH)\tAdjusted p-value (Bonf)\tAdjusted p-value (Global Bonf)\tGenes"
  # print(identical(dat_first_row, pmet_result_rowname))

  if (identical(dat_first_row, character(0))) {
    # hideFeedback("pmet_result_file")
    # showFeedbackDanger(inputId = "pmet_result_file", text = "Empty file")
    return("empty")
  } else if (!identical(dat_first_row, pmet_result_rowname)) {
    # print("Wrong format of uploaded file")
    # hideFeedback("pmet_result_file")
    # showFeedbackDanger(inputId = "pmet_result_file", text = "Wrong format of uploaded file")
    return("wrong")
  }

  df <- data.table::fread(input$pmet_result_file$datapath,
      select = c(
        "Cluster", "Motif 1", "Motif 2",
        "Number of genes in cluster with both motifs",
        "Adjusted p-value (BH)", "Genes"
      ),
      verbose = FALSE
    ) %>%
      setNames(c("cluster", "motif1", "motif2", "gene_num", "p_adj", "genes")) %>%
      # dplyr::filter(gene_num > 0) %>%
      arrange(desc(p_adj)) %>%
      mutate(`motif_pair` = paste0(motif1, "^^", motif2))

}