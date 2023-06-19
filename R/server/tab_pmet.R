# update motif database when motif db changed --------------------------------
observe({

  if (input$sequence_type == "intervals") {

    shinyjs::show("uploaded_motif_db_div")
    shinyjs::show("uploaded_fasta_div")

    shinyjs::hide("motif_db")
    shinyjs::hide("uploaded_annotation_div")
    shinyjs::hide("utr5_div")
  } else if (input$motif_db != "uploaded_motif") {

    shinyjs::show("motif_db")
    shinyjs::show("utr5_div")

    # hide self upload option of motif DB
    shinyjs::hide("uploaded_motif_db_div")
    shinyjs::hide("uploaded_fasta_div")
    shinyjs::hide("uploaded_annotation_div")

    shinyjs::disable("promoter_length_div")
    shinyjs::disable("max_motif_matches_div")
    shinyjs::disable("promoter_number_div")
    shinyjs::disable("promoters_overlap_div")
    shinyjs::disable("utr5_div")
  } else {
    # show self upload option of motif DB
    shinyjs::show("uploaded_motif_db_div")
    shinyjs::show("uploaded_fasta_div")
    shinyjs::show("uploaded_annotation_div")

    shinyjs::enable("promoter_length_div")
    shinyjs::enable("max_motif_matches_div")
    shinyjs::enable("promoter_number_div")
    shinyjs::enable("utr5_div")
    shinyjs::enable("promoters_overlap_div")
  }
}) # end of motif DB options

# session_id is the name of folde to keep uploaded files from user
# because some data needed by PMET is not accessible after the session is closed
UPLOAD_DIR<- "data/PMETindex/uploaded_motif"

session_id <- runif(1, 100, 999999999) %/% 1
flag_first_run <- reactiveVal(TRUE)


flag_upload_changed <- reactiveVal(c( 0, 0, 0, 0, 1, 1, 1, 1, 1, 1))

# self uploaded motif database  ------------------------------------------------
# feedback for no file uploaded motif meme file
showFeedbackDanger(inputId = "uploaded_motif_db", text = "No motif meme files")
observeEvent(input$uploaded_motif_db, {
  # copy uploaded motif to session folder for PMET to run in the back
  temp_2_local_func(UPLOAD_DIR, session_id, input$uploaded_motif_db)

  flag_upload_changed(as.numeric(c(1, 0, 0, 0, 0, 0, 0, 0, 0, 0) | flag_upload_changed()))

  # indicators for file uploaded
  if (!is.null(input$uploaded_motif_db$datapath)) {
    hideFeedback("uploaded_motif_db")
    showFeedbackSuccess(inputId = "uploaded_motif_db")
  } else {
    showFeedbackDanger(inputId = "uploaded_motif_db", text = "No motif")
  }
})

# self uploaded genome fasta  --------------------------------------------------
showFeedbackDanger(inputId = "uploaded_fasta", text = "No motif meme file")
observeEvent(input$uploaded_fasta, {
  # copy uploaded genome fasta to session folder for PMET to run in the back
  temp_2_local_func(UPLOAD_DIR, session_id, input$uploaded_fasta)

  flag_upload_changed(as.numeric(c(0, 1, 0, 0, 0, 0, 0, 0, 0, 0) | flag_upload_changed()))

  # indicators for file uploaded
  if (!is.null(input$uploaded_fasta$datapath)) {
    hideFeedback("uploaded_fasta")
    showFeedbackSuccess(inputId = "uploaded_fasta")
  } else {
    showFeedbackDanger(inputId = "uploaded_fasta", text = "No motif")
  }
})

# self uploaded annotation  ----------------------------------------------------
showFeedbackDanger(inputId = "uploaded_annotation", text = "No annotation file")
observeEvent(input$uploaded_annotation, {
  # copy uploaded annotation to session folder for PMET to run in the back
  temp_2_local_func(UPLOAD_DIR, session_id, input$uploaded_annotation)

  flag_upload_changed(as.numeric(c(0, 0, 1, 0, 0, 0, 0, 0, 0, 0) | flag_upload_changed()))

  # indicators for file uploaded
  if (!is.null(input$uploaded_annotation$datapath)) {
    hideFeedback("uploaded_annotation")
    showFeedbackSuccess(inputId = "uploaded_annotation")
  } else {
    showFeedbackDanger(inputId = "uploaded_annotation", text = "No annotation")
  }
})


