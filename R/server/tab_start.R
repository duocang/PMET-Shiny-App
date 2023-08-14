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
observeEvent(input$email, {
  if (input$email == "") { # no typing
    hideFeedback(inputId = "email")
    showFeedbackDanger(inputId = "email", text = "Email needed")
  } else if (ValidEmail(input$email)) { # invalid email
    hideFeedback(inputId = "email")
    showFeedbackSuccess(inputId = "email", text = "Results will be sent via Email.")
  } else { # valid email
    hideFeedback(inputId = "email")
    showFeedbackWarning(inputId = "email", text = "invalid Email")
  }
})


# show Run button () -----------------------------------------------------------
# when the following requirements are met:
# 1. all input is required
# 2. gene file is a file with 2 columns
# 3. valid email is provided
observe({
  req(input$email)
  # when input changed
  # hide spinner (indicator for job running)
  # hide run and download buttions
  hide_spinner()
  shinyjs::hide("toast-container")
  shinyjs::hide("run_pmet_btn_div")
  shinyjs::hide("pmet_result_download_btn")

  # check file input and gene file
  files_ready <- switch(input$mode,
    "promoters_pre" = {
      req(input$`promoters_pre-genes`)
      req(input$`promoters_pre-genes` != "")

      # Because after the previous round of PMET job, the value of `promoters_pre-genes`
      # did not change. This means that even if no new gene file is uploaded,
      # `promoters_pre-genes` can still go through req.
      # So we determine whether the user has actually uploaded the file for a new PMET job
      # by checking if the gene file exists.
      # Because after each completion of a PMET job, we manually delete the gene file.
      req(file.exists(input$`promoters_pre-genes`$datapath))
      req(input$`promoters_pre-premade`)


      gene_file_status <-  CheckGeneFile( input$`promoters_pre-genes`$datapath,
                                          "promoters_pre",
                                          premade = input$`promoters_pre-premade`)

      all(gene_file_status == "OK") | (length(gene_file_status) == 3)
    },
    "promoters" = {
      req(input$`promoters-genes`)
      inputs <- list(
        input$`promoters-fasta`,
        input$`promoters-gff3`,
        input$`promoters-meme` ,
        input$`promoters-genes`)
      files_upload_status <- (!is.null(inputs) && all(!is.null(inputs)))
      gene_file_status    <- CheckGeneFile(input$`promoters-genes`$datapath, "promoters")

      files_upload_status &&  gene_file_status == "OK"
    },
    "intervals" = {
      req(input$`intervals-genes`)
      inputs              <- list(input$`intervals-fasta`,
                                  input$`intervals-meme`,
                                  input$`intervals-genes`)
      files_upload_status <- (!is.null(inputs) && all(!is.null(inputs)))
      gene_file_status    <- CheckGeneFile(input$`intervals-genes`$datapath, "intervals")

      files_upload_status &&  gene_file_status == "OK"
    }
  )
  # show run buttion if all files uploaded and email valid
  if (files_ready && ValidEmail(input$email)) {
    shinyjs::show("run_pmet_btn_div")
  } else {
    shinyjs::hide("run_pmet_btn_div")
  }
})


