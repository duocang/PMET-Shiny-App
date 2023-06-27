# session_id is the name of folde to keep uploaded files from user
# because some data needed by PMET is not accessible after the session is closed
UPLOAD_DIR               <- "data/PMETindex/uploaded_motif"
session_id               <- runif(1, 100, 999999999) %/% 1
genes_skipped            <- reactiveVal(NULL) # store skipped genes for download handler
flag_first_run           <- reactiveVal(TRUE)
flag_upload_changed <- list(
  sequence_type       = 0,
  motif_db            = 0,
  uploaded_meme       = 0,
  uploaded_fasta      = 0,
  uploaded_annotation = 0,
  gene_for_pmet       = 0,
  promoter_length     = 0,
  max_motif_matches   = 0,
  promoter_number     = 0,
  utr5                = 0,
  promoters_overlap   = 0
)

# update motif database when motif db and sequence type changed --------------------
# 1. show/hide file inputs (selecton boxes)
# 2. reset file inputs
# 3. reset flags of first run and file inputs after the first run
observe({
  if (input$sequence_type == "intervals") {

    shinyjs::show("uploaded_meme_div")
    shinyjs::show("uploaded_fasta_div")

    shinyjs::hide("run_pmet_div")
    shinyjs::hide("motif_db")
    shinyjs::hide("uploaded_annotation_div")
    shinyjs::hide("utr5_div")
    for (i in c("uploaded_meme", "uploaded_fasta", "motif_annotation",
              "gene_for_pmet", "promoter_length", "promoter_number",
              "utr5", "promoters_overlap"
              )) {
      reset(i)
    }
    for (i in c("uploaded_meme", "uploaded_fasta", "motif_annotation", "gene_for_pmet")) {
      showFeedbackDanger(inputId = i, text = "")
    }
  } else if (input$motif_db != "uploaded_motif") {

    shinyjs::show("motif_db")
    shinyjs::show("utr5_div")

    # hide self upload option of motif DB
    shinyjs::hide("uploaded_meme_div")
    shinyjs::hide("uploaded_fasta_div")
    shinyjs::hide("uploaded_annotation_div")

    shinyjs::disable("promoter_length_div")
    shinyjs::disable("max_motif_matches_div")
    shinyjs::disable("promoter_number_div")
    shinyjs::disable("promoters_overlap_div")
    shinyjs::disable("utr5_div")
    for (i in c("uploaded_meme", "uploaded_fasta", "motif_annotation",
              "gene_for_pmet", "promoter_length", "promoter_number",
              "utr5", "promoters_overlap"
              )) {
      reset(i)
    }
    showFeedbackDanger(inputId = "gene_for_pmet", text = "")
  } else {
    # show self upload option of motif DB
    shinyjs::show("uploaded_meme_div")
    shinyjs::show("uploaded_fasta_div")
    shinyjs::show("uploaded_annotation_div")
    shinyjs::show("motif_db")

    shinyjs::enable("promoter_length_div")
    shinyjs::enable("max_motif_matches_div")
    shinyjs::enable("promoter_number_div")
    shinyjs::enable("utr5_div")
    shinyjs::enable("promoters_overlap_div")

    for (i in c("uploaded_meme", "uploaded_fasta", "motif_annotation",
              "gene_for_pmet", "promoter_length", "promoter_number",
              "utr5", "promoters_overlap"
              )) {
      reset(i)
    }
    for (i in c("uploaded_meme", "uploaded_fasta", "motif_annotation", "gene_for_pmet")) {
      showFeedbackDanger(inputId = i, text = "")
    }
  }
  Sys.sleep(1)
  # changes of seq type and motif database will reset first run flag
  # because it involves different PMETindexing process
  flag_first_run(TRUE)
  flag_upload_changed <<- list(
    sequence_type       = 0,
    motif_db            = 0,
    uploaded_meme       = 0,
    uploaded_fasta      = 0,
    uploaded_annotation = 0,
    gene_for_pmet       = 0,
    promoter_length     = 0,
    max_motif_matches   = 0,
    promoter_number     = 0,
    utr5                = 0,
    promoters_overlap   = 0
  )

}) # end of motif DB options


observeEvent(input$motif_db, {
  flag_upload_changed[["motif_db"]] <<- 1
}, ignoreInit = T)

observeEvent(input$sequence_type, {
  flag_upload_changed[["sequence_type"]] <<- 1
}, ignoreInit = T)

