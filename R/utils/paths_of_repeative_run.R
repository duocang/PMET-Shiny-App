# The function `PathsPmetRepeat` returns a list `pmet_config` that
# contains path configuration information based on different input parameters
# and flag variables. This path configuration information is used for executing
# a repetitive running function.

# Simply, we try to reused computed data if user runs a job with identical inputs.

# Parameters:
# - input:                    An input object that contains input of shiny upload.
# - temp_folder:              temp folder when user uploading.
# - pair_dir:              folder used for storing uploaded genes and PMET result.
# - index_dir:           folder used for storing PMET index files.
# - p_pair_dir:     folder from the previous run (or STOP clicked), used to check for the existence of previous PMET result.
# - p_index_dir:  folder from the previous run (or STOP clicked), used to check for the existence of previous PMETindex reulst.
# - flags:     A vector indicating whether there have been changes in the uploaded files.
# - indexing:                A logical flag indicating whether PMET indexing performed or not (set by user, if upload own motifs).

# Returns:
# - pmet_config: A list containing path configuration information used for executing PMETindex-and-PMET or PMET.

# Basic flow:

# indexing: FIMO and PMETindexing
# pairing : PMET
# - First, checks if PMET indexing needs to be performed, TRUE when user uploads own motifs (and genome and annotaion)
# - If PMET indexing is TRUE:
#     - It checks if a flag file was generated from the previous run.
#     - If flags vector indicates no changes and the previous run was successful, it uses the previous user folder path, the previous PMET index path, and the gene path.
#     - If flags vector indicates changes and the previous run was successful, it uses the current user folder path, the previous PMET index path, and the gene path.
#     - If flags vector indicates no changes and the previous run was successful, only pairing is needed.
#     - If flags vector indicates changes and the previous run was successful, indexing and pairing are needed.
#     - If flags vector indicates changes, it creates a new user folder and PMET index path, and copies the uploaded files to the corresponding locations.
# - If PMET indexing is FALSE, user chooses data we provide:
#     - It checks if the flags vector indicates changes.
#     - If flags vector indicates no changes, it uses the previous user folder path and PMET index path.
#     - If flags vector indicates changes, it uses the current user folder path and PMET index path.
#     - If flags vector indicates no changes and the previous run was successful, no indexing or pairing is needed.
#     - If flags vector indicates changes, only pairing is needed.
# - Returns pmet_config list containing the path configuration information as the result.
PathsPmetRepeat <- function(input,
                            temp_folder,
                            previous_paths,
                            flags,
                            first_run,
                            mode) {


  for (name in names(flags)) {
    value <- flags[[name]]
    cat(sprintf("%-20s %d\n", paste0(name, ":"), value))
  }

  pmet_config <- list(user_id                 = NULL,
                      pair_dir           = NULL,
                      index_dir          = NULL,
                      genes_path              = NULL,
                      indexing_pairing_needed = NULL,
                      pairing_need            = NULL)

  pmet_paths  <- paths_for_pmet_func(input, mode, first_run, temp_folder)

  pmet_config$user_id <- pmet_paths$user_id

  c_pair_dir  <- pmet_paths$pair_dir         # current
  c_index_dir <- pmet_paths$index_dir
  p_pair_dir  <- previous_paths["pair_dir" ] # previous
  p_index_dir <- previous_paths["index_dir"]

  if (first_run) {
    if (mode == 1) {
      pmet_config$indexing_pairing_needed <- FALSE
      pmet_config$pairing_need            <- TRUE
    } else {
      pmet_config$indexing_pairing_needed <- TRUE
      pmet_config$pairing_need            <- FALSE
    }
    pmet_config$pair_dir  <- c_pair_dir
    pmet_config$index_dir <- c_index_dir
    pmet_config$genes_path     <- file.path(pmet_config$pair_dir, input$genes$name)

    # rename temp folder in first run of PMET
    file.rename(file.path("result", temp_folder), pmet_config$pair_dir)
    if (mode != 1) {
      file.rename(file.path("result/indexing", temp_folder), pmet_config$index_dir)
    }
  } # if (first_run)

  if (!first_run) {
    pairing_OK   <- file.exists(paste0(p_pair_dir   , "_FLAG"))

    if (mode == 1) {
      if ( sum(unlist(flags)) == 0 ) {
        pmet_config$pair_dir  <- ifelse(pairing_OK, p_pair_dir, c_pair_dir)
        pmet_config$index_dir <- p_index_dir
        pmet_config$genes_path     <- file.path(pmet_config$pair_dir, input$genes$name)

        if (!pairing_OK) {
          dir.create(pmet_config$pair_dir, recursive = TRUE, showWarnings = FALSE)
          file.copy(input$genes$datapath, pmet_config$pair_dir, overwrite = TRUE)
          file.rename(file.path(pmet_config$pair_dir , "0.txt" ), pmet_config$genes_path)
        }

        pmet_config$indexing_pairing_needed  <- FALSE
        pmet_config$pairing_need        <- !pairing_OK
      } else {
        pmet_config$pair_dir            <- c_pair_dir
        pmet_config$index_dir           <- c_index_dir
        pmet_config$indexing_pairing_needed  <- FALSE
        pmet_config$pairing_need             <- TRUE
        pmet_config$genes_path               <- file.path(pmet_config$pair_dir, input$genes$name)

        file.rename(file.path("result", temp_folder), pmet_config$pair_dir)
      }
    }# if !indexing
    if (mode == 2 | mode == 3) {
      # if the previous run has completed of PMETindex, there will be a flag file generated
      indexing_OK <- file.exists(paste0(p_index_dir, "_FLAG"))

      # after the previous run, the flag will be set to all zeros, meaning no upload changed
      if ( sum(unlist(flags)) == 0 ) {
        pmet_config$pair_dir  <- ifelse(pairing_OK, p_pair_dir, c_pair_dir)
        pmet_config$index_dir <- p_index_dir
        pmet_config$genes_path     <- file.path(pmet_config$pair_dir, input$genes$name)

        if (!pairing_OK) {
          dir.create(pmet_config$pair_dir, recursive = TRUE, showWarnings = FALSE)
          file.copy(input$genes$datapath, pmet_config$genes_path, overwrite = TRUE)
        }
        pmet_config$pairing_need            <- !pairing_OK && indexing_OK
        pmet_config$indexing_pairing_needed <- !pmet_config$pairing_need && !indexing_OK


      } else if ( flags$genes == 1 & sum(unlist(flags)) == 1) {
        pmet_config$pair_dir  <- c_pair_dir
        pmet_config$index_dir <- ifelse(indexing_OK, p_index_dir, c_pair_dir)

        pmet_config$genes_path     <- file.path(pmet_config$pair_dir, input$genes$name)

        pmet_config$indexing_pairing_needed <- !indexing_OK
        pmet_config$pairing_need            <- indexing_OK

        file.rename(file.path("result", temp_folder), pmet_config$pair_dir)

        file.copy(input$genes$datapath, pmet_config$genes_path, overwrite = TRUE)
      } else {
        # user uploads new daat for PMET, create new folder for PMETindex and PMET
        pmet_config$pair_dir            <- c_pair_dir
        pmet_config$index_dir           <- c_index_dir
        pmet_config$indexing_pairing_needed  <- TRUE
        pmet_config$pairing_need             <- FALSE
        pmet_config$genes_path               <- file.path(pmet_config$pair_dir, input$genes$name)

        # copy uploaded files from var (temp) to local folders
        if (flags$meme == 0) {
          TempToLocal("result/indexing", temp_folder, input$meme)
        }
        if (flags$fasta == 0) {
          TempToLocal("result/indexing", temp_folder, input$fasta)
        }
        if (flags$gff3 == 0) {
          TempToLocal("result/indexing", temp_folder, input$gff3)
        }
        if (flags$genes == 0) {
          # # create local folders
          # dir.create(file.path("result", temp_folder), recursive = TRUE, showWarnings = FALSE)
          TempToLocal("result", temp_folder, input$genes)
        }
        file.rename(file.path("result", temp_folder), pmet_config$pair_dir)
        file.rename(file.path("result/indexing", temp_folder), pmet_config$index_dir)
      }
    } # if (mode == 2)
  } # if (!first_run)

  for (name in names(pmet_config)) {
    value <- pmet_config[[name]]
    cat(sprintf("%-20s %s\n", paste0(name, ":"), value))
  }
  return(pmet_config)
} # function definition