# Run PMET ---------------------------------------------------------------------
# A queue of notification IDs
notifi_pmet_ids <-  character(0)
observeEvent(input$run_pmet_btn, {
  show_spinner()
  report_success(
    title = "PMET will take long time to complete.",
    text ="You are safe to close this page and result will be send via email.",
    button = "OK"
  )

  shinyjs::hide("pmet_result_download_btn")
  shinyjs::disable("run_pmet_btn")

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
  inputs$email <- input$email

  pmet_paths  <- PmetPathsGenerator(inputs, mode)
  # change temporary directory'name to a  user-specified (pattern: email_timepoint)
  if (mode == "promoters_pre") {
    file.rename(file.path("result", job_id), pmet_paths$pair_dir)
  } else {
    file.rename(file.path("result", job_id  ), pmet_paths$pair_dir)
    file.rename(file.path("result/indexing", job_id), pmet_paths$index_dir)
  }
  cli::cat_rule(sprintf("pmet task starts！"))
  # PMET job is runnig in the back
  future_promise({
    ComdRunPmet(inputs,
                pmet_paths$index_dir,
                pmet_paths$pair_dir,
                pmet_paths$genes_path,
                mode)
  }) %...>% (function(result_link) {
    # 1. Download button for ngxin file -----------------------------------------
    shinyjs::show("pmet_result_download_btn") # hide download button
    output$pmet_result_download_ui <- renderUI({
      actionButton(
        "pmet_result_download_btn",
        "Result",
        icon = icon("download"),
        class = "btn-success",
        onclick = paste0("location.href='", result_link, "'"),
        style = "width: 130px;margin-left: 30px;"
      )
    }) # end of rednderUI
    # automatically scroll to the spot of download button
    runjs('document.getElementById("run_pmet_div").scrollIntoView();')

    # 2. Notitication -----------------------------------------------------------
    # Download reminder (automatically disappears after 120 seconds)
    showToast(
      "success",
      "The result is ready to be downloaded!",
      .options = myToastOptions
    )

    # remove notification of PMET running
    if (length(notifi_pmet_ids) > 0) {
      removeNotification(notifi_pmet_ids[1])
    }
    notifi_pmet_ids <<- notifi_pmet_ids[-1]

    # remove the indicator of pmete running (shinybusy)
    hide_spinner()

    # terminal message
    cli::cat_rule(sprintf("pmet done!"))
    Sys.sleep(0.5)

    # 3. Reset---------------------------------------------------------------------

    # reset buttion
    #   reset loadingButton (RUN PMET) to its active state after PMET DONE
    resetLoadingButton("run_pmet_btn")
    shinyjs::enable("run_pmet_btn")
    # when job is finished, disable the RUN buttion to avoid second run
    shinyjs::hide("run_pmet_btn_div")

    # reset all and parameters and input files
    for (i in c("fasta", "gff3", "meme", "genes",
                # "species", "premade",
                "promoter_length", "max_match", "promoter_num", "ic_threshold",
                "fimo_threshold", "utr5", "promoters_overlap")) {
      shinyjs::reset(paste0(input$mode, "-", i))
      hideFeedback(paste0(input$mode, "-", i))
    }

    # 4. Hide UI elements -------------------------------------------------------------
    # hide gene not find link
    if (input$mode == "promoters_pre") {
      shinyjs::hide("promoters_pre-genes_not_found_link")
    }

    # 5. Delete uploaded gene file
    # The PMET RUN button should disappear after the previous PMET job is completed and
    # set the fileInput of genne file to NUL, to ensure that a new gene file is uploaded
    # before showing the PMET RUN button again.
    # But it is not easy to set input$input$`promoters_pre-genes` to NULL. So, we decide
    # to delete temp gene file from previous PMET job and check the existence of gene file
    # to show PMET run button in the future PMET job.
    file.remove(input$`promoters_pre-genes`$datapath)
  }) # end of future
})


# info of species
observeEvent(input$`promoters_pre-species`, {
  req(input$`promoters_pre-species`, input$`promoters_pre-species`!="")
  shinyjs::show("txt_species")
  shinyjs::show("txt_genome")
  shinyjs::show("txt_annotation")

  output$txt_species <- renderUI({
    HTML(paste0('
      <p>
        <span style="font-weight: bold; font-size: 18px; display: inline-block; width: 130px;">Species</span>
        <span style="font-weight: bold; font-size: 18px; display: inline-block; width: 10px; text-align: right;">:</span>
        <span style="color:#5698c3; font-size: 19px;">',input$`promoters_pre-species` %>% str_replace_all("_", " "), '</span>
      </p>'))
  })

  link_text <- MOTF_DB_META[[input$`promoters_pre-species`]][["genome_name"]]
  link_url  <- MOTF_DB_META[[input$`promoters_pre-species`]][["genome_link"]]

  html_link <- paste0('
    <p>
      <span style="font-weight: bold; font-size: 18px; display: inline-block; width: 130px;">Genome</span>
      <span style="font-weight: bold; font-size: 18px; display: inline-block; width: 10px; text-align: right;">:</span>
      <a style="font-size: 18px; color:#5698c3;text-decoration: underline;" href="', link_url, '" target="_blank">', link_text, '</a>
    </p>')

  output$txt_genome <- renderUI({
    HTML(html_link)
  })
}, ignoreInit = TRUE)

# annotation
observeEvent(input$`promoters_pre-species`, {
  req(input$`promoters_pre-species`, input$`promoters_pre-species`!="")
  link_text <- MOTF_DB_META[[input$`promoters_pre-species`]][["annotation_name"]]
  link_url  <- MOTF_DB_META[[input$`promoters_pre-species`]][["annotation_link"]]

  genes     <- read.table(file.path("data/indexing", input$`promoters_pre-species`, "universe.txt" ) )[, 1]
  num_genes <- length(genes)
  genes     <- head(genes)

  genes_html <- paste0("<div style='margin-left:160px;'>
                          <p style='margin: 0; line-height: 1;'>", paste(genes, collapse="</p>
                          <p style='margin: 0; line-height: 1;'>"), "</p>
                          <p style='margin: 0; line-height: 0.5;font-weight: bold; font-size: 16px;'>. </p>
                          <p style='margin: 0; line-height: 0.5;font-weight: bold; font-size: 16px;'>. </p>
                          <p style='margin: 0; line-height: 0.5;font-weight: bold; font-size: 16px;'>. </p>
                          <p></p>
                          <p style='line-height: 1.5; font-weight: bold; font-size: 16px; color:#666666;'>Number of genes in genome: ", num_genes, "</p>
                        </div>")
  html_link <- paste0('
                      <p>
                        <span style="font-weight: bold; font-size: 18px; display: inline-block; width: 130px;">Annotation</span>
                        <span style="font-weight: bold; font-size: 18px; display: inline-block; width: 10px; text-align: right;">: </span>
                        <a style="font-size: 18px; color:#5698c3;text-decoration: underline;" href="', link_url, '" target="_blank">', link_text, '</a>
                      </p>',
                      genes_html)
  output$txt_annotation <- renderUI({HTML(html_link)})
}, ignoreInit = TRUE)

# motif database
observeEvent(input$`promoters_pre-premade`, {
  req(input$`promoters_pre-premade`)
  shinyjs::show("txt_motif_db")

  num_motif_names <- file.path(input$`promoters_pre-premade`, "fimohits") %>%
          list.files(pattern = "*.txt", full.names = TRUE) %>%
          length()
  motif_names <- file.path(input$`promoters_pre-premade`, "fimohits") %>%
          list.files(pattern = "*.txt", full.names = TRUE) %>%
                    sample(5) %>%
                    tools::file_path_sans_ext() %>%
                    basename()
  motif_names_html <- paste0("
                        <div style='margin-left:160px;'>
                          <p style='margin: 0; line-height: 1;'>", paste(motif_names, collapse="</p>
                          <p style='margin: 0; line-height: 1;'>"), "</p>
                          <p style='margin: 0; line-height: 0.5;font-weight: bold; font-size: 16px;'>. </p>
                          <p style='margin: 0; line-height: 0.5;font-weight: bold; font-size: 16px;'>. </p>
                          <p style='margin: 0; line-height: 0.5;font-weight: bold; font-size: 16px;'>. </p>
                          <p></p>
                          <p style='line-height: 1.5; font-weight: bold; font-size: 16px; color:#666666;'>Number of motifs: ", num_motif_names,
                          "</p>
                        </div>")

  link_text <- basename(input$`promoters_pre-premade`) %>% str_split_1("_") %>% paste0(collapse = " ") #%>% tools::toTitleCase()
  link_url  <- MOTF_DB_META[[input$`promoters_pre-species`]][["motif_db"]][[basename(input$`promoters_pre-premade`)]]

  html_link <- paste0('
                      <p>
                        <span style="font-weight: bold; font-size: 18px; display: inline-block; width: 130px;">Motif database</span>
                        <span style="font-weight: bold; font-size: 18px; display: inline-block; width: 10px; text-align: right;">:</span>
                        <a style="font-size: 18px; color:#5698c3;text-decoration: underline;" href="', link_url, '" target="_blank">', link_text, '</a>
                      </p>',
                      motif_names_html)
  output$txt_motif_db <- renderUI({HTML(html_link)})

}, ignoreInit = TRUE)

# hide pre-computed properties when switching
observeEvent(input$mode, {
  shinyjs::hide("txt_species")
  shinyjs::hide("txt_genome")
  shinyjs::hide("txt_annotation")
  shinyjs::hide("txt_motif_db")
})