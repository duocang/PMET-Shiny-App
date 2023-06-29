# Function to run PMET with indexing and pairing
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
  print(result_link)

  switch(mode,
    "1" = {
      if ( pairing_only) {
        bash_pmet <- paste(
          "nohup PMETdev/PMET.sh ",
          " -d ", pmetIndex_path,
          " -g ", genes_path,
          " -i 24",
          " -t 8",
          " -o ", pmetPair_path,
          "-e", recipient,
          "-l", result_link,
          " &")
        system("chmod +x PMETdev/PMET.sh")
        messages <- system(bash_pmet, intern=TRUE)
      }
    },
    "2" = {
      if (pairing_only) {
        bash_pmet <- paste(
          "nohup PMETdev/PMET_only_promoters.sh",
          " -d ", pmetIndex_path,
          " -g ", genes_path,
          " -i 24",
          " -t 8",
          " -o ", pmetPair_path,
          "-e", recipient,
          "-l", result_link,
          " &")
        system("chmod +x PMETdev/PMET.sh")
        messages <- system(bash_pmet, intern=TRUE)
      } else if (indexing_pairing) {
        # cli::cat_rule(sprintf("运行PMETindex！"))
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
          "-t 8",
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
        system("chmod +x PMETdev/scripts/gff3sort/gff3sort.pl")
        system("chmod +x PMETdev/PMETindex_promoters_parallel_delete_fimo.sh")
        message <- tryCatch({
          system(bash_pmet, intern=TRUE)
        }, error = function(err) {
          return("PMET STOP")
        })
      }
    },
    "3" = {
      if (pairing_only) {
        bash_pmet <- paste(
          "nohup PMETdev/PMET_only_intervals.sh",
          " -d ", pmetIndex_path,
          " -g ", genes_path,
          " -i 24",
          " -t 8",
          " -o ", pmetPair_path,
          "-e", recipient,
          "-l", result_link,
          " &")
        system("chmod +x PMETdev/PMET.sh")
        messages <- system(bash_pmet, intern=TRUE)
      } else if (indexing_pairing) {
        bash_pmet <- paste(
          "nohup PMETdev/PMETindex_intervals_parallel_delete_fimo.sh ",
          "-r ", "PMETdev/scripts ",
          "-o", pmetIndex_path,
          "-n", input$promoter_number,
          "-k", input$max_motif_matches,
          "-f", "0.05",
          "-t 8",
          "-x", pmetPair_path,
          "-g", genes_path,
          "-e", recipient,
          "-l", result_link,
          file.path(pmetIndex_path, input$uploaded_fasta$name),
          file.path(pmetIndex_path, input$uploaded_meme$name),
          "&"
        )
        system("chmod +x PMETdev/PMETindex_intervals_parallel_delete_fimo.sh")
        messages <- system(bash_pmet, intern=TRUE)
      }
    })

  if (!pairing_only & !indexing_pairing) {
    system(paste("Rscript R/utils/send_mail.R", recipient, result_link))
  }


  if (file.exists(paste0(pmetPair_path, ".zip")))
    return(result_link)
  else
    return("NO RESULT")
}


# command_run_pmet <- function(input = NULL, paths = NULL) {
command_run_pmet_ <- function(input,
                              pmetIndex_path  = NULL,
                              pmetPair_path   = NULL,
                              genes_path      = NULL,
                              model           = NULL) {

  # send email to user when pmet is done
  temp <- str_split(pmetPair_path, "/")[[1]]
  pmetPair_path_name <- temp[length(temp)]
  recipient   <- input$userEmail
  result_link <- paste0("https://bar.utoronto.ca/pmet_result/", paste0(pmetPair_path_name, ".zip"))

  print(result_link)

  switch(model,
    "promoters_pre" = {
      bash_pmet <- paste(
        "nohup PMETdev/PMET_only_promoters.sh ",
        " -d ", pmetIndex_path,
        " -g ", genes_path,
        " -i 24",
        " -t 8",
        " -o ", pmetPair_path,
        "-e", recipient,
        "-l", result_link,
        " &")
      print(bash_pmet)
      system("chmod +x PMETdev/PMET_only_promoters.sh")
      messages <- system(bash_pmet, intern=TRUE)
    },
    "promoters" = {
      # cli::cat_rule(sprintf("运行PMETindex！"))
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
        "-t 8",
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
      system(bash_pmet, intern=TRUE)

    },
    "intervals" = {
      bash_pmet <- paste(
        "nohup PMETdev/PMETindex_intervals_parallel_delete_fimo.sh ",
        "-r ", "PMETdev/scripts ",
        "-o", pmetIndex_path,
        "-n", input$promoter_number,
        "-k", input$max_motif_matches,
        "-f", "0.05",
        "-t 8",
        "-x", pmetPair_path,
        "-g", genes_path,
        "-e", recipient,
        "-l", result_link,
        file.path(pmetIndex_path, input$uploaded_fasta$name),
        file.path(pmetIndex_path, input$uploaded_meme$name),
        "&"
      )
      print(bash_pmet)
      system("chmod +x PMETdev/PMETindex_intervals_parallel_delete_fimo.sh")
      messages <- system(bash_pmet, intern=TRUE)
    })

  if (file.exists(paste0(pmetPair_path, ".zip")))
    return(result_link)
  else
    return("NO RESULT")
}