# genes uploaded ---------------------------------------------------------------
# feedback for no file uploaded when page first opened
showFeedbackDanger(inputId = "gene_for_pmet", text = "No genes files")
genes_skipped <- NULL # store skipped genes for download handler
genes_uploaded_falg <- TRUE # flag, set to FALSE when no valid genes were uploaded
observeEvent(input$gene_for_pmet, {
  # copy uploaded genes to result folder for PMET to run in the back
  system(paste("mkdir -p", file.path("result", session_id)))
  file.copy(input$gene_for_pmet$datapath, file.path("result", session_id), overwrite = TRUE)
  file.rename(file.path("result", session_id, "0.txt"),
              file.path("result", session_id, input$gene_for_pmet$name))

  flag_upload_changed(as.numeric(c(0, 0, 0, 1, 0, 0, 0, 0, 0, 0) | flag_upload_changed()))

  genes_skipped <<- NULL
  genes_uploaded_falg <<- TRUE

  # indicators for file uploaded
  shinyjs::hide("skipped_genes_link")
  if (!is.null(input$gene_for_pmet$datapath)) {
    hideFeedback("gene_for_pmet")
    showFeedbackSuccess(inputId = "gene_for_pmet")
  } else {
    showFeedbackDanger(inputId = "gene_for_pmet", text = "No genes")
  }

  # read gene file uploaded
  genes_uploaded <- tryCatch(
    {
      read.table(input$gene_for_pmet$datapath)
    },
    error = function(e) {
      message("Error: ", e$message)
      NULL
    }
  )
  # wrong format of uploaded file
  # 1. NULL of the file
  # 2. no data in the file
  # 3. wrong column in the file
  # 4. genes are not in TAIR10 fo example
  if (is.null(genes_uploaded)) {
    genes_uploaded_falg <<- FALSE
    hideFeedback("gene_for_pmet")
    showFeedbackDanger( inputId = "gene_for_pmet", text = "Wrong format of uploaded file")
  } else if (nrow(genes_uploaded) == 0) {
    genes_uploaded_falg <<- FALSE
    hideFeedback("gene_for_pmet")
    showFeedbackDanger(inputId = "gene_for_pmet", text = "Empty file")
  } else if (ncol(genes_uploaded) != 2) {
    genes_uploaded_falg <<- FALSE

    hideFeedback("gene_for_pmet")
    showFeedbackDanger( inputId = "gene_for_pmet", text = "Only cluster and gene columns are allowed")
  } else if (input$motif_db != "uploaded_motif") {
    # if motifs selected, check the uploaded genes
    # with the gene list in our folder, named universe.txt

    # species <- str_split(input$motif_db, "-")[[1]][1]
    species <- ifelse(input$motif_db != "uploaded_motif",
      str_split(input$motif_db, "-")[[1]][1],
      "uploaded_motif"
    )

    input_directory <- file.path("data/PMETindex", species, input$motif_db)
    genes_universe <- read.table(file.path(input_directory, "universe.txt")) %>% `colnames<-`(c("gene"))


    colnames(genes_uploaded) <- c("cluster", "gene")
    genes_present <- dplyr::inner_join(genes_uploaded, genes_universe, by = "gene")
    genes_skipped <<- setdiff(genes_uploaded, genes_present)

    # no genes available in the uploaded file
    if (nrow(genes_skipped) == nrow(genes_uploaded)) {
      genes_uploaded_falg <<- FALSE
      hideFeedback("gene_for_pmet")
      showFeedbackDanger(inputId = "gene_for_pmet", text = "No valid genes available in the uploaded file")
    } else if (nrow(genes_uploaded) != nrow(genes_present)) {
      hideFeedback("gene_for_pmet")
      showFeedbackWarning(
        inputId = "gene_for_pmet",
        text = paste(nrow(genes_skipped), "out of", nrow(genes_uploaded), "genes are skipped")
      )
    } # end of if (nrow(genes_skipped) == nrow(genes_uploaded))
    shinyjs::show("skipped_genes_link")
  } # end of if (is.null(genes_uploaded)) else
})