observeEvent(input$promoter_length, {
  flag_upload_changed[["promoter_length"]] <<- 1
}, ignoreInit = T)

observeEvent(input$max_motif_matches, {
  flag_upload_changed[["max_motif_matches"]] <<- 1
}, ignoreInit = T)

observeEvent(input$promoter_number, {
  flag_upload_changed[["promoter_number"]] <<- 1
}, ignoreInit = T)

observeEvent(input$utr5, {
  flag_upload_changed[["utr5"]] <<- 1
}, ignoreInit = T)

observeEvent(input$promoters_overlap, {
  flag_upload_changed[["promoters_overlap"]] <<- 1
}, ignoreInit = T)

# self uploaded motif database  ------------------------------------------------
# feedback for no file uploaded motif meme file
showFeedbackDanger(inputId = "uploaded_meme", text = "No motif meme files")
observeEvent(input$uploaded_meme, {
  # copy uploaded motif to session folder for PMET to run in the back
  temp_2_local_func(UPLOAD_DIR, session_id, input$uploaded_meme)

  flag_upload_changed[["uploaded_meme"]] <<- 1

  # indicators for file uploaded
  if (!is.null(input$uploaded_meme$datapath)) {
    showFeedbackSuccess(inputId = "uploaded_meme")
  } else {
    showFeedbackDanger(inputId = "uploaded_meme", text = "No motif")
  }
}, ignoreInit = T)

# self uploaded genome fasta  --------------------------------------------------
showFeedbackDanger(inputId = "uploaded_fasta", text = "No motif meme file")
observeEvent(input$uploaded_fasta, {
  # copy uploaded genome fasta to session folder for PMET to run in the back
  temp_2_local_func(UPLOAD_DIR, session_id, input$uploaded_fasta)

  flag_upload_changed[["uploaded_fasta"]] <<- 1

  # indicators for file uploaded
  if (!is.null(input$uploaded_fasta$datapath)) {
    showFeedbackSuccess(inputId = "uploaded_fasta")
  } else {
    showFeedbackDanger(inputId = "uploaded_fasta", text = "No motif")
  }
}, ignoreInit = T)

# self uploaded annotation  ----------------------------------------------------
showFeedbackDanger(inputId = "uploaded_annotation", text = "No annotation file")
observeEvent(input$uploaded_annotation, {
  # copy uploaded annotation to session folder for PMET to run in the back
  temp_2_local_func(UPLOAD_DIR, session_id, input$uploaded_annotation)

  flag_upload_changed[["uploaded_annotation"]] <<- 1

  # indicators for file uploaded
  if (!is.null(input$uploaded_annotation$datapath)) {
    showFeedbackSuccess(inputId = "uploaded_annotation")
  } else {
    showFeedbackDanger(inputId = "uploaded_annotation", text = "No annotation")
  }
}, ignoreInit = T)


# self genes uploaded -----------------------------------------------------------
# feedback for no file uploaded when page first opened
showFeedbackDanger(inputId = "gene_for_pmet", text = "No genes files")

observeEvent(input$gene_for_pmet, {
  # copy uploaded genes to result folder for PMET to run in the back
  temp_2_local_func("result", session_id, input$gene_for_pmet)
  flag_upload_changed[["gene_for_pmet"]] <<- 1

  # shinyjs::hide("skipped_genes_link")

  # inputs <- reactiveValuesToList(input)
  genes_status <- check_gene_file_fucn(input)

  if (length(genes_status) == 3) {
    genes_skipped(genes_status[[3]])
    shinyjs::show("skipped_genes_link")
    showFeedbackWarning(
      inputId = "gene_for_pmet",
      text = paste(genes_status[[1]], "out of", genes_status[[2]], "genes are skipped"))
  } else {
    shinyjs::hide("skipped_genes_link")
    switch(genes_status,
      "OK" = {
        showFeedbackSuccess(inputId = "gene_for_pmet")
      },
      "no_content" = {
        showFeedbackDanger(inputId = "gene_for_pmet", text = "No content in the file")
      },
      "wrong_column" = {
        showFeedbackDanger( inputId = "gene_for_pmet", text = "Only cluster and interval columns are allowed")
      },
      "gene_wrong_format" = {
        showFeedbackDanger( inputId = "gene_for_pmet", text = "Wrong format of uploaded file")
      },
      "intervals_wrong_format" = {
        showFeedbackDanger( inputId = "gene_for_pmet", text = "Genomic intervals pattern: chromosome:number-number.")
      },
      "no_valid_genes" = {
        showFeedbackDanger(inputId = "gene_for_pmet", text = "No valid genes available in the uploaded file")
      })
  }
}, ignoreInit = T)

