intervals_ui <- function(id, height = 800, width = 850) {
  ns <- NS(id)
  # motif database
  div(
    div(id = "fasta_div", class = "one_upload",
      fileInput(ns("fasta"), "Upload genome file",
        multiple = FALSE,
        accept = c(".fasta", ".fa")
      ),
      downloadLink(ns("demo_intervals_fa"), "Example intervals collection")
    ), # end of fasta_div
    div(div = "meme_div", class = "one_upload",
      fileInput(ns("meme"), "Upload motif meme file",
        multiple = FALSE,
        accept = ".meme"
      ),
      downloadLink(ns("demo_meme"), "Example motif DB")
    ),
    div(id = "peaks_div", class = "one_upload",
      fileInput(ns("genes"), "Clusters and intervals", multiple = FALSE, accept = ".txt"),
      # example gene list
      downloadLink(ns("demo_genes"), "Example peaks (intervals)")
    ),
    # parameters
    div(id = "parameters_div", class = "one_upload",
      div("Parameters", class = "big_font"),
      fluidRow(
        div(id = "max_match_div", class = "parameters_box",
          selectInput(
            inputId = ns("max_match"), label = "Max motif matches",
            choices = c(2, 3, 4, 5, 10, 15, 20), selected = 5
          )
        ),
        div(id = "promoter_num_div", class = "parameters_box",
          selectInput(
            inputId = ns("promoter_num"),
            label = "Number of selected promoters",
            choices = c(2000, 3000, 4000, 5000, 10000),
            selected = 5000
          )
        ),

        div(id = "fimo_threshold_div", class = "parameters_box",
          selectInput(
            inputId = ns("fimo_threshold"),
            label = "Fimo threshold",
            choices = c(0.000001, 0.00001, 0.0001, 0.001, 0.01, 0.05),
            selected = 0.05
          )
        ),
        div(id = "ic_threshold_div", class = "parameters_box",
          selectInput(
            inputId = ns("ic_threshold"),
            label = "Information content threshold",
            choices = c(2, 4, 8, 10, 16, 24, 32),
            selected = 4
          )
        )
      )
    )
  )
}

intervals_server <- function(id, job_id, trigger, mode, navbar) {
  moduleServer(
    id,
    function(input, output, session) {
      # self uploaded genome fasta  --------------------------------------------------
      observeEvent(input$fasta, {

        req(input$fasta)
        # copy uploaded genome fasta to session folder for PMET to run in the back
        TempToLocal("result/indexing", job_id, input$fasta)

        # indicators for file uploaded
        if (!is.null(input$fasta$datapath)) {
          hideFeedback(inputId = "fasta")
          showFeedbackSuccess(inputId = "fasta")
        } else {
          hideFeedback(inputId = "fasta")
          showFeedbackDanger(inputId = "fasta", text = "No motif")
        }
      }, ignoreInit = T)

      # self uploaded motif database  ------------------------------------------------
      observeEvent(input$meme, {
        req(input$meme)

        # copy uploaded motif to session folder for PMET to run in the back
        TempToLocal("result/indexing", job_id, input$meme)

        # indicators for file uploaded
        if (!is.null(input$meme$datapath)) {
          hideFeedback(inputId = "meme")
          showFeedbackSuccess(inputId = "meme")
        } else {
          hideFeedback(inputId = "meme")
          showFeedbackDanger(inputId = "meme", text = "No motif")
        }
      }, ignoreInit = T)

      # self genes uploaded -----------------------------------------------------------
      observeEvent(input$genes, {

        req(input$genes)
        # copy uploaded genes to result folder for PMET to run in the back
        TempToLocal("result", job_id, input$genes)

        inputs <- reactiveValuesToList(input)
        genes_status <- CheckGeneFile(input$genes$datapath, mode = "intervals")

        hideFeedback(inputId = "genes")
        switch(genes_status,
          "OK" = {
            hideFeedback(inputId = "genes")
            showFeedbackSuccess(inputId = "genes")
          },
          "NO_CONTENT" = {
            hideFeedback(inputId = "genes")
            showFeedbackDanger(inputId = "genes", text = "No content in the file")
          },
          "WORNG_COLUMN_NUMBER" = {
            hideFeedback(inputId = "genes")
            showFeedbackDanger( inputId = "genes", text = "Only cluster and interval columns are allowed")
          },
          "GENE_WRONG_FORMAT" = {
            hideFeedback(inputId = "genes")
            showFeedbackDanger( inputId = "genes", text = "Wrong format of uploaded file")
          },
          "intervals_wrong_format" = {
            hideFeedback(inputId = "genes")
            showFeedbackDanger( inputId = "genes", text = "Genomic intervals pattern: chromosome:number-number.")
          },
          "no_valid_genes" = {
            hideFeedback(inputId = "genes")
            showFeedbackDanger(inputId = "genes", text = "No valid genes available in the uploaded file")
          })
      }, ignoreInit = T)

      output$demo_intervals_fa <- downloadHandler(
        filename = function() {
          "demo_intervals.fa"
        },
        content = function(file) {
          data <- readLines("data/demo_intervals/intervals.fa")
          writeLines(data, file)
        }
      )

      output$demo_meme <- downloadHandler(
        filename = function() {
          "demo_motif.meme"
        },
        content = function(file) {
          data <- readLines("data/demo_intervals/motif.meme")
          writeLines(data, file)
        }
      )

      output$demo_genes <- downloadHandler(
        filename = function() {
          "demo_peaks.txt"
        },
        content = function(file) {
          data <- readLines("data/demo_intervals/peaks.txt")
          writeLines(data, file)
        }
      )

      # workthrough tips of Run PMET ------------------------------------------------
      elements <- c(
        "#fasta_div",
        "#meme_div",
        "#peaks_div"
      )
      intors <- c(
        "Genome file",
        "Annotation file",
        "A tab separated file containing the gene set number and gene."
      )
      intro <- data.frame(element = elements, intro = intors)

      observeEvent(trigger(), {
        if (mode() == "intervals" & navbar() == "run_start") {
          introjs(session, options = list(steps = intro))
        }
      }, ignoreInit = F)

      list(input = input)
    }
  )
}