# modal dialog shown, when link clicked (skipped genes are not nul)
observeEvent(input$skipped_genes_link, {
  if (!is.null(genes_skipped)) {
    Sys.sleep(0.2)
    showModal(modalDialog(
      title = "Skipped genes:",
      DT::renderDataTable({
        genes_skipped
      }),
      footer = tagList(
        downloadButton("skipped_genes_down_btn", "Download"),
        modalButton("Cancel")
      )
    )) # end of showModal
  }
})

# Download Skipped genes when button clicked -----------------------------------
output$skipped_genes_down_btn <- downloadHandler(
  filename = function() {
    "genes_skipped.txt"
  },
  content = function(file) {
    write.table(genes_skipped, file, quote = FALSE, row.names = FALSE)
  }
) # downLoadHandler end

# Download example genes file for PMET ---------------------------------------
output$demo_genes_file_link <- downloadHandler(
  filename = function() {
    "example_genes.txt"
  },
  content = function(file) {
    data <- read.table("data/example_genes.txt")
    write.table(data, file, quote = FALSE, row.names = FALSE, col.names = FALSE)
  }
)

output$demo_motif_db_link <- downloadHandler(
  filename = function() {
    "example_motif.meme"
  },
  content = function(file) {
    data <- readLines("data/example_motif.meme")
    writeLines(data, file)
  }
)

# feedback for no email --------------------------------------------------------
observeEvent(input$userEmail, {
  if (input$userEmail == "") { # no typing
    hideFeedback("userEmail")
    showFeedbackDanger(inputId = "userEmail", text = "Email needed")
  } else if (valid.email.func(input$userEmail)) { # invalid email
    hideFeedback("userEmail")
    showFeedbackSuccess(inputId = "userEmail", text = "Results will be sent via Email.")
  } else { # valid email
    hideFeedback("userEmail")
    showFeedbackWarning(inputId = "userEmail", text = "invalid Email")
  }
})

# show/hide Run button () ------------------------------------------------------
observe({
  if (valid.files.email.func(input)) {
    shinyjs::show("run_pmet_button_div")
  } else {
    shinyjs::hide("run_pmet_button_div")
  }
})

# Run PMET ---------------------------------------------------------------------
folder_name    <- "" # a global variable to track current job (folder/path)
user_folder    <- ""
pmetIndex_path <- ""
notifi_pmet_id <- NULL # id to remove notification when stop pmet job

