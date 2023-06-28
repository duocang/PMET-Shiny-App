promoters_ui <- function(id, height = 800, width = 850) {
  ns <- NS(id)
  # motif database
  div(
    div(id = "uploaded_fasta_div", class = "one_upload",
      fileInput(ns("uploaded_fasta"), "Upload genome file",
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
    div(id = "uploaded_annotation_div", class = "one_upload",
        fileInput(ns("uploaded_annotation"), "Upload annotation file",
          multiple = FALSE,
          accept = ".gff3"
        ),
        tags$a(
          href = "https://ftp.ensemblgenomes.ebi.ac.uk/pub/plants/release-56/gff3/arabidopsis_thaliana/Arabidopsis_thaliana.TAIR10.56.gff3.gz",
          download = "example_annotation.gff3",
          "Example annotation"
        )
    ), # end of uploaded_annotation_div
    div(id = ns("uploaded_meme_div"), class = "one_upload",
      fileInput(ns("uploaded_meme"), "Upload motif meme file",
        multiple = FALSE,
        accept = ".meme"
      ),
      downloadLink(ns("demo_motif_db_link"), "Example motif DB")
    ),
    div(id = "gene_for_pmet_div", class = "one_upload",
      fileInput(ns("gene_for_pmet"), "Clusters and genes", multiple = FALSE, accept = ".txt"),
      # example gene list
      downloadLink(ns("demo_genes_file_link"), "Example gene")
    ),
    # parameters
    div(id = "parameters_div", class = "one_upload",
      div("Parameters", class = "big_font"),
      fluidRow(
        class = "parameters_id",
        div(id = "promoter_length_div", class = "parameters_box",
          selectInput(
            inputId = ns("promoter_length"),
            label = "Promoter Length",
            choices = c(500, 1000, 1500, 2000),
            selected = 1000
          )
        ),
        div(id = "max_motif_matches_div", class = "parameters_box",
          selectInput(
            inputId = ns("max_motif_matches"), label = "Max motif matches",
            choices = c(2, 3, 4, 5, 10, 15, 20), selected = 5
          )
        ),
        div(id = "promoter_number_div", class = "parameters_box",
          selectInput(
            inputId = ns("promoter_number"),
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
        )
      ),
      div(id = "utr5_div", class = "parameters_box",
        radioButtons(
          ns("utr5"), "5' UTR included?",
          c("Yes" = "Yes", "No" = "No"),
          inline = TRUE
        )
      ),
      div(id = "promoters_overlap_div", class = "parameters_box",
        radioButtons(
          ns("promoters_overlap"),
          "Promoters' potential overlaps removed?",
          c("Yes" = "AllowOverlap", "No" = "NoOverlap"),
          inline = TRUE
        )
      )
    )
  )
}

promoters_server <- function(id, job_id, flag_upload_changed, trigger, mode, navbar) {
  moduleServer(
    id,
    function(input, output, session) {

      UPLOAD_DIR <- "data/PMETindex/uploaded_motif"
      # self uploaded genome fasta  --------------------------------------------------
      observeEvent(input$uploaded_fasta, {
        req(input$uploaded_fasta)

        # copy uploaded genome fasta to session folder for PMET to run in the back
        temp_2_local_func(UPLOAD_DIR, job_id, input$uploaded_fasta)

        flag_upload_changed[["uploaded_fasta"]] <<- 1

        # indicators for file uploaded
        if (!is.null(input$uploaded_fasta$datapath)) {
          showFeedbackSuccess(inputId = "uploaded_fasta")
        } else {
          showFeedbackDanger(inputId = "uploaded_fasta", text = "No motif")
        }
      }, ignoreInit = T)

      # self uploaded annotation  ----------------------------------------------------
      observeEvent(input$uploaded_annotation, {
        req(input$uploaded_annotation)

        # copy uploaded annotation to session folder for PMET to run in the back
        temp_2_local_func(UPLOAD_DIR, job_id, input$uploaded_annotation)

        flag_upload_changed[["uploaded_annotation"]] <<- 1

        # indicators for file uploaded
        if (!is.null(input$uploaded_annotation$datapath)) {
          showFeedbackSuccess(inputId = "uploaded_annotation")
        } else {
          showFeedbackDanger(inputId = "uploaded_annotation", text = "No annotation")
        }
      }, ignoreInit = T)

      # self uploaded motif database  ------------------------------------------------
      observeEvent(input$uploaded_meme, {
        req(inputId = "uploaded_meme")

        # copy uploaded motif to session folder for PMET to run in the back
        temp_2_local_func(UPLOAD_DIR, job_id, input$uploaded_meme)

        flag_upload_changed[["uploaded_meme"]] <<- 1

        # indicators for file uploaded
        if (!is.null(input$uploaded_meme$datapath)) {
          showFeedbackSuccess(inputId = "uploaded_meme")
        } else {
          showFeedbackDanger(inputId = "uploaded_meme", text = "No motif")
        }
      }, ignoreInit = T)

      # self genes uploaded -----------------------------------------------------------
      observeEvent(input$gene_for_pmet, {
        req(inputId = "uploaded_gene_for_pmet")

        # copy uploaded genes to result folder for PMET to run in the back
        temp_2_local_func("result", job_id, input$gene_for_pmet)
        flag_upload_changed[["gene_for_pmet"]] <<- 1

        genes_status <- check_gene_file_func_(input$gene_for_pmet$size,
                                              input$gene_for_pmet$datapath,
                                              mode = "promoters")
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

      # Download example genes file for PMET ---------------------------------------
      output$demo_genes_file_link <- downloadHandler(
        filename = function() {
          "example_genes.txt"
        },
        content = function(file) {
          write.table(read.table("data/data_for_promoters/example_genes.txt"), file, quote = FALSE, row.names = FALSE, col.names = FALSE)
        }
      )

      output$demo_motif_db_link <- downloadHandler(
        filename = function() {
          "example_motif.meme"
        },
        content = function(file) {
          data <- readLines("data/data_for_promoters/example_motif.meme")
          writeLines(data, file)
        }
      )

      elements <- c(
        "#uploaded_fasta_div",
        "#uploaded_annotation_div",
        "#uploaded_meme_div",
        "#gene_for_pmet_div",
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
        print(navbar())
        if (mode() == "promoters" & navbar() == "run_start") {
          introjs(session, options = list(steps = intro))
        }
      }, ignoreInit = F)

      list(input = input)
    }
  )
}
