# workthrough of Run PMET ----------------------------------------------------
run_pmet_steps <- reactive({
  elements <- c(
    "#promoters_div",
    "#species_div",
    "#motif_db_div",
    "#gene_for_pmet_div",
    "#parameters_div",
    "#userEmail_div"
  )
  intors <- c(
    "Choose type of input sequences",
    "Choose plant",
    "Upload your own motif file or choose from the available defaults",
    "A tab separated file containing the gene set number and gene.",
    "Fine tuning of PMET",
    "Email address to receive notifications"
  )
  data.frame(element = elements, intro = intors)
})


# update motif database when species changed ---------------------------------
observeEvent(input$species, {
  species <- input$species %>%
    tolower() %>%
    str_replace_all(" ", "_")

  dbs <- switch(species,
    "arabidopsis_thaliana" = c("jaspar_2018", "jaspar_2022", "plant_cistrome_DB")
  )
  updateSelectInput(session, inputId = "motif_db", label = "Motif database", choices = dbs)
})

# feedback for no file uploaded when page first opened
showFeedbackDanger(inputId = "gene_for_pmet", text = "No genes files")

genes_skipped <- NULL # store skipped genes for download handler
genes_uploaded_falg <- TRUE # flag, set to FALSE when no valid genes were uploaded

observeEvent(input$gene_for_pmet, {
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

  # save genes file to results directory
  species <- input$species %>%
    tolower() %>%
    str_replace_all(" ", "_")
  project_path <- getwd() # %>% str_replace("01_shiny", "")
  input_directory <- file.path(project_path, "data/PMETindex", species, input$motif_db)
  genes_universe <- read.table(file.path(input_directory, "universe.txt")) %>% `colnames<-`(c("gene"))

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
    hideFeedback("gene_for_pmet")
    showFeedbackDanger(inputId = "gene_for_pmet", text = "Wrong format of uploaded file")
  } else if (nrow(genes_uploaded) == 0) {
    hideFeedback("gene_for_pmet")
    showFeedbackDanger(inputId = "gene_for_pmet", text = "Empty file")
  } else if (ncol(genes_uploaded) != 2) {
    print("Wrong column")
    hideFeedback("gene_for_pmet")
    showFeedbackDanger(inputId = "gene_for_pmet", text = "Only cluster and gene columns are allowed")
  } else {
    colnames(genes_uploaded) <- c("cluster", "gene")
    genes_present <- dplyr::inner_join(genes_uploaded, genes_universe, by = "gene")
    genes_skipped <<- setdiff(genes_uploaded, genes_present)
    print(genes_skipped)

    # no genes available in the uploaded file
    if (nrow(genes_skipped) == nrow(genes_uploaded)) {
      print("No valid genes available in the uploaded file")
      genes_uploaded_falg <<- FALSE
      hideFeedback("gene_for_pmet")
      showFeedbackDanger(inputId = "gene_for_pmet", text = "No valid genes available in the uploaded file")
    } else if (nrow(genes_uploaded) != nrow(genes_present)) {
      print("Some genes are not available in the uploaded file")
      hideFeedback("gene_for_pmet")
      showFeedbackWarning(inputId = "gene_for_pmet", text = paste0(nrow(genes_skipped), " out of ", nrow(genes_uploaded), " genes are skipped"))
    } # end of if (nrow(genes_skipped) == nrow(genes_uploaded))

    # modal dialog: if any genes are not present
    shinyjs::show("skipped_genes_link")
    # Sys.sleep(0.5)
    # showModal(modalDialog(
    #   title = "Skipped genes:",
    #   DT::renderDataTable({
    #     genes_skipped
    #   }),
    #   footer = tagList(
    #     downloadButton("skipped_genes_down_btn", "Download"),
    #     modalButton("Cancel")
    #   )
    # )) # end of showModal
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
    data <- read.table("data/genes.txt")
    write.table(data, file, quote = FALSE, row.names = FALSE, col.names = FALSE)
  }
)


# feedback for no email ------------------------------------------------------
observeEvent(input$userEmail, {
  if (input$userEmail == "") { # no typing
    hideFeedback("userEmail")
    showFeedbackDanger(inputId = "userEmail", text = "Email needed")
  } else if (isValidEmail(input$userEmail)) { # invalid email
    hideFeedback("userEmail")
    showFeedbackSuccess(inputId = "userEmail", text = "Results will be sent to you Email.")
  } else { # valid email
    hideFeedback("userEmail")
    showFeedbackWarning(inputId = "userEmail", text = "invalid Email")
  }
})

