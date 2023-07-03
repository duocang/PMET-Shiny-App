# session_id is the name of folde to keep uploaded files from user
# because some data needed by PMET is not accessible after the session is closed
UPLOAD_DIR     <- "data/PMETindex/uploaded_motif"
job_id         <- runif(1, 100, 999999999) %/% 1

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


# show/hide Run button () ------------------------------------------------------
observe({
  switch(input$mode,
    "promoters_pre" = {
      input_temp <- promoters_pre_handler$input
      if (!is.null(input_temp$gene_for_pmet$datapath) & ValidEmail(input$userEmail)) {
        shinyjs::show("run_pmet_button_div")
      } else {
        shinyjs::hide("run_pmet_button_div")
      }
    },
    "promoters" = {
      input_temp <- promoters_handler$input
      if (  !is.null(input_temp$uploaded_fasta$datapath)
          & !is.null(input_temp$uploaded_annotation$datapath)
          & !is.null(input_temp$uploaded_meme$datapath)
          & !is.null(input_temp$gene_for_pmet$datapath)
          & ValidEmail(input$userEmail)) {
            shinyjs::show("run_pmet_button_div")
          } else {
            shinyjs::hide("run_pmet_button_div")
          }
    },
    "intervals" = {
      input_temp <- intervals_handler$input
      if (  !is.null(input_temp$uploaded_fasta$datapath)
          & !is.null(input_temp$uploaded_meme$datapath)
          & !is.null(input_temp$gene_for_pmet$datapath)
          & ValidEmail(input$userEmail)) {
            shinyjs::show("run_pmet_button_div")
          } else {
            shinyjs::hide("run_pmet_button_div")
          }
    }
  )
})

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

# Run PMET ---------------------------------------------------------------------
notifi_pmet_id <- NULL # id to remove notification when stop pmet job

observeEvent(input$run_pmet_button, {

  mode <- input$mode

  inputs <- switch(mode,
    "promoters_pre" = { promoters_pre_handler$input },
    "promoters"     = { promoters_handler$input },
    "intervals"     = { intervals_handler$input }
  ) %>% reactiveValuesToList()

  inputs$userEmail <- input$userEmail

  shinyjs::hide("pmet_result_download_button") # hide download button
  shinyjs::disable("run_pmet_button")          # disable rum button
  # run butn clicked, wrap the code in a call to `withBusyIndicatorServer()`
  withBusyIndicatorServer("sf-loading-button-run_pmet_button", {
    Sys.sleep(0.5)
    if (FALSE) { stop("choose another option") }
  })
  runjs('document.getElementById("run_pmet_div").scrollIntoView();')

  notifi_pmet_id <<- showNotification("PMET is running...", type = "message", duration = 0)

  pmet_paths  <- PmetPathsGenerator(inputs, mode)

  if (mode == "promoters_pre") {
    file.rename(file.path("result", job_id), pmet_paths$pmetPair_path)
  } else {
    file.rename(file.path("result", job_id), pmet_paths$pmetPair_path)
    file.rename(file.path(UPLOAD_DIR, job_id), pmet_paths$pmetIndex_path)
  }

  # PMET job is runnig in the back
  future_promise({
    ComdRunPmet(inputs,
                      pmet_paths$pmetIndex_path,
                      pmet_paths$pmetPair_path,
                      pmet_paths$genes_path,
                      mode)
  }) %...>% (function(result_link) {
    cli::cat_rule(sprintf("pmet done!"))
    Sys.sleep(0.5)
    # 1. reset loadingButton (RUN PMET) to its active state after PMET DONE
    # 2. hide STOP button
    resetLoadingButton("run_pmet_button")
    shinyjs::enable("run_pmet_button")
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

  cli::cat_rule(sprintf("pmet task starts！"))
})