intervals_ui <- function(id, height = 800, width = 850) {
  ns <- NS(id)
  # motif database
  div(
    div(id = "uploaded_fasta_div", class = "one_upload",
      fileInput(ns("uploaded_fasta"), "Upload genome file",
        multiple = FALSE,
        accept = c(".fasta", ".fa")
      ),
      downloadLink(ns("demo_intervals_file_link"), "Example intervals collection")
    ), # end of uploaded_fasta_div
    div(div = "uploaded_meme_div", class = "one_upload",
      fileInput(ns("uploaded_meme"), "Upload motif meme file",
        multiple = FALSE,
        accept = ".meme"
      ),
      downloadLink(ns("demo_motif_db_link"), "Example motif DB")
    ),
    div(id = "gene_for_pmet_div", class = "one_upload",
      fileInput(ns("gene_for_pmet"), "Clusters and intervals", multiple = FALSE, accept = ".txt")
    )
  )
}

intervals_server <- function(id, job_id, trigger, mode, navbar) {
  moduleServer(
    id,
    function(input, output, session) {
      UPLOAD_DIR <- "data/PMETindex/uploaded_motif"

      # self uploaded genome fasta  --------------------------------------------------
      observeEvent(input$uploaded_fasta, {

        req(input$uploaded_fasta)
        # copy uploaded genome fasta to session folder for PMET to run in the back
        TempToLocal(UPLOAD_DIR, job_id, input$uploaded_fasta)

        # indicators for file uploaded
        if (!is.null(input$uploaded_fasta$datapath)) {
          hideFeedback(inputId = "uploaded_fasta")
          showFeedbackSuccess(inputId = "uploaded_fasta")
        } else {
          hideFeedback(inputId = "uploaded_fasta")
          showFeedbackDanger(inputId = "uploaded_fasta", text = "No motif")
        }
      }, ignoreInit = T)

      # self uploaded motif database  ------------------------------------------------
      observeEvent(input$uploaded_meme, {
        req(input$uploaded_meme)

        # copy uploaded motif to session folder for PMET to run in the back
        TempToLocal(UPLOAD_DIR, job_id, input$uploaded_meme)

        # indicators for file uploaded
        if (!is.null(input$uploaded_meme$datapath)) {
          hideFeedback(inputId = "uploaded_fasta")
          showFeedbackSuccess(inputId = "uploaded_meme")
        } else {
          hideFeedback(inputId = "uploaded_fasta")
          showFeedbackDanger(inputId = "uploaded_meme", text = "No motif")
        }
      }, ignoreInit = T)

      # self genes uploaded -----------------------------------------------------------
      observeEvent(input$gene_for_pmet, {

        req(input$gene_for_pmet)
        # copy uploaded genes to result folder for PMET to run in the back
        TempToLocal("result", job_id, input$gene_for_pmet)

        inputs <- reactiveValuesToList(input)
        genes_status <- CheckGeneFile(input$gene_for_pmet$size,
                                      input$gene_for_pmet$datapath,
                                      motif_db = NULL,
                                      mode = "intervals")
        hideFeedback(inputId = "uploaded_fasta")
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
      }, ignoreInit = T)

      output$demo_intervals_file_link <- downloadHandler(
        filename = function() {
          "intervals.fa"
        },
        content = function(file) {
          data <- readLines("data/data_for_intervals/intervals.fa")
          writeLines(data, file)
        }
      )

      output$demo_motif_db_link <- downloadHandler(
        filename = function() {
          "motif.meme"
        },
        content = function(file) {
          data <- readLines("data/data_for_intervals/motif.meme")
          writeLines(data, file)
        }
      )

      output$gene_for_pmet <- downloadHandler(
        filename = function() {
          "intervals.txt"
        },
        content = function(file) {
          data <- readLines("data/data_for_intervals/intervals.txt")
          writeLines(data, file)
        }
      )

      # workthrough tips of Run PMET ------------------------------------------------
      elements <- c(
        "#uploaded_fasta_div",
        "#uploaded_meme_div",
        "#gene_for_pmet_div"
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
