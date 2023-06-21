# command_run_pmet <- function(input = NULL, paths = NULL) {
command_run_pmet <- function( input,
                              pmetIndex_path  = NULL,
                              pmetPair_path     = NULL,
                              genes_path      = NULL,
                              indexing_pairing=TRUE,
                              pairing_only    =FALSE,
                              mode = 1) {


  # send email to user when pmet is done
  temp <- str_split(pmetPair_path, "/")[[1]]
  pmetPair_path_name <- temp[length(temp)]
  recipient   <- input$userEmail
  result_link <- paste0("https://bar.utoronto.ca/pmet_result/", paste0(pmetPair_path_name, ".zip"))


  if (mode == 3) {
    bash_pmet <- paste(
      "nohup PMETdev/PMETindex_intervals_parallel_delete_fimo.sh ",
      "-r ", "PMETdev/scripts ",
      "-o", pmetIndex_path,
      "-n", input$promoter_number,
      "-k", input$max_motif_matches,
      "-f", "0.05",
      "-t 4",
      file.path(pmetIndex_path, input$uploaded_fasta$name),
      file.path(pmetIndex_path, input$uploaded_meme$name),
      "&"
    )
    system("chmod +x PMETdev/PMETindex_intervals_parallel_delete_fimo.sh")
    messages <- system(bash_pmet, intern=TRUE)
  }

  # if run pmet_index
  if (mode == 2 & indexing_pairing) {
    cli::cat_rule(sprintf("运行PMETindex！"))

    bash_pmet <- paste(
      "nohup PMETdev/PMETindex_promoters_parallel_delete_fimo.sh ",
      "-r ", "PMETdev/scripts ",
      "-i gene_id=",
      "-o", pmetIndex_path,
      "-n", input$promoter_number,
      "-k", input$max_motif_matches,
      "-p", input$promoter_length,
      "-f", "0.05",
      "-v ", input$promoters_overlap, # AllowOverlap/NoOverlap
      "-u ", input$utr5, # Yes/No
      "-t 4",
      "-c", "24",
      "-x", pmetPair_path,
      "-g", genes_path,
      "-e", recipient,
      "-l", result_link,
      file.path(pmetIndex_path, input$uploaded_fasta$name),
      file.path(pmetIndex_path, input$uploaded_annotation$name),
      file.path(pmetIndex_path, input$uploaded_meme$name),
      "&"
    )
    print(bash_pmet)
    system("chmod +x PMETdev/scripts/gff3sort/gff3sort.pl")
    system("chmod +x PMETdev/PMETindex_promoters_parallel_delete_fimo.sh")
    messages <- system(bash_pmet, intern=TRUE)
    # system(bash_pmet)
    # print(messages)
  }

  print(mode)
  print(pairing_only)

  if ((mode %in% c(1, 2)) & pairing_only) {
    bash_pmet <- paste(
      "nohup PMETdev/PMET.sh ",
      " -d ", pmetIndex_path,
      " -g ", genes_path,
      " -i 24",
      " -t 4",
      " -o ", pmetPair_path,
      "-e", recipient,
      "-l", result_link,
      " &")
    system("chmod +x PMETdev/PMET.sh")
    print(bash_pmet)
    messages <- system(bash_pmet, intern=TRUE)
    # system(bash_pmet)
  }


  if (!pairing_only & !indexing_pairing) {
    system(paste("Rscript R/utils/send_mail.R", recipient, result_link))
  }


  if (file.exists(paste0(pmetPair_path, ".zip")))
    return(result_link)
  else
    return("NO RESULT")
}
