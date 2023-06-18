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


temp <- runif(1, 100, 99999999) %/% 1

# self uploaded motif database  ------------------------------------------------
# feedback for no file uploaded motif meme file
showFeedbackDanger(inputId = "uploaded_motif_db", text = "No motif meme files")
observeEvent(input$uploaded_motif_db, {
  # copy uploaded motif
  system(paste("mkdir -p", file.path("data/PMETindex/uploaded_motif", temp)))
  file.copy(input$uploaded_motif_db$datapath, file.path("data/PMETindex/uploaded_motif", temp), overwrite = TRUE)
  file.rename(file.path("data/PMETindex/uploaded_motif", temp, "0.meme"),
              file.path("data/PMETindex/uploaded_motif", temp, input$uploaded_motif_db$name))

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
  # copy uploaded genome fasta
  system(paste("mkdir -p", file.path("data/PMETindex/uploaded_motif", temp)))
  file.copy(input$uploaded_fasta$datapath,
            file.path("data/PMETindex/uploaded_motif", temp),
            overwrite = TRUE)
  fasta_temp <- ifelse(endsWith(input$uploaded_fasta$name, "fa"), "0.fa", "0.fasta")
  file.rename(file.path("data/PMETindex/uploaded_motif", temp, fasta_temp),
              file.path("data/PMETindex/uploaded_motif", temp, input$uploaded_fasta$name))

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
  # copy uploaded annotation
  system(paste("mkdir -p", file.path("data/PMETindex/uploaded_motif", temp)))
  file.copy(input$uploaded_annotation$datapath,
            file.path("data/PMETindex/uploaded_motif", temp), overwrite = TRUE)
  file.rename(file.path("data/PMETindex/uploaded_motif", temp, "0.gff3"),
              file.path("data/PMETindex/uploaded_motif", temp, input$uploaded_annotation$name))

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
  # copy uploaded genes
  system(paste("mkdir -p", file.path("result", temp)))
  file.copy(input$gene_for_pmet$datapath, file.path("result", temp), overwrite = TRUE)
  file.rename(file.path("result", temp, "0.txt"),
              file.path("result", temp, input$gene_for_pmet$name))
  # system(paste("mkdir -p", file.path("data/PMETindex/uploaded_motif", temp)))
  # file.copy(input$gene_for_pmet$datapath, file.path("data/PMETindex/uploaded_motif", temp), overwrite = TRUE)
  # file.rename(file.path("data/PMETindex/uploaded_motif", temp, "0.txt"),
  #             file.path("data/PMETindex/uploaded_motif", temp, input$gene_for_pmet$name))


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
    showFeedbackDanger(
      inputId = "gene_for_pmet",
      text = "Wrong format of uploaded file"
    )
  } else if (nrow(genes_uploaded) == 0) {
    genes_uploaded_falg <<- FALSE
    hideFeedback("gene_for_pmet")
    showFeedbackDanger(inputId = "gene_for_pmet", text = "Empty file")
  } else if (ncol(genes_uploaded) != 2) {
    genes_uploaded_falg <<- FALSE

    hideFeedback("gene_for_pmet")
    showFeedbackDanger(
      inputId = "gene_for_pmet",
      text = "Only cluster and gene columns are allowed"
    )
  } else if (input$motif_db != "uploaded_motif") {
    # if motifs selected, check the uploaded genes
    # with the gene list in our folder, named universe.txt

    # species <- str_split(input$motif_db, "-")[[1]][1]
    species <- ifelse(input$motif_db != "uploaded_motif",
      str_split(input$motif_db, "-")[[1]][1],
      "uploaded_motif"
    )

    project_path <- getwd() # %>% str_replace("01_shiny", "")
    input_directory <- file.path(project_path, "data/PMETindex", species, input$motif_db)
    genes_universe <- read.table(file.path(input_directory, "universe.txt")) %>% `colnames<-`(c("gene"))


    colnames(genes_uploaded) <- c("cluster", "gene")
    genes_present <- dplyr::inner_join(genes_uploaded, genes_universe, by = "gene")
    genes_skipped <<- setdiff(genes_uploaded, genes_present)
    print(genes_skipped)

    # no genes available in the uploaded file
    if (nrow(genes_skipped) == nrow(genes_uploaded)) {
      genes_uploaded_falg <<- FALSE
      hideFeedback("gene_for_pmet")
      showFeedbackDanger(inputId = "gene_for_pmet", text = "No valid genes available in the uploaded file")
    } else if (nrow(genes_uploaded) != nrow(genes_present)) {
      hideFeedback("gene_for_pmet")
      showFeedbackWarning(
        inputId = "gene_for_pmet",
        text = paste0(
          nrow(genes_skipped),
          " out of ",
          nrow(genes_uploaded),
          " genes are skipped"
        )
      )
    } # end of if (nrow(genes_skipped) == nrow(genes_uploaded))
    shinyjs::show("skipped_genes_link")
  } # end of if (is.null(genes_uploaded)) else
})

# modal dialog shown, when link clicked (skipped genes are not nul)
observeEvent(input$skipped_genes_link, {
  print("skipped_genes_link")
  if (!is.null(genes_skipped)) {
    print(genes_skipped)
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
folder_name <- "" # a global variable to track current job (folder/path)
notifi_pmet_id <- NULL # id to remove notification when stop pmet job
observeEvent(input$run_pmet_button, {
  folder_name <<- ""
  notifi_pmet_id <<- NULL

  # hide download button
  shinyjs::hide("pmet_result_download_button")

  if (valid.files.email.func(input)) {
    # When butn clicked, wrap the code in a call to `withBusyIndicatorServer()`
    withBusyIndicatorServer("sf-loading-button-run_pmet_button", {
      Sys.sleep(0.5)
      if (FALSE) {
        stop("choose another option")
      }
    })

    shinyjs::disable("run_pmet_button")
    shinyjs::show("stop_bnt_div")
    runjs('document.getElementById("stop_bnt_div").scrollIntoView();')

    notifi_pmet_id <<- showNotification("PMET is running...", type = "message", duration = 0)

    paths_pmet <- paths.for.pmet.func(input)
    folder_name <<- paths_pmet$folder_name
    user_folder <<- paths_pmet$user_folder

    list_of_inputs <- reactiveValuesToList(input)

    # rename temp folder
    paths_pmet <- paths.for.pmet.func(list_of_inputs)
    file.rename(file.path("result", temp), paths_pmet$user_folder)
    file.rename(file.path("data/PMETindex/uploaded_motif", temp), paths_pmet$pmetIndex_path)


    # PMET job is runnig in the back
    future({
      command_run_pmet(list_of_inputs, paths_pmet)
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
    }) # end of future
    cli::cat_rule(sprintf("pmet 的任务我已经提交了！"))
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
  cli::cat_rule(sprintf("任务被取消了！"))
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
