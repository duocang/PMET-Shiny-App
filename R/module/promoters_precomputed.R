promoters_pre_ui <- function(id, height = 800, width = 850) {
  ns <- NS(id)
  # motif database
  div(
    div(id = "motif_db_div", class = "one_upload",
      selectInput(
        inputId = ns("motif_db"), label = "Motif database",
        choices = list(
          `Arabidopsis thaliana` = list(
            `Jaspar plants non redundant 2018` = "arabidopsis_thaliana-jaspar_plants_non_redundant_2018",
            `Jaspar plants non redundant 2022` = "arabidopsis_thaliana-jaspar_plants_non_redundant_2022",
            `Plant cistrome DB` = "arabidopsis_thaliana-plant_cistrome_DB"
          ),
          Maize = list(
            `Jaspar plants non redundant 2018` = "maize-jaspar_plants_non_redundant_2018",
            `Jaspar plants non redundant 2022` = "maize-jaspar_plants_non_redundant_2022")),
      selected = "jaspar_plants_non_redundant_2018",
      selectize = TRUE)
    ),
    div(id = "gene_for_pmet_div", class = "one_upload",
      fileInput(ns("gene_for_pmet"), "Clusters and genes", multiple = FALSE, accept = ".txt"),
      # example gene list
      downloadLink(ns("demo_genes_file_link"), "Example gene"),
      shinyjs::hidden(
        actionLink(ns("skipped_genes_link"), "Skipped genes", icon = icon("info-circle")))
    ) # end of gene_for_pmet_div
  )
}

promoters_pre_server <- function(id, job_id, trigger, mode, navbar) {
  moduleServer(
    id,
    function(input, output, session) {
      genes_skipped  <- reactiveVal(NULL) # store skipped genes for download handler

      # self genes uploaded -----------------------------------------------------------
      observeEvent(input$gene_for_pmet, {
        req(input$gene_for_pmet)
        # copy uploaded genes to result folder for PMET to run in the back
        TempToLocal("result", job_id, input[["gene_for_pmet"]])

        inputs <- reactiveValuesToList(input)

        genes_status <- CheckGeneFile(input$gene_for_pmet$size,
                                              input$gene_for_pmet$datapath,
                                              input$motif_db,
                                              mode = "promoters_pre")

        if (length(genes_status) == 3) {
          genes_skipped(genes_status[[3]])
          shinyjs::show("skipped_genes_link")
          showFeedbackWarning(
            inputId = "gene_for_pmet",
            text = paste(genes_status[[1]], "out of", genes_status[[2]], "genes are skipped"))
        } else {
          shinyjs::hide("skipped_genes_link")
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
            "no_valid_genes" = {
              showFeedbackDanger(inputId = "gene_for_pmet", text = "No valid genes available in the uploaded file")
            })
        }
      }, ignoreInit = T)

    # modal dialog shown, when link clicked (skipped genes are not nul)
    observeEvent(input$skipped_genes_link, {
      if (!is.null(genes_skipped())) {
        Sys.sleep(0.2)
        showModal(modalDialog(
          title = "Skipped genes:",
          DT::renderDataTable({ genes_skipped() }),
          footer = tagList(
            downloadButton("skipped_genes_down_btn", "Download"),
            modalButton("Cancel"))
        )) # end of showModal
      }
    })

    # Download Skipped genes when button clicked -----------------------------------
    output$skipped_genes_down_btn <- downloadHandler(
      filename = function() {
        "genes_skipped.txt"
      },
      content = function(file) { write.table(genes_skipped(), file, quote = FALSE, row.names = FALSE) }
    ) # downLoadHandler end

    # Download example genes file for PMET ---------------------------------------
    output$demo_genes_file_link <- downloadHandler(
      filename = function() {
        "example_genes.txt"
      },
      content = function(file) {
        write.table(read.table("data/data_for_promoters/example_genes.txt"), file, quote = FALSE, row.names = FALSE, col.names = FALSE)
      }
    )

    # workthrough tips of Run PMET -----------------------------------------------
    elements <- c(
        "#motif_db_div",
        "#gene_for_pmet_div"
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
