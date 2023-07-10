promoters_pre_ui <- function(id, height = 800, width = 850) {
  ns <- NS(id)
  # motif database
  div(
    div(id = "premade_div", class = "one_upload",
      uiOutput(ns("premade_uiOutput"))
    ),
    div(id = "genes_div", class = "one_upload",
      fileInput(ns("genes"), "Clusters and genes", multiple = FALSE, accept = ".txt"),
      # example gene list
      downloadLink(ns("demo_genes"), "Example gene"),
      shinyjs::hidden(
        actionLink(ns("genes_not_found_link"), "Genes not found", icon = icon("info-circle")))
    ), # end of genes_div
        # parameters
    div(id = "parameters_div", class = "one_upload",
      div("Parameters", class = "big_font"),
      fluidRow(
        div(id = "ic_threshold_div", class = "parameters_box",
          selectInput(
            inputId = ns("ic_threshold"),
            label = "Number of selected promoters",
            choices = c(2, 4, 8, 10, 16, 24, 32),
            selected = 4
          )
        ),
      )
    )
  )
}

promoters_pre_server <- function(id, job_id, trigger, mode, navbar) {
  moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      output$premade_uiOutput <- renderUI({
        selectInput(
          inputId = ns("premade"), label = "Motif database",
          choices = CHOICES,
          selected = "arabidopsis_thaliana-PBM",
          selectize = TRUE
        )
      })

      genes_not_found  <- reactiveVal(NULL) # store genes not found for download handler

      # self genes uploaded -----------------------------------------------------------
      observeEvent(input$genes, {
        req(input$genes)
        # copy uploaded genes to result folder for PMET to run in the back
        TempToLocal("result", job_id, input[["genes"]])

        inputs <- reactiveValuesToList(input)

        genes_status <- CheckGeneFile(input$genes$datapath, mode = "promoters_pre", input$premade)

        hideFeedback(inputId = "genes")
        if (length(genes_status) == 3) {
          genes_not_found(genes_status[[3]])
          shinyjs::show("genes_not_found_link")
          showFeedbackWarning(
            inputId = "genes",
            text = paste(genes_status[[1]], "out of", genes_status[[2]], "genes are not found"))
        } else {
          shinyjs::hide("genes_not_found_link")
          switch(genes_status,
            "OK" = {
              showFeedbackSuccess(inputId = "genes")
            },
            "NO_CONTENT" = {
              showFeedbackDanger(inputId = "genes", text = "No content in the file")
            },
            "WORNG_COLUMN_NUMBER" = {
              showFeedbackDanger( inputId = "genes", text = "Only cluster and interval columns are allowed")
            },
            "GENE_WRONG_FORMAT" = {
              showFeedbackDanger( inputId = "genes", text = "Wrong format of uploaded file")
            },
            "no_valid_genes" = {
              showFeedbackDanger(inputId = "genes", text = "No valid genes available in the uploaded file")
            })
        }
      }, ignoreInit = T)

      # modal dialog shown, when link clicked (genes not found are not null)
      observeEvent(input$genes_not_found_link, {
        if (!is.null(genes_not_found())) {
          Sys.sleep(0.5)
          showModal(modalDialog(
            title = "Genes not found:",
            DT::renderDataTable({ genes_not_found() }),
            footer = tagList(
              downloadButton(ns("genes_not_found_down_btn"), "Download"),
              modalButton("Cancel"))
          )) # end of showModal
        }
      })

      # Download genes not found when button clicked -----------------------------------
      output$genes_not_found_down_btn <- downloadHandler(
        filename = function() {
          "genes_not_found.txt"
        },
        content = function(file) {
          write.table(genes_not_found(), file, quote = FALSE, row.names = FALSE) }
      ) # downLoadHandler end


      # Download example genes file for PMET ---------------------------------------
      output$demo_genes <- downloadHandler(
        filename = function() {
          "demo_genes.txt"
        },
        content = function(file) {
          read.table("data/demo_promoters/example_genes.txt") %>%
            write.table(file, quote = FALSE, row.names = FALSE, col.names = FALSE)
        }
      )

      # workthrough tips of Run PMET -----------------------------------------------
      elements <- c(
          "#premade_div",
          "#genes_div"
      )
      intors <- c(
        "Upload your own motif file or choose from the available defaults",
        "A tab separated file containing the gene set number and gene."
      )
      intro <- data.frame(element = elements, intro = intors)

      observeEvent(trigger(), {
        if (mode() == "promoters_pre" & navbar() == "run_start") {
          introjs(session, options = list(steps = intro))
        }
      }, ignoreInit = F)

      list(input = input)
    })
}
