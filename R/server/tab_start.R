# use this list for all your toasts
myToastOptions <- list(
  positionClass = "toast-bottom-right",
  progressBar = TRUE,
  timeOut = 600000,
  closeButton = TRUE,

  # same as defaults
  newestOnTop = TRUE,
  preventDuplicates = FALSE,
  showDuration = 300,
  hideDuration = 1000,
  extendedTimeOut = 1000,
  showEasing = "linear",
  hideEasing = "linear",
  showMethod = "fadeIn",
  hideMethod = "fadeOut"
)


# job_id is the name of folde to keep uploaded files from user
# because some data needed by PMET is not accessible after shiny session is closed
UPLOAD_DIR    <- "result/indexing"
job_id        <- runif(1, 100, 999999999) %/% 1

trig <- reactiveVal(FALSE)
observeEvent(input$show_tutorial, {
  trig(!trig())
})

promoters_handler     <- promoters_server    ("promoters",     job_id, trig, reactive(input$mode), reactive(input$navbar))
promoters_pre_handler <- promoters_pre_server("promoters_pre", job_id, trig, reactive(input$mode), reactive(input$navbar))
intervals_handler     <- intervals_server    ("intervals",     job_id, trig, reactive(input$mode), reactive(input$navbar))


output$mode_ui <-  renderUI({
  switch(input$mode,
    "promoters_pre" = { promoters_pre_ui("promoters_pre") },
    "promoters"     = { promoters_ui("promoters") },
    "intervals"     = { intervals_ui("intervals") }
  )})

# feedback for no email --------------------------------------------------------
observeEvent(input$userEmail, {
  if (input$userEmail == "") { # no typing
    hideFeedback(inputId = "userEmail")
    showFeedbackDanger(inputId = "userEmail", text = "Email needed")
  } else if (ValidEmail(input$userEmail)) { # invalid email
    hideFeedback(inputId = "userEmail")
    showFeedbackSuccess(inputId = "userEmail", text = "Results will be sent via Email.")
  } else { # valid email
    hideFeedback(inputId = "userEmail")
    showFeedbackWarning(inputId = "userEmail", text = "invalid Email")
  }
})


# show Run button () -----------------------------------------------------------
# when the following requirements are met:
# 1. all input is required
# 2. gene file is a file with 2 columns
# 3. valid email is provided
observe({
  # when input changed
  # hide spinner (indicator for job running)
  # hide run and download buttions
  hide_spinner()
  shinyjs::hide("toast-container")
  shinyjs::hide("run_pmet_button_div")
  shinyjs::hide("pmet_result_download_button")

  # check file input and gene file
  files_ready <- switch(input$mode,
    "promoters_pre" = {
      gene_file_status <-  CheckGeneFile( input$`promoters_pre-gene_for_pmet`$datapath,
                                          "promoters_pre",
                                          motif_db = input$`promoters_pre-motif_db`)

      all(gene_file_status == "OK") | (length(gene_file_status) == 3)
    },
    "promoters" = {
      inputs <- list(
        input$`promoters-uploaded_fasta`, input$`promoters-uploaded_annotation`,
        input$`promoters-uploaded_meme` , input$`promoters-gene_for_pmet`)
      files_upload_status <- (!is.null(inputs) && all(!is.null(inputs)))
      gene_file_status    <- CheckGeneFile(input$`promoters-gene_for_pmet`$datapath, "promoters")

      files_upload_status &&  gene_file_status == "OK"
    },
    "intervals" = {
      inputs              <- list( input$`uploaded_fasta`, input$`uploaded_meme`, input$`gene_for_pmet`)
      files_upload_status <- (!is.null(inputs) && all(!is.null(inputs)))
      gene_file_status    <- CheckGeneFile(input$`intervals-gene_for_pmet`$datapath, "intervals")

      files_upload_status &&  gene_file_status == "OK"
    }
  )

  if (files_ready && ValidEmail(input$userEmail)) {
    shinyjs::show("run_pmet_button_div")
  } else {
    shinyjs::hide("run_pmet_button_div")
  }
})


