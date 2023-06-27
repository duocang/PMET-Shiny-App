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

        print(head(genes_skipped))

        print(nrow(genes_skipped))
        print(nrow(genes_uploaded))

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


# observeEvent(input$gene_for_pmet, {
#   # copy uploaded genes to result folder for PMET to run in the back
#   temp_2_local_func("result", session_id, input$gene_for_pmet)
#   flag_upload_changed[["gene_for_pmet"]] <<- 1

#   shinyjs::hide("skipped_genes_link")
#   # no valide gene file
#   if (input$gene_for_pmet$size== 0 |is.null(input$gene_for_pmet$datapath) ){
#     showFeedbackDanger(inputId = "gene_for_pmet", text = "No content in the file")
#   }

#   # read gene file uploaded
#   genes_uploaded <- tryCatch({
#       read.table(input$gene_for_pmet$datapath)},
#     error = function(e) { showFeedbackDanger( inputId = "gene_for_pmet", text = "Wrong format of uploaded file") })

#   if (ncol(genes_uploaded) != 2) {
#     showFeedbackDanger( inputId = "gene_for_pmet", text = "Only cluster and interval columns are allowed")
#   } else {
#     colnames(genes_uploaded) <- c("cluster", "gene")
#   }

#   switch(input$sequence_type,
#     "intervals" = {
#       pattern <- "^1:\\d+-\\d+$"
#       num_invalid_intervals <- (!grepl(pattern, genes_uploaded[, "gene"])) %>% sum()
#       if (num_invalid_intervals != 0) {
#         showFeedbackDanger( inputId = "gene_for_pmet", text = "Genomic intervals pattern: chromosome:number-number.")
#       } else {
#         showFeedbackSuccess(inputId = "gene_for_pmet")
#       }
#     },
#     "promoters" = {
#       if (input$motif_db != "uploaded_motif") {
#         # if motifs selected, check the uploaded genes with the gene list in our folder, named universe.txt
#         genes_universe <- file.path("data/PMETindex",
#                                     str_split(input$motif_db, "-")[[1]][1],
#                                     input$motif_db, "universe.txt") %>% read.table() %>% `colnames<-`(c("gene"))

#         genes_present <-  dplyr::inner_join(genes_uploaded, genes_universe, by = "gene")
#         genes_skipped( setdiff(genes_uploaded, genes_present) )

#         # no genes available in the uploaded file
#         if (nrow(genes_skipped) == nrow(genes_uploaded)) {
#           shinyjs::show("skipped_genes_link")
#           showFeedbackDanger(inputId = "gene_for_pmet", text = "No valid genes available in the uploaded file")
#         } else if (nrow(genes_uploaded) != nrow(genes_present)) {
#           shinyjs::show("skipped_genes_link")
#           showFeedbackWarning(
#             inputId = "gene_for_pmet",
#             text = paste(nrow(genes_skipped), "out of", nrow(genes_uploaded), "genes are skipped"))
#         } else {
#           showFeedbackSuccess(inputId = "gene_for_pmet")
#         } # end of if (nrow(genes_skipped) == nrow(genes_uploaded))
#       } else {
#         showFeedbackSuccess(inputId = "gene_for_pmet")
#       }
#     }) # end of switch
# }, ignoreInit = T)