# show/hide Run button ()
observe({
  if (!is.null(input$gene_for_pmet$datapath) & isValidEmail(input$userEmail) & genes_uploaded_falg) {
    shinyjs::show("run_pmet_button_div")
  } else {
    shinyjs::hide("run_pmet_button_div")
  }
})

# Run PMET -------------------------------------------------------------------
os <- Sys.info()["sysname"]
# a global variable to track current job (folder/path)
folder_name <- ""
notifi_pmet_id <- NULL # id to remove notification when stop pmet job
observeEvent(input$run_pmet_button, {
  folder_name <<- ""
  notifi_pmet_id <<- NULL

  # hide download button
  shinyjs::hide("pmet_result_download_button")

  if (!is.null(input$gene_for_pmet) & isValidEmail(input$userEmail)) {
    # When the button is clicked, wrap the code in a call to `withBusyIndicatorServer()`
    withBusyIndicatorServer("sf-loading-button-run_pmet_button", {
      Sys.sleep(0.5)
      if (FALSE) {
        stop("choose another option")
      }
    })
    shinyjs::disable("run_pmet_button")
    shinyjs::show("stop_bnt_div")
    runjs('document.getElementById("stop_bnt_div").scrollIntoView();')
    notifi_pmet_id <<- showNotification("PMET is running...",
      type = "message",
      duration = 0
    )

    genes_path <- input$gene_for_pmet$datapath
    project_path <- getwd() # %>% str_replace("/01_shiny", "")
    species <- input$species %>%
      tolower() %>%
      str_replace_all(" ", "_")

    pmetIndex_path <- file.path(project_path, "data/PMETindex", species, input$motif_db)
    folder_name <<- str_split(input$userEmail, "@")[[1]] %>%
      paste0(collapse = "_") %>%
      paste0("_", species, "_", input$motif_db) %>%
      paste0("_", format(Sys.time(), "%Y%b%d_%H%M"))

    user_folder <<- file.path(project_path, "result", folder_name)

    # PMET job is runnig in the back
    future({
      command_run_pmet(project_path, pmetIndex_path, user_folder, genes_path, os)
    }) %...>% (function(result_link) {
      cli::cat_rule(sprintf("pmet 完成了！"))

      Sys.sleep(0.5)
      # 1. reset the loadingButton (RUN PMET) to its active state after PMET DONE
      # 2. hide STOP button
      resetLoadingButton("run_pmet_button")
      shinyjs::enable("run_pmet_button")
      shinyjs::hide("stop_bnt_div")
      removeNotification(notifi_pmet_id)
      showNotification("PMET finished.", type = "error", duration = 0)

      # # dynamically create a button after PMET done to download PMET result
      # output$pmet_result_download_ui <- renderUI({
      #   downloadButton("pmet_result_download_button", "PMET result", style = "width: 135px")
      # })

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
      })
      runjs('document.getElementById("pmet_result_download_ui_div").scrollIntoView();')
    })
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
# activities when stop pmet job
observeEvent(input$stop, {
  cli::cat_rule(sprintf("任务被取消了！"))

  pid <- system("pidof pmetParallel", intern = TRUE)
  # when pmetParaleel is finished, there will be no pid returned.
  if (!identical(pid, character(0))) {
    system(paste0("kill -9 ", pid))
    system(paste0("rm -rf ", user_folder))

    showNotification("PMET had been stopped!!!", type = "error", duration = 0)

    resetLoadingButton("run_pmet_button")
    shinyjs::enable("run_pmet_button")
    shinyjs::hide("stop_bnt_div")
    shinyjs::hide("pmet_result_download_button")
    removeNotification(notifi_pmet_id)
  }
})

# it is commented because nginx used
# # Download PMET result zipped ------------------------------------------------
# output$pmet_result_download_button <- downloadHandler(
#   filename = function() {
#     "pmet_result.zip"
#   },
#   content = function(file) {
#     fs <- dir(file.path("result", folder_name)) %>%
#       file.path("result", folder_name, .)
#     zip::zip(file, files = fs, mode = "cherry-pick")
#   },
#   contentType = "application/zip"
# )

# hide download button every time change gene file
observeEvent(input$gene_for_pmet, {
  shinyjs::hide("pmet_result_download_button")
})
