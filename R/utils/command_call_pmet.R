command_run_pmet <- function(input = NULL, paths = NULL) {

  # paths_pmet <- paths.for.pmet.func(input)

  project_path   <- paths$project_path
  pmetIndex_path <- paths$pmetIndex_path
  user_folder    <- paths$user_folder
  genes_path     <- paths$genes_path


  # print(project_path)
  # print(pmetIndex_path)
  # print(user_folder)
  # print(genes_path)

  # print("___________")

  # send email to user when pmet is done
  temp <- str_split(user_folder, "/")[[1]]
  user_folder_name <- temp[length(temp)]
  recipient   <- paste0(str_split(user_folder_name, "_")[[1]][c(1, 2)], collapse = "@")
  result_link <- paste0("https://bar.utoronto.ca/pmet_result/", paste0(user_folder_name, ".zip"))

  # if run pmet_index
  if (!is.null(input$uploaded_motif_db)) {
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
      "-t 4 ",
      "-c", "24",
      "-x", user_folder,
      "-g", file.path(user_folder, input$gene_for_pmet$name),
      "-e", recipient,
      "-l", result_link,
      file.path(pmetIndex_path, input$uploaded_fasta$name),
      file.path(pmetIndex_path, input$uploaded_annotation$name),
      file.path(pmetIndex_path, input$uploaded_motif_db$name), "&"

      # input$uploaded_fasta$datapath,
      # input$uploaded_annotation$datapath,
      # input$uploaded_motif_db$datapath, "&"
    )
    system("chmod +x PMETdev/PMETindex_promoters_parallel_delete_fimo.sh")
  } else {
    bash_pmet <- paste(
      "nohup PMETdev/PMET.sh ",
      " -d ", pmetIndex_path,
      " -g ", file.path(user_folder, input$gene_for_pmet$name),
      " -i 24",
      " -t 8",
      " -o ", user_folder,
      "-e", recipient,
      "-l", result_link,
      " &")
    system("chmod +x PMETdev/PMET.sh")

    print(bash_pmet)
  }

  messages <- system(bash_pmet, intern=TRUE)
  print(messages)

  return(result_link)
}
