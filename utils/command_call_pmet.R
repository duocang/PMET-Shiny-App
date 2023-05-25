command_run_pmet <- function(project_path = NULL,
                             pmetIndex_path = NULL,
                             user_folder = NULL,
                             genes_path,
                             os = "Linux") {
  # prepare parameters for

  genes_universe <- read.table(file.path(pmetIndex_path, "universe.txt")) %>%
    `colnames<-`(c("gene"))
  genes_uploaded <- read.table(genes_path) %>%
    `colnames<-`(c("cluster", "gene"))
  genes_present <- dplyr::inner_join(genes_uploaded, genes_universe,
    by = "gene"
  )
  genes_skipped <- setdiff(genes_uploaded, genes_present)

  # create a folder for user -----------------------------------------------
  bash_create_folder <- paste0("mkdir -p ", user_folder)
  system(bash_create_folder, intern = TRUE)

  genes_provided <- file.path(user_folder, "genes_provided.txt")
  genes_used_PMET <- file.path(user_folder, "genes_used_PMET.txt")
  genes_skipped_file <- file.path(user_folder, "genes_skipped.txt")

  # save genes info to user folder (result)
  write.table(genes_uploaded, genes_provided,
    row.names = FALSE, col.names = FALSE, quote = FALSE
  )
  write.table(genes_present, genes_used_PMET,
    row.names = FALSE, col.names = FALSE, quote = FALSE
  )
  write.table(genes_skipped, genes_skipped_file,
    row.names = FALSE, col.names = FALSE, quote = FALSE
  )

  # run pmet ---------------------------------------------------------------
  pmet <- switch(os,
    "Windows" = file.path(project_path, "utils/pmetParallel.exe "),
    "Linux"   = file.path(project_path, "utils/pmetParallel_linux "),
    "Darwin"  = file.path(project_path, "utils/pmetParallel_mac "),
    stop(paste("Unsupported OS:", os))
  )

  bash_pmet <- paste0(
    pmet,
    " -d ", pmetIndex_path,
    " -g ", file.path(user_folder, "genes_used_PMET.txt"),
    " -i 4",
    " -p promoter_lengths.txt",
    " -b binomial_thresholds.txt",
    " -c IC.txt",
    " -f fimohits",
    " -t 4",
    " -o ", user_folder, " > ",
    file.path(user_folder, "PMETparallel.log")
  )

  # # merge results ----------------------------------------------------------
  if (os == "Windows") {
    print(bash_pmet)

    system(bash_pmet, intern = TRUE)
    paste0("cat ", user_folder, "/temp*.txt > ", user_folder, "/motif_output.txt") %>%
      str_replace_all("//", "/") %>%
      str_replace_all("/", "\\\\") %>%
      system()

    paste0("rm ", user_folder, "/temp*.txt") %>%
      str_replace_all("//", "/") %>%
      str_replace_all("/", "\\\\") %>%
      system()
  } else {
    pmet_output_txt_temps <- file.path(user_folder, "/temp*.txt")
    pmet_output_txt <- file.path(user_folder, "PMET_OUTPUT.txt")
    # commands
    bash_merge_temps <- paste0("cat ", pmet_output_txt_temps, " > ", pmet_output_txt)
    bash_rm_temps <- paste0("rm ", pmet_output_txt_temps)

    bash_run <- paste0(
      bash_pmet, "\n\n",
      bash_merge_temps, "\n\n",
      bash_rm_temps
    )

    bash_file <- file.path(user_folder, "run_pmet.sh")
    # commands to .sh file
    write.table(bash_run,
      bash_file,
      quote = FALSE,
      col.names = FALSE,
      row.names = FALSE, sep = "\t"
    )
    # run commands
    system(paste0("bash ", bash_file), intern = TRUE)

    temp <- str_split(user_folder, "/")[[1]]
    user_folder_name <- temp[length(temp)]

    # zip command
    zip_file <- file.path(user_folder, "..", paste0(user_folder_name, ".zip"))
    bash_zip <- paste(
      "zip -j",
      zip_file,
      genes_provided,
      genes_used_PMET,
      genes_skipped_file,
      pmet_output_txt,
      sep = " "
    )
    system(bash_zip)

    # send email to user when pmet is done
    temp <- str_split(user_folder, "/")[[1]]
    recipient <- paste0(str_split(user_folder_name, "_")[[1]][c(1, 2)], collapse = "@")
    result_link <- paste0("http://127.0.0.1:84/result/", paste0(user_folder_name, ".zip"))
    print(recipient)
    # send_result_mail(recipient = recipient, result_link = result_link)

    # # move pmet result txt to result folder, download when user clicks on button
    # temp <- file.path(user_folder, "..", paste0(user_folder_name, ".txt"))

    # system(paste("mv", pmet_output_txt, temp , sep = " "))
    
    # system(paste0("rm -rf ", user_folder))

  }
  return(result_link)
}
