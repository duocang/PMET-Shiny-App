# The function `paths_of_repeative_run_func` returns a list `pmet_config` that
# contains path configuration information based on different input parameters
# and flag variables. This path configuration information is used for executing
# a repetitive running function.

# Simply, we try to reused computed data if user runs a job with identical inputs.

# Parameters:
# - input:                    An input object that contains input of shiny upload.
# - temp_folder:              temp folder when user uploading.
# - pmetPair_path:              folder used for storing uploaded genes and PMET result.
# - pmetIndex_path:           folder used for storing PMET index files.
# - p_pmetPair_path:     folder from the previous run (or STOP clicked), used to check for the existence of previous PMET result.
# - p_pmetindex_path:  folder from the previous run (or STOP clicked), used to check for the existence of previous PMETindex reulst.
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
paths_of_repeative_run_func <- function(input,
                                        temp_folder,
                                        previous_paths,
                                        flags,
                                        first_run,
                                        mode) {

  print(flags)

  pmet_config <- list(pmetPair_path           = NULL,
                      pmetIndex_path          = NULL,
                      genes_path              = NULL,
                      indexing_pairing_needed = NULL,
                      pairing_need            = NULL)

  UPLOAD_DIR <- "data/PMETindex/uploaded_motif"

  pmet_paths  <- paths_for_pmet_func(input, mode, first_run, temp_folder)

  c_pmetPair_path  <- pmet_paths$pmetPair_path         # current
  c_pmetIndex_path <- pmet_paths$pmetIndex_path
  p_pmetPair_path  <- previous_paths["pmetPair_path" ] # previous
  p_pmetindex_path <- previous_paths["pmetIndex_path"]

  if (first_run) {
    if (mode == 1) {
      pmet_config$indexing_pairing_needed <- FALSE
      pmet_config$pairing_need            <- TRUE
    } else {
      pmet_config$indexing_pairing_needed <- TRUE
      pmet_config$pairing_need            <- FALSE
    }
    pmet_config$pmetPair_path  <- c_pmetPair_path
    pmet_config$pmetIndex_path <- c_pmetIndex_path
    pmet_config$genes_path     <- file.path(pmet_config$pmetPair_path, input$gene_for_pmet$name)

    # rename temp folder in first run of PMET
    file.rename(file.path("result", temp_folder), pmet_config$pmetPair_path)
    if (mode != 1) {
      file.rename(file.path(UPLOAD_DIR, temp_folder), pmet_config$pmetIndex_path)
    }

  }

  if (!first_run) {
    # print(flags)
    pairing_OK   <- file.exists(paste0(p_pmetPair_path   , "_FLAG"))

    if (mode == 1) {
      if ( sum(unlist(flags)) == 0 ) {
        pmet_config$pmetPair_path  <- ifelse(pairing_OK, p_pmetPair_path, c_pmetPair_path)
        pmet_config$pmetIndex_path <- p_pmetindex_path
        pmet_config$genes_path     <- file.path(pmet_config$pmetPair_path, input$gene_for_pmet$name)

        if (!pairing_OK) {
          dir.create(pmet_config$pmetPair_path, recursive = TRUE)
          file.copy(input$gene_for_pmet$datapath, pmet_config$pmetPair_path, overwrite = TRUE)
          file.rename(file.path(pmet_config$pmetPair_path , "0.txt" ), pmet_config$genes_path)
        }

        pmet_config$indexing_pairing_needed  <- FALSE
        pmet_config$pairing_need        <- !pairing_OK
      } else {
        pmet_config$pmetPair_path            <- c_pmetPair_path
        pmet_config$pmetIndex_path           <- c_pmetIndex_path
        pmet_config$indexing_pairing_needed  <- FALSE
        pmet_config$pairing_need             <- TRUE
        pmet_config$genes_path               <- file.path(pmet_config$pmetPair_path, input$gene_for_pmet$name)

        file.rename(file.path("result", temp_folder), pmet_config$pmetPair_path)
      }
    }# if !indexing

    if (mode == 2) {
      # if the previous run has completed of PMETindex, there will be a flag file generated
      indexing_OK <- file.exists(paste0(p_pmetindex_path, "_FLAG"))

      # after the previous run, the flag will be set to all zeros, meaning no upload changed
      if ( sum(unlist(flags)) == 0 ) {
        print("afaFDA发森阿赛")
        pmet_config$pmetPair_path  <- ifelse(pairing_OK, p_pmetPair_path, c_pmetPair_path)
        pmet_config$pmetIndex_path <- p_pmetindex_path
        pmet_config$genes_path     <- file.path(pmet_config$pmetPair_path, input$gene_for_pmet$name)

        if (!pairing_OK) {
          dir.create(pmet_config$pmetPair_path, recursive = TRUE)
          file.copy(input$gene_for_pmet$datapath, pmet_config$genes_path, overwrite = TRUE)
        }
        pmet_config$pairing_need            <- !pairing_OK && indexing_OK
        pmet_config$indexing_pairing_needed <- !pmet_config$pairing_need && !indexing_OK


      } else if ( flags$gene_for_pmet == 1 & sum(unlist(flags)) == 1) {
        pmet_config$pmetPair_path  <- c_pmetPair_path
        pmet_config$pmetIndex_path <- p_pmetindex_path
        pmet_config$genes_path     <- file.path(pmet_config$pmetPair_path, input$gene_for_pmet$name)

        pmet_config$indexing_pairing_needed <- !indexing_OK
        pmet_config$pairing_need            <- indexing_OK

        file.rename(file.path("result", temp_folder), pmet_config$pmetPair_path)

        file.copy(input$gene_for_pmet$datapath, pmet_config$genes_path, overwrite = TRUE)
      } else {
        # user uploads new daat for PMET, create new folder for PMETindex and PMET
        pmet_config$pmetPair_path            <- c_pmetPair_path
        pmet_config$pmetIndex_path           <- c_pmetIndex_path
        pmet_config$indexing_pairing_needed  <- TRUE
        pmet_config$pairing_need             <- FALSE
        pmet_config$genes_path               <- file.path(pmet_config$pmetPair_path, input$gene_for_pmet$name)

        # copy uploaded files from var (temp) to local folders
        if (flags$uploaded_meme == 0) {
          temp_2_local_func(UPLOAD_DIR, temp_folder, input$uploaded_meme)
        }
        if (flags$uploaded_fasta == 0) {
          temp_2_local_func(UPLOAD_DIR, temp_folder, input$uploaded_fasta)
        }
        if (flags$uploaded_annotation == 0) {
          temp_2_local_func(UPLOAD_DIR, temp_folder, input$uploaded_annotation)
        }
        if (flags$gene_for_pmet == 0) {
          # create local folders
          dir.create(file.path("result", temp_folder), recursive = TRUE)
          temp_2_local_func("result", temp_folder, input$gene_for_pmet)
        }
        file.rename(file.path("result", temp_folder), pmet_config$pmetPair_path)
        file.rename(file.path(UPLOAD_DIR, temp_folder), pmet_config$pmetIndex_path)
      }
    } # if (mode == 2)
  } # if (!first_run)

  print(pmet_config)
  return(pmet_config)
} # function definition