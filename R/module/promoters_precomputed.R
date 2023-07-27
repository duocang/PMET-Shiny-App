promoters_pre_ui <- function(id, height = 800, width = 850) {
    tags$head(
    )
  ns <- NS(id)
  # motif database
  div(
    div(id = "species_div", style = "margin-bottom: 10px;",
      selectInput(ns("species"), label = "Species", NULL)
    ),
    div(id = "premade_div", style = "margin-bottom: 10px;",
      selectInput(inputId = ns("premade"), label = "Motif database", NULL)
    ),
    div(id = ns("genes_div"), style = "margin-bottom: 10px;",
      # uiOutput(ns("genes_uiOutput"))
      shinyjs::disabled(
        div(id= ns("gene_fileinput"),
          fileInput(ns("genes"), "Clusters and genes", multiple = FALSE, accept = ".txt")
        )
      ),
      # example gene list
      downloadLink(ns("demo_genes"), "Example gene for Arabidopsis thaliana"),
      shinyjs::hidden(
        actionLink(ns("genes_not_found_link"), "Genes not found", icon = icon("info-circle"), style = "color: #F89406;font-weight: bold; font-size: 14px;")
      )
    ),# end of genes_div
    bsTooltip(id = ns("gene_fileinput"),
              title = "Please select a species and a motif database",
              placement = "top",
              trigger = "hover",
              options = list(delay = list(show = 500, hide = 100))),
    # parameters
    div(id = ns("parameters_div"), style = "margin-bottom: 10px;",
      div("Parameters", style = "font-size: 16px; font-weight: bold;"),
      fluidRow(
        div(class = "selectInput_div",
          class = "parameters_id", style = "padding-left:15px; padding-right:15px;",
          div(id = "promoter_length_div",
            shinyjs::disabled(
              selectInput(
                inputId = ns("promoter_length"),
                label = "Promoter Length",
                choices = c(500, 1000, 1500, 2000),
                selected = 1000
              )
            )
          ),
          div(id = "max_match_div",
            shinyjs::disabled(
              selectInput(
                inputId = ns("max_match"), label = "Max motif matches",
                choices = c(2, 3, 4, 5, 10, 15, 20),
                selected = 5
              )
            )
          ),
          div(id = "promoter_num_div",
            shinyjs::disabled(
              selectInput(
                inputId = ns("promoter_num"),
                label = "Number of selected promoters",
                choices = c(2000, 3000, 4000, 5000, 10000),
                selected = 5000
              )
            )
          ),
          div(id = "fimo_threshold_div",
            shinyjs::disabled(
              selectInput(
                inputId = ns("fimo_threshold"),
                label = "Fimo threshold",
                choices = c(0.000001, 0.00001, 0.0001, 0.001, 0.01, 0.05),
                selected = 0.05
              )
            )
          ),
          div(id = "ic_threshold_div",
            shinyjs::disabled(
              selectInput(
                inputId = ns("ic_threshold"),
                label = "Information content threshold",
                choices = c(2, 4, 8, 10, 16, 24, 32),
                selected = 4
              )
            )
          )
        ),
        div(class = "radioButtons_div", style = "padding-left:15px; padding-right:15px;",
          div(id = "utr5_div",
            shinyjs::disabled(
              radioButtons(
                ns("utr5"), "5' UTR included?",
                c("Yes" = "Yes", "  No" = "No"),
                inline = TRUE
              )
            )
          ),
          div(id = "promoters_overlap_div",
            shinyjs::disabled(
              radioButtons(
                ns("promoters_overlap"),
                "Promoters' potential overlaps removed?",
                c("Yes" = "AllowOverlap", "No" = "NoOverlap"),
                inline = TRUE
              )
            )
          )
        )
      )
    ) # parameters_div
  )
}

promoters_pre_server <- function(id, job_id, tutorial_trigger, mode, navbar) {
  moduleServer(
    id,
    function(input, output, session) {
      ns <- session$ns

      # by default , species left empty
      # species_list <- list(
      #     species = list(
      #       `Aarabidopsis thaliana`               = "Arabidopsis_thaliana",
      #       `Brachypodium distachyon`             = "Brachypodium_distachyon",
      #       `Brassica napus`                      = "Brassica_napus",
      #       `Glycine max`                         = "Glycine_max",
      #       `Hordeum vulgare`                     = "Hordeum_vulgare",
      #       `Hordeum vulgare goldenpromise`       = "Hordeum_vulgare_goldenpromise",
      #       `Hordeum vulgare (Morex V3)`          = "Hordeum_vulgare_Morex_V3",
      #       `Hordeum vulgare (R1)`                = "Hordeum_vulgare_R1",
      #       `Hordeum vulgare (v082214v1)`         = "Hordeum_vulgare_v082214v1",
      #       `Medicago truncatula`                 = "Medicago_truncatula",
      #       `Oryza sativa indica (9311)`          = "Oryza_sativa_indica_9311",
      #       `Oryza sativa indica (IR8)`           = "Oryza_sativa_indica_IR8",
      #       `Oryza sativa indica (MH63)`          = "Oryza_sativa_indica_MH63",
      #       `Oryza sativa indica (ZS97)`          = "Oryza_sativa_indica_ZS97",
      #       `Oryza sativa japonica (Ensembl)`     = "Oryza_sativa_japonica_Ensembl",
      #       `Oryza sativa japonica (Kitaake)`     = "Oryza_sativa_japonica_Kitaake",
      #       `Oryza sativa japonica (Nipponbare)`  = "Oryza_sativa_japonica_Nipponbare",
      #       `Oryza sativa japonica (v7.1)`        = "Oryza_sativa_japonica_V7.1",
      #       `Solanum lycopersicum`                = "Solanum_lycopersicum",
      #       `Solanum tuberosum`                   = "Solanum_tuberosum",
      #       `Triticum aestivum`                   = "Triticum_aestivum",
      #       `Zea mays`                            = "Zea_mays"
      #     )
      # )
      species_list <- SPECIES_LIST
      # present selction options in species input field
      observe({
        req(navbar())
        req(mode())

        updateSelectInput(session, "species", choices = species_list, selected = species_list[length(species_list)])
      })

      observe({
        req(navbar())
        req(mode())
        req(input$species)

        if(input$species != "") {
          # shinyjs::show("premade")

          choices_list <- list("Motif Database" = MOTIF_DB[[input$species]])
          updateSelectInput(session, "premade", choices = choices_list, selected = choices_list[length(choices_list)])
        }
      })

      # eable gene upload
      observe({
        req(input$premade, input$species)
        shinyjs::enable("gene_fileinput")
        removeTooltip(session, ns("gene_fileinput"))
      })

      # self genes uploaded -----------------------------------------------------------
      genes_not_found  <- reactiveVal(NULL) # store genes not found for download handler
      observeEvent(input$genes, {

        req(input$genes, input$genes != "", input$premade, input$species)
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

      observeEvent(tutorial_trigger(), {
        if (mode() == "promoters_pre" & navbar() == "run_start") {
          introjs(session, options = list(steps = intro))
        }
      }, ignoreInit = F)

      list(input = input)
    })
}