# Run PMET ---------------------------------------------------------------------
# A queue of notification IDs
notifi_pmet_ids <-  character(0)
observeEvent(input$run_pmet_button, {
  show_spinner()
  # show_modal_spinner()
  # notify_success("Well done!")
  report_success(
    title = "PMET will take long time to complete.",
    text ="You are safe to close this page and result will be send via email.",
    button = "OK"
  )

  shinyjs::hide("pmet_result_download_button")
  shinyjs::disable("run_pmet_button")

  # move focus to run button
  runjs('document.getElementById("run_pmet_div").scrollIntoView();')

  notifi_pmet_id  <- showNotification("PMET is running...", type = "message", duration = 0)
  notifi_pmet_ids <<- c(notifi_pmet_ids, notifi_pmet_id)

  mode <- input$mode
  inputs <- switch(mode,
    "promoters_pre" = { promoters_pre_handler$input },
    "promoters"     = { promoters_handler$input     },
    "intervals"     = { intervals_handler$input     }
  ) %>% reactiveValuesToList()
  inputs$userEmail <- input$userEmail

  pmet_paths  <- PmetPathsGenerator(inputs, mode)
  # change temporary directory'name to a  user-specified (pattern: email_timepoint)
  if (mode == "promoters_pre") {
    file.rename(file.path("result", job_id), pmet_paths$pmetPair_path)
  } else {
    file.rename(file.path("result", job_id  ), pmet_paths$pmetPair_path)
    file.rename(file.path(UPLOAD_DIR, job_id), pmet_paths$pmetIndex_path)
  }
  cli::cat_rule(sprintf("pmet task starts！"))
  # PMET job is runnig in the back
  future_promise({
    ComdRunPmet(inputs,
                pmet_paths$pmetIndex_path,
                pmet_paths$pmetPair_path,
                pmet_paths$genes_path,
                mode)
  }) %...>% (function(result_link) {
    # remove notification
    if (length(notifi_pmet_ids) > 0) {
      removeNotification(notifi_pmet_ids[1])
    }
    notifi_pmet_ids <<- notifi_pmet_ids[-1]

    # remove the indicator of pmete running (shinybusy)
    hide_spinner()

    cli::cat_rule(sprintf("pmet done!"))
    Sys.sleep(0.5)
    # 1. reset loadingButton (RUN PMET) to its active state after PMET DONE
    # 2. hide STOP button
    resetLoadingButton("run_pmet_button")
    shinyjs::enable("run_pmet_button")
    # when job is finished, disable the RUN buttion to avoid second run
    shinyjs::hide("run_pmet_button_div")

    # download button for ngxin file
    shinyjs::show("pmet_result_download_button") # hide download button
    output$pmet_result_download_ui <- renderUI({
      actionButton(
        "pmet_result_download_button",
        "Result",
        icon = icon("download"),
        class = "btn-success",
        onclick = paste0("location.href='", result_link, "'"),
        style = "width: 130px;margin-left: 30px;"
      )
    }) # end of rednderUI
    # automatically scroll to the spot of download button
    runjs('document.getElementById("run_pmet_div").scrollIntoView();')

    showToast(
      "success",
      "The result is ready to be downloaded!",
      .options = myToastOptions
    )

    # reset all input files and parameters
    for (i in c("uploaded_fasta", "uploaded_annotation", "uploaded_meme", "gene_for_pmet",
                "promoter_length", "max_motif_matches", "promoter_number", "fimo_threshold",
                "utr5", "promoters_overlap")) {
      shinyjs::reset(paste0(input$mode, "-", i))
      hideFeedback(paste0(input$mode, "-", i))
    }
  }) # end of future
})

output$image <- renderImage({
  style = "margin-left: 0px;"
  workflow_path <- switch(input$mode,
    "promoters_pre" = {
      height = 800
      style = "margin-left: 400px;"
      "www/figures/pmet_heterotypic.png"
    },
    "promoters" = {
      height = 800
      "www/figures/PMET_workflow_promoters_PMET_PMETindex.png"
    },
    "intervals" = {
      height = 800
      "www/figures/PMET_workflow_intervals_PMET_PMETindex.png"
    }
  )

  list(
    src         = workflow_path,
    contentType = "image/png",
    height       = height,
    style       = style
  )
}, deleteFile=FALSE)
