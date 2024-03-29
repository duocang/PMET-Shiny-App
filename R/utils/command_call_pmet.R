# Function to run PMET with indexing and pairing
ComdRunPmet <- function(input,
                        index_dir  = NULL,
                        pair_dir   = NULL,
                        genes_path = NULL,
                        model      = NULL) {

  # send email to user when pmet is done
  temp <- str_split(pair_dir, "/")[[1]]
  pair_dir_name <- temp[length(temp)]
  recipient   <- input$email

  nginx_link <- readLines("data/nginx_link.txt")
  nginx_link <- nginx_link[1]

  result_link <- paste0(nginx_link, paste0(pair_dir_name, ".zip"))
  print(result_link)

  switch(model,
    "promoters_pre" = {
      bash_pmet <- paste(
        "nohup PMETdev/promoters_only_pair.sh ",
        "-d", index_dir,
        "-g", file.path(pair_dir, "0.txt"),
        "-i", input$ic_threshold,
        "-t", NCPU,
        "-o", pair_dir,
        "-e", recipient,
        "-l", result_link, " &")
      system("chmod +x PMETdev/promoters_only_pair.sh")
    },
    "promoters" = {
      bash_pmet <- paste(
        "nohup PMETdev/promoters_index_pair_new_fimo.sh ",
        "-r ", "PMETdev/scripts ",
        "-i gene_id=",
        "-o", index_dir,
        "-n", input$promoter_num,
        "-k", input$max_match,
        "-p", input$promoter_length,
        "-f", input$fimo_threshold,
        "-v", input$promoters_overlap, # AllowOverlap/NoOverlap
        "-u", input$utr5, # Yes/No
        "-t", NCPU,
        "-c", input$ic_threshold,
        "-x", pair_dir,
        "-g", file.path(pair_dir, "0.txt"),
        "-e", recipient,
        "-l", result_link,
        file.path(index_dir, paste0("0.", tools::file_ext(input$fasta$name))),
        file.path(index_dir, "0.gff3"),
        file.path(index_dir, "0.meme"), "&")
      system("chmod +x PMETdev/scripts/gff3sort/gff3sort.pl")
      system("chmod +x PMETdev/promoters_index_pair_new_fimo.sh")
    },
    "intervals" = {
      bash_pmet <- paste(
        "nohup PMETdev/intervals_index_pair.sh ",
        "-r ", "PMETdev/scripts ",
        "-o", index_dir,
        "-n", input$promoter_num,
        "-k", input$max_match,
        "-f", input$fimo_threshold,
        "-t", NCPU,
        "-x", pair_dir,
        "-g", file.path(pair_dir, "0.txt"),
        "-c", input$ic_threshold,
        "-e", recipient,
        "-l", result_link,
        file.path(index_dir, paste0("0.", tools::file_ext(input$fasta$name))),
        file.path(index_dir, "0.meme"), "&")
      system("chmod +x PMETdev/intervals_index_pair.sh")
    })

    print(bash_pmet)
    messages <- system(bash_pmet, intern=TRUE)

  if (file.exists(paste0(pair_dir, ".zip"))) {
    # delete folder and FLAG of PMET index
    if (model != "promoters_pre") {
      bash_rm_pmetindex <- paste0("rm -rf ", index_dir, "_FLAG")
      system(bash_rm_pmetindex, intern=TRUE)
      bash_rm_pmetindex <- paste0("rm -rf ", index_dir)
      system(bash_rm_pmetindex, intern=TRUE)
    }
    return(result_link)
  }
  else {
    return("NO RESULT")
  }
}
