promoters_ui <- function(id, height = 800, width = 850) {
  ns <- NS(id)
  tags$head(
    tags$style(HTML("
      .label-size {
        font-size: 13px;
      }
    ")))
  # motif database
  div(
    div(id = "fasta_div", style = "margin-bottom: 10px;",
      fileInput(ns("fasta"), "Upload genome file",
        multiple = FALSE,
        accept = c(".fasta", ".fa")
      ),
      tags$a(
        id = ns("demo_genome_file_link"),
        href = "https://ftp.ensemblgenomes.ebi.ac.uk/pub/plants/release-56/fasta/arabidopsis_thaliana/dna/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa.gz",
        download = "Arabidopsis_thaliana.TAIR10.dna.toplevel.fa.gz",
        "Example genome"
      )
    ),
    div(id = "gff3_div", style = "margin-bottom: 10px;",
        fileInput(ns("gff3"), "Upload annotation file",
          multiple = FALSE,
          accept = ".gff3"
        ),
        tags$a(
          id = ns("demo_annotation_file_link"),
          href = "https://ftp.ensemblgenomes.ebi.ac.uk/pub/plants/release-56/gff3/arabidopsis_thaliana/Arabidopsis_thaliana.TAIR10.56.gff3.gz",
          download = "example_annotation.gff3",
          "Annotation of Arabidopsis thaliana"
        )
    ), # end of gff3_div
    div(id = ns("meme_div"), style = "margin-bottom: 10px;",
      fileInput(ns("meme"), "Upload motif meme file",
        multiple = FALSE,
        accept = ".meme"
      ),
      downloadLink(ns("demo_meme"), "Example motif DB")
    ),  # end of meme div
    div(id = "genes_div", style = "margin-bottom: 10px;",
      shinyjs::disabled(
        div(id= ns("gene_fileinput"),
          fileInput(ns("genes"), "Clusters and genes", multiple = FALSE, accept = ".txt")
        )
      ),
      # example gene list
      downloadLink(ns("demo_genes"), "Example gene for Arabidopsis thaliana"),
      # missing gene
      shinyjs::hidden(
        actionLink(ns("genes_not_found_link"), "Genes not found", icon = icon("info-circle"), style = "color: #F89406;font-weight: bold; font-size: 14px;")
      )
    ), # end of genes_div
    bsTooltip(id = ns("gene_fileinput"),
          title = "Please upload an annotation file",
          placement = "top",
          trigger = "hover",
          options = list(delay = list(show = 500, hide = 100))
    ), # end of tooltip
    # parameters
    div(id = "parameters_div", style = "margin-bottom: 10px;",
      div("Parameters", style = "font-size: 16px; font-weight: bold;"),
      fluidRow(
        div(class = "selectInput_div",
          div(id = "promoter_length_div",
            selectInput(
              inputId = ns("promoter_length"),
              label = "Promoter Length",
              choices = c(500, 1000, 1500, 2000),
              selected = 1000
            )
          ),
          div(id = "max_match_div",
            selectInput(
              inputId = ns("max_match"), label = "Max motif matches",
              choices = c(2, 3, 4, 5, 10, 15, 20), selected = 5
            )
          ),
          div(id = "promoter_num_div",
            selectInput(
              inputId = ns("promoter_num"),
              label = "Number of selected promoters",
              choices = c(2000, 3000, 4000, 5000, 10000),
              selected = 5000
            )
          ),
          div(id = "fimo_threshold_div",
            selectInput(
              inputId = ns("fimo_threshold"),
              label = "Fimo threshold",
              choices = c(0.000001, 0.00001, 0.0001, 0.001, 0.01, 0.05),
              selected = 0.05
            )
          ),
          div(id = "ic_threshold_div",
            selectInput(
              inputId = ns("ic_threshold"),
              label = "Information content threshold",
              choices = c(2, 4, 8, 10, 16, 24, 32),
              selected = 4
            )
          )
        ),
        div(class = "radioButtons_div", style = "padding-left:15px; padding-right:15px;",
          div(id = "utr5_div",
            radioButtons(
              ns("utr5"), "5' UTR included?",
              c("Yes" = "Yes", "No" = "No"),
              inline = TRUE
            )
          ),
          div(id = "promoters_overlap_div",
            radioButtons(
              ns("promoters_overlap"),
              "Promoters' potential overlaps removed?",
              c("Yes" = "AllowOverlap", "No" = "NoOverlap"),
              inline = TRUE
            )
          )
        )
      ) # end of fluidRow
    ) # end of div parameters
  )
}

promoters_server <- function(id, job_id, trigger, mode, navbar) {
  moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      # self uploaded genome fasta  --------------------------------------------------
      observeEvent(input$fasta, {
        req(input$fasta)

        # copy uploaded genome fasta to session folder for PMET to run in the back
        TempToLocal("result/indexing", job_id, input$fasta)

        # indicators for file uploaded
        hideFeedback(inputId = "fasta")
        if (!is.null(input$fasta$datapath)) {
          showFeedbackSuccess(inputId = "fasta")
        } else {
          showFeedbackDanger(inputId = "fasta", text = "No motif")
        }
      }, ignoreInit = T)

      # self uploaded annotation  ----------------------------------------------------
      observeEvent(input$gff3, {
        req(input$gff3)

        # copy uploaded annotation to session folder for PMET to run in the back
        TempToLocal("result/indexing", job_id, input$gff3)

        # indicators for file uploaded
        hideFeedback(inputId = "gff3")
        if (!is.null(input$gff3$datapath)) {
          showFeedbackSuccess(inputId = "gff3")
        } else {
          showFeedbackDanger(inputId = "gff3", text = "No annotation")
        }
      }, ignoreInit = T)

      # self uploaded motif database  ------------------------------------------------
      observeEvent(input$meme, {
        req(inputId = "meme")

        # copy uploaded motif to session folder for PMET to run in the back
        TempToLocal("result/indexing", job_id, input$meme)

        # indicators for file uploaded
        hideFeedback(inputId = "meme")
        if (!is.null(input$meme$datapath)) {
          showFeedbackSuccess(inputId = "meme")
        } else {
          showFeedbackDanger(inputId = "meme", text = "No motif")
        }
      }, ignoreInit = T)

      # self genes uploaded -----------------------------------------------------------
      # eable gene upload after annotation uploaded
      observe({
        req(input$gff3$datapath)
        shinyjs::enable("gene_fileinput")
        removeTooltip(session, ns("gene_fileinput"))
      })

      genes_not_found  <- reactiveVal(NULL) # store genes not found for download handler
      observeEvent(input$genes, {
        req(input$genes, input$genes != "")

        # copy uploaded genes to result folder for PMET to run in the back
        TempToLocal("result", job_id, input$genes)

        # it takes time to find which intervals are not presetn so we show red first
        showFeedbackDanger(
          "genes",
          text = "Processing... Wait!",
          color = "#d9534f",
          icon = shiny::icon("exclamation-sign", lib = "glyphicon"),
          session = shiny::getDefaultReactiveDomain()
        )

        # inputs <- reactiveValuesToList(input)
        genes_status <- CheckGeneFile(input$genes$datapath, mode = "promoters", premade = input$gff3$datapath)

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
            "intervals_wrong_format" = {
              showFeedbackDanger( inputId = "genes", text = "Genomic intervals pattern: chromosome:number-number.")
            },
            "no_valid_genes" = {
              showFeedbackDanger(inputId = "genes", text = "No valid genes available in the uploaded file")
            }
          )
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
      }, ignoreInit = T)

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
          write.table(read.table("data/demo_promoters/example_genes.txt"), file, quote = FALSE, row.names = FALSE, col.names = FALSE)
        }
      )

      output$demo_meme <- downloadHandler(
        filename = function() {
          "demo_motif.meme"
        },
        content = function(file) {
          data <- readLines("data/demo_promoters/example_motif.meme")
          writeLines(data, file)
        }
      )

      # workthrough tips of Run PMET ------------------------------------------------------
      elements <- c(
        "#fasta_div",
        "#gff3_div",
        "#meme_div",
        "#genes_div",
        "#parameters_div"
      )
      intors <- c(
        "Genome file",
        "Annotation file",
        "Upload your own motif file or choose from the available defaults",
        "A tab separated file containing the gene set number and gene.",
        "Fine tuning of PMET"
      )
      intro <- data.frame(element = elements, intro = intors)

      observeEvent(trigger(), {
        if (mode() == "promoters" & navbar() == "run_start") {
          introjs(session, options = list(steps = intro))
        }
      }, ignoreInit = F)

      list(input = input)
    }
  )
}