# modal dialog shown, when link clicked (skipped genes are not nul)
observeEvent(input$skipped_genes_link, {
  if (!is.null(genes_skipped())) {
    Sys.sleep(0.2)
    showModal(modalDialog(
      title = "Skipped genes:",
      DT::renderDataTable({ genes_skipped() }),
      footer = tagList(
        downloadButton("skipped_genes_down_btn", "Download"),
        modalButton("Cancel"))
    )) # end of showModal
  }
})

# Download Skipped genes when button clicked -----------------------------------
output$skipped_genes_down_btn <- downloadHandler(
  filename = function() {
    "genes_skipped.txt"
  },
  content = function(file) { write.table(genes_skipped(), file, quote = FALSE, row.names = FALSE) }
) # downLoadHandler end

# Download example genes file for PMET ---------------------------------------
output$demo_genes_file_link <- downloadHandler(
  filename = function() {
    "example_genes.txt"
  },
  content = function(file) {
    write.table(read.table("data/example_genes.txt"), file, quote = FALSE, row.names = FALSE, col.names = FALSE)
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
    showFeedbackDanger(inputId = "userEmail", text = "Email needed")
  } else if (valid.email.func(input$userEmail)) { # invalid email
    showFeedbackSuccess(inputId = "userEmail", text = "Results will be sent via Email.")
  } else { # valid email
    showFeedbackWarning(inputId = "userEmail", text = "invalid Email")
  }
})
# iv <- InputValidator$new()
#   iv$add_rule("userEmail", sv_required())
#   iv$add_rule("userEmail", sv_email())
#   iv$enable()

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
pmetPair_path  <- ""
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


    # previous_paths["pmetPair_path" ] <- pmetPair_path
    # previous_paths["pmetIndex_path"] <- pmetIndex_path
    previous_paths <- list(pmetPair_path = pmetPair_path, pmetIndex_path=pmetIndex_path)
    print("后十八届")
    print(previous_paths)
    mode           <- pmet_mode_func(input)
    pmet_config    <- paths_of_repeative_run_func(input,
                                                  session_id,
                                                  previous_paths,
                                                  flag_upload_changed,
                                                  flag_first_run(),
                                                  mode)

    pmetPair_path    <<- pmet_config$pmetPair_path
    pmetIndex_path   <<- pmet_config$pmetIndex_path

    inputs <- reactiveValuesToList(input)
    # PMET job is runnig in the back
    future_promise({
      command_run_pmet( inputs,
                        pmetIndex_path,
                        pmetPair_path,
                        pmet_config$genes_path,
                        pmet_config$indexing_pairing_needed,
                        pmet_config$pairing_need,
                        mode)
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
      flag_upload_changed <<- list(
        sequence_type       = 0,
        motif_db            = 0,
        uploaded_meme       = 0,
        uploaded_fasta      = 0,
        uploaded_annotation = 0,
        gene_for_pmet       = 0,
        promoter_length     = 0,
        max_motif_matches   = 0,
        promoter_number     = 0,
        utr5                = 0,
        promoters_overlap   = 0
      )
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
    # system(paste0("kill -9 ", pid))

    # system(paste0("rm -rf ", "result/", pmetPair_path))
    # system(paste0("rm -rf ", "result/", pmetPair_path, ".zip"))

    showNotification("PMET had been stopped!!!", type = "error", duration = 0)

    resetLoadingButton("run_pmet_button")
    shinyjs::enable("run_pmet_button")
    shinyjs::hide("stop_bnt_div")
    shinyjs::hide("pmet_result_download_button")
    removeNotification(notifi_pmet_id)
  }
}, ignoreInit = T)

# hide download button every time change gene file
observeEvent(c( input$motif_db, input$uploaded_fasta_div, input$uploaded_annotation_div,
                input$gene_for_pmet_div, input$promoter_length, input$max_motif_matches,
                input$promoter_number, input$utr5, input$promoters_overlap,
                input$userEmail_div), {
  shinyjs::hide("pmet_result_download_button")
})

observeEvent(input$test, {

  print("FDA发腮阿赛发腮")

})
