# The function `paths_of_repeative_run_func` returns a list `pmet_config` that
# contains path configuration information based on different input parameters
# and flag variables. This path configuration information is used for executing
# a repetitive running function.

# Simply, we try to reused computed data if user runs a job with identical inputs.

# Parameters:
# - input:                   An input object that contains input of shiny upload.
# - session_id:              temp folder when user uploading.
# - user_folder:             folder used for storing uploaded genes and PMET result.
# - pmetIndex_path:          folder used for storing PMET index files.
# - previous_user_folder:    folder from the previous run (or STOP clicked), used to check for the existence of previous PMET result.
# - previsou_pmetindex_path: folder from the previous run (or STOP clicked), used to check for the existence of previous PMETindex reulst.
# - flag_upload_changed:     A vector indicating whether there have been changes in the uploaded files.
# - indexing:                A logical flag indicating whether PMET indexing performed or not (set by user, if upload own motifs).

# Returns:
# - pmet_config: A list containing path configuration information used for executing PMETindex-and-PMET or PMET.

# Basic flow:

# indexing: FIMO and PMETindexing
# pairing : PMET
# - First, checks if PMET indexing needs to be performed, TRUE when user uploads own motifs (and genome and annotaion)
# - If PMET indexing is TRUE:
#     - It checks if a flag file was generated from the previous run.
#     - If flag_upload_changed vector indicates no changes and the previous run was successful, it uses the previous user folder path, the previous PMET index path, and the gene path.
#     - If flag_upload_changed vector indicates changes and the previous run was successful, it uses the current user folder path, the previous PMET index path, and the gene path.
#     - If flag_upload_changed vector indicates no changes and the previous run was successful, only pairing is needed.
#     - If flag_upload_changed vector indicates changes and the previous run was successful, indexing and pairing are needed.
#     - If flag_upload_changed vector indicates changes, it creates a new user folder and PMET index path, and copies the uploaded files to the corresponding locations.
# - If PMET indexing is FALSE, user chooses data we provide:
#     - It checks if the flag_upload_changed vector indicates changes.
#     - If flag_upload_changed vector indicates no changes, it uses the previous user folder path and PMET index path.
#     - If flag_upload_changed vector indicates changes, it uses the current user folder path and PMET index path.
#     - If flag_upload_changed vector indicates no changes and the previous run was successful, no indexing or pairing is needed.
#     - If flag_upload_changed vector indicates changes, only pairing is needed.
# - Returns pmet_config list containing the path configuration information as the result.
paths_of_repeative_run_func <- function(input,
                                        session_id,
                                        user_folder,
                                        pmetIndex_path,
                                        previous_user_folder,
                                        previsou_pmetindex_path,
                                        flag_upload_changed,
                                        indexing) {
  pmet_config <- list(user_folder=NULL,
                      pmetIndex_path=NULL,
                      genes_path  = NULL,
                      indexing_pairing_needed=NULL,
                      pairing_need_only=NULL)


  pairing_SUCCESS   <- file.exists(paste0(previous_user_folder   , "_FLAG"))

  if (indexing) {
    # if the previous run has completed of PMETindex, there will be a flag file generated
    indexing_SUCCESS <- file.exists(paste0(previsou_pmetindex_path, "_FLAG"))

    # after the previous run, the flag will be set to all zeros
    if (identical(flag_upload_changed, c(0,0,0,0,  0,0,0,0,0,0))) {
      pmet_config$user_folder    <- ifelse(pairing_SUCCESS, previous_user_folder, user_folder)
      pmet_config$pmetIndex_path <- previsou_pmetindex_path
      pmet_config$genes_path     <- file.path(pmet_config$user_folder, input$gene_for_pmet$name)

      if (!pairing_SUCCESS) {
        system(paste("mkdir -p", pmet_config$user_folder))
        file.copy(input$gene_for_pmet$datapath, pmet_config$user_folder, overwrite = TRUE)
        file.rename(file.path(pmet_config$user_folder , "0.txt" ), pmet_config$genes_path)
      }
      pmet_config$pairing_need_only       <- !pairing_SUCCESS && indexing_SUCCESS
      pmet_config$indexing_pairing_needed <- !pmet_config$pairing_need_only && !indexing_SUCCESS


    } else if (identical(flag_upload_changed, c(0,0,0,1,  0,0,0,0,0,0))) {
      pmet_config$user_folder              <- user_folder
      pmet_config$pmetIndex_path           <- previsou_pmetindex_path
      pmet_config$genes_path               <- file.path(pmet_config$user_folder, input$gene_for_pmet$name)

      pmet_config$indexing_pairing_needed <- !indexing_SUCCESS
      pmet_config$pairing_need_only       <- indexing_SUCCESS

      file.rename(file.path("result", session_id), pmet_config$user_folder)

      file.copy(input$gene_for_pmet$datapath, pmet_config$user_folder, overwrite = TRUE)
      file.rename(file.path(pmet_config$user_folder , "0.txt" ), pmet_config$genes_path)
    } else {
      # user uploads new daat for PMET, create new folder for PMETindex and PMET
      pmet_config$user_folder              <- user_folder
      pmet_config$pmetIndex_path           <- pmetIndex_path
      pmet_config$indexing_pairing_needed  <- TRUE
      pmet_config$pairing_need_only        <- FALSE
      pmet_config$genes_path               <- file.path(pmet_config$user_folder, input$gene_for_pmet$name)
      # create local folders
      system(paste("mkdir -p", user_folder))
      system(paste("mkdir -p", pmetIndex_path))
      # copy uploaded files from var (temp) to local folders
      file.copy(input$uploaded_motif_db$datapath  , pmetIndex_path, overwrite = TRUE)
      file.copy(input$uploaded_fasta$datapath     , pmetIndex_path, overwrite = TRUE)
      file.copy(input$uploaded_annotation$datapath, pmetIndex_path, overwrite = TRUE)
      file.copy(input$gene_for_pmet$datapath      , user_folder   , overwrite = TRUE)
      # rename copied files
      fasta_temp <- ifelse(endsWith(input$uploaded_fasta$name, "fa"), "0.fa", "0.fasta")
      file.rename(file.path(pmetIndex_path, fasta_temp), file.path(pmetIndex_path, input$uploaded_fasta$name))
      file.rename(file.path(pmetIndex_path, "0.meme"  ), file.path(pmetIndex_path, input$uploaded_motif_db$name))
      file.rename(file.path(pmetIndex_path, "0.gff3"  ), file.path(pmetIndex_path, input$uploaded_annotation$name))
      file.rename(file.path(user_folder   , "0.txt"   ), genes_path)
    }
  } # if indexing

  if (!indexing) {
    if (identical(flag_upload_changed, c(0,0,0,0, 0,0,0,0,0,0))) {
      pmet_config$user_folder    <- ifelse(pairing_SUCCESS, previous_user_folder, user_folder)
      pmet_config$pmetIndex_path <- previsou_pmetindex_path
      pmet_config$pmetIndex_path <- pmetIndex_path
      pmet_config$genes_path     <- file.path(pmet_config$user_folder, input$gene_for_pmet$name)

      if (!pairing_SUCCESS) {
        system(paste("mkdir -p", pmet_config$user_folder))
        file.copy(input$gene_for_pmet$datapath, pmet_config$user_folder, overwrite = TRUE)
        file.rename(file.path(pmet_config$user_folder , "0.txt" ), pmet_config$genes_path)
      }

      pmet_config$indexing_pairing_needed  <- FALSE
      pmet_config$pairing_need_only        <- !pairing_SUCCESS
    } else {
      pmet_config$user_folder              <- user_folder
      pmet_config$pmetIndex_path           <- pmetIndex_path
      pmet_config$indexing_pairing_needed  <- FALSE
      pmet_config$pairing_need_only        <- TRUE
      pmet_config$genes_path               <- file.path(user_folder, input$gene_for_pmet$name)

      file.rename(file.path("result", session_id), pmet_config$user_folder)

      file.copy(input$gene_for_pmet$datapath , user_folder, overwrite = TRUE)
      file.rename(file.path(user_folder, "0.txt"), pmet_config$genes_path)
    }
  }# if !indexing

  return(pmet_config)
} # function definition