observeEvent(input$run_pmet_button, {

  # hide download button
  shinyjs::hide("pmet_result_download_button")

  if (valid.files.email.func(input)) {
    # When run butn clicked, wrap the code in a call to `withBusyIndicatorServer()`
    withBusyIndicatorServer("sf-loading-button-run_pmet_button", {
      Sys.sleep(0.5)
      if (FALSE) { stop("choose another option") }
    })

    shinyjs::disable("run_pmet_button")
    shinyjs::show("stop_bnt_div")
    runjs('document.getElementById("stop_bnt_div").scrollIntoView();')

    notifi_pmet_id <<- showNotification("PMET is running...", type = "message", duration = 0)

    if (flag_first_run()) {
      paths_pmet     <-  paths_for_pmet_func(input)
      folder_name    <<- paths_pmet$folder_name
      user_folder    <<- paths_pmet$user_folder
      pmetIndex_path <<- paths_pmet$pmetIndex_path
      genes_path     <-  paths_pmet$genes_path

      # rename temp folder in first run of PMET
      file.rename(file.path("result", session_id), paths_pmet$user_folder)
      if (!is.null(input$uploaded_motif_db)) {
        file.rename(file.path(UPLOAD_DIR, session_id), paths_pmet$pmetIndex_path)
      }

      indexing_pairing <- !is.null(input$uploaded_motif_db)
      pairing_only     <- is.null(input$uploaded_motif_db)
    } else {
      previous_user_folder    <- user_folder
      previsou_pmetindex_path <- pmetIndex_path

      paths_pmet     <-  paths_for_pmet_func(input)
      user_folder    <<- paths_pmet$user_folder
      pmetIndex_path <<- paths_pmet$pmetIndex_path

      pmet_config <- paths_of_repeative_run_func( input,
                                                  session_id,
                                                  user_folder,
                                                  pmetIndex_path,
                                                  previous_user_folder,
                                                  previsou_pmetindex_path,
                                                  flag_upload_changed(),
                                                  !is.null(input$uploaded_motif_db))

      user_folder      <<- pmet_config$user_folder
      pmetIndex_path   <<- pmet_config$pmetIndex_path
      genes_path       <-  pmet_config$genes_path
      indexing_pairing <- pmet_config$indexing_pairing_needed
      pairing_only     <- pmet_config$pairing_need_only
    }

    # PMET job is runnig in the back
    future({
      command_run_pmet( input,
                        pmetIndex_path,
                        user_folder,
                        genes_path,
                        indexing_pairing=indexing_pairing,
                        pairing_only = pairing_only)
    }) %...>% (function(result_link) {
      cli::cat_rule(sprintf("pmet done!"))
      Sys.sleep(0.5)
      # 1. reset loadingButton (RUN PMET) to its active state after PMET DONE
      # 2. hide STOP button
      resetLoadingButton("run_pmet_button")
      shinyjs::enable("run_pmet_button")
      shinyjs::hide("stop_bnt_div")
      removeNotification(notifi_pmet_id)
      showNotification("PMET finished.", type = "error", duration = 0)

      # download button for ngxin file
      print(result_link)
      output$pmet_result_download_ui <- renderUI({
        actionButton(
          "pmet_result_download_button",
          "PMET result",
          icon = icon("download"),
          onclick = paste0("location.href='", result_link, "'"),
          style = "width: 135px"
        )
      }) # end of rednderUI
      # automatically scroll to the spot of download button
      runjs('document.getElementById("pmet_result_download_ui_div").scrollIntoView();')

      # when PMET done, then it is not the first time of PMET
      flag_first_run(FALSE) #
      flag_upload_changed(c(0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
    }) # end of future
    cli::cat_rule(sprintf("pmet task starts！"))
  } else { # when clikc RUN PMET button withouth valid job

    # reset the loadingButton to its active state after 3 seconds
    resetLoadingButton("run_pmet_button")
    # the prefix "sf-loading-button-" comes from loadingButton
    withBusyIndicatorServer("sf-loading-button-run_pmet_button", {
      Sys.sleep(0.5)
      if (is.null(input$gene_for_pmet$datapath) | is.null(input$userEmail)) {
        stop("Upload gene file")
      } else {
        stop("Email needed")
      }
    })
  } # end of if else
})


# STOP buttion: activities when stop pmet job------------------------------------------------
observeEvent(input$stop, {

  cli::cat_rule(sprintf("Task stops！"))
  print(folder_name)


  pid <- pid.pmet.finder.func(folder_name)
  print(pid)

  # when pmetParaleel is finished, there will be no pid returned.
  if (!identical(pid, character(0))) {
    system(paste0("kill -9 ", pid))
    # system(paste0("rm -rf ", "result/", user_folder))
    # system(paste0("rm -rf ", "result/", user_folder, ".zip"))

    showNotification("PMET had been stopped!!!", type = "error", duration = 0)

    resetLoadingButton("run_pmet_button")
    shinyjs::enable("run_pmet_button")
    shinyjs::hide("stop_bnt_div")
    shinyjs::hide("pmet_result_download_button")
    removeNotification(notifi_pmet_id)
  }
})


# hide download button every time change gene file
observeEvent(input$gene_for_pmet, {
  shinyjs::hide("pmet_result_download_button")
})
