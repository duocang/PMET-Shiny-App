tabPanel(
  introjsUI(),
  useShinyFeedback(),
  title = "Run PMET",
  value = "run_tabpanel",
  pageWithSidebar(
    dashboardHeader(disable = TRUE),
    sidebarPanel(
      width = 4,
      # promoters
      div(
        id = "promoters_div",
        div("Type of Sequences:", class = "big_font"),
        radioButtons("sequence_type", NULL,
          c("Promoters" = "promoters", "Genomic intervals" = "intervals"),
          inline = TRUE
        )
      ),
      # motif database
      div(
        id = "motif_db_class",
        selectInput(
          inputId = "motif_db", label = "Motif database",
          choices = list(
            `Arabidopsis thaliana` = list(
              `Jaspar plants non redundant 2018` = "arabidopsis_thaliana-jaspar_plants_non_redundant_2018",
              `Jaspar plants non redundant 2022` = "arabidopsis_thaliana-jaspar_plants_non_redundant_2022",
              `Plant cistrome DB` = "arabidopsis_thaliana-plant_cistrome_DB"
            ),
            Maize = list(
              `Jaspar plants non redundant 2018` = "maize-jaspar_plants_non_redundant_2018",
              `Jaspar plants non redundant 2022` = "maize-jaspar_plants_non_redundant_2022"
            ),
            `Not found` = list(`Upload` = "uploaded_motif")
          ),
          selected = "jaspar_plants_non_redundant_2018",
          selectize = TRUE
        ),
        # div(id = "motif_db_div", uiOutput("motif_db_output")),
        div(
          id = "uploaded_meme_div",
          fileInput("uploaded_meme", "Upload motif meme file",
            multiple = FALSE,
            accept = ".meme"
          ),
          downloadLink("demo_motif_db_link", "Example motif DB")
        )
      ),
      div(
        id = "uploaded_fasta_div",
        fileInput("uploaded_fasta", "Upload genome file",
          multiple = FALSE,
          accept = c(".fasta", ".fa")
        ),
        tags$a(
          href = "https://ftp.ensemblgenomes.ebi.ac.uk/pub/plants/release-56/fasta/arabidopsis_thaliana/dna/Arabidopsis_thaliana.TAIR10.dna.toplevel.fa.gz",
          download = "example_annotation.gff3",
          "Example genome"
        )
      ), # end of uploaded_fasta_div
      div(
        id = "uploaded_annotation_div",
        fileInput("uploaded_annotation", "Upload annotation file",
          multiple = FALSE,
          accept = ".gff3"
        ),
        tags$a(
          href = "https://ftp.ensemblgenomes.ebi.ac.uk/pub/plants/release-56/gff3/arabidopsis_thaliana/Arabidopsis_thaliana.TAIR10.56.gff3.gz",
          download = "example_annotation.gff3",
          "Example annotation"
        )
      ), # end of uploaded_annotation_div
      div(
        id = "gene_for_pmet_div",
        fileInput("gene_for_pmet", "Gene clusters and genes",
          multiple = FALSE,
          accept = ".txt"
        ),
        # example gene list
        downloadLink("demo_genes_file_link", "Example gene"),
        shinyjs::hidden(
          actionLink(
            "skipped_genes_link",
            "Skipped genes",
            icon = icon("info-circle")
          )
        )
      ), # end of gene_for_pmet_div
      # parameters
      div(
        id = "parameters_div",
        div("Parameters", class = "big_font"),
        fluidRow(
          class = "parameters_id",
          div(
            id = "promoter_length_div",
            selectInput(
              inputId = "promoter_length",
              label = "Promoter Length",
              choices = c(500, 1000, 1500, 2000),
              selected = 1000
            )
          ),
          div(
            id = "max_motif_matches_div",
            selectInput(
              inputId = "max_motif_matches", label = "Max motif matches",
              choices = c(2, 3, 4, 5, 10, 15, 20), selected = 5
            )
          ),
          div(
            id = "promoter_number_div",
            selectInput(
              inputId = "promoter_number",
              label = "Number of selected promoters/intervals",
              choices = c(2000, 3000, 4000, 5000, 10000),
              selected = 5000
            )
          )
        ),
        div(
          id = "utr5_div",
          radioButtons(
            "utr5", "5' UTR included?",
            c("Yes" = "Yes", "No" = "No"),
            inline = TRUE
          )
        ),
        div(
          id = "promoters_overlap_div",
          radioButtons(
            "promoters_overlap",
            "Promoters' potential overlaps removed?",
            c("Yes" = "AllowOverlap", "No" = "NoOverlap"),
            inline = TRUE
          )
        )
      ),

      # personal info
      div(
        id = "userEmail_div",
        textInput("userEmail", "Email", value = "")
      ),
      # action button
      div(
        class = "run_pmet_div",
        shinyjs::hidden(
          shiny::div(
            id = "run_pmet_button_div",
            withBusyIndicatorUI(
              loadingButton("run_pmet_button",
                label = "Run PMET",
                loadingLabel = "Running...",
                style = "width: 135px"
              )
            ),
            shinyjs::hidden(
              div(
                id = "stop_bnt_div",
                style = "margin-bottom:30px; margin-top:20px;",
                actionButton("stop", "Stop",
                  style = "color: #ffff; background-color: #e95420; width: 135px"
                )
              )
            )
          )
        )
      ),
      # Download PMET result button
      div(
        id = "pmet_result_download_ui_div",
        style = "margin-bottom:30px; margin-top:20px;",
        uiOutput("pmet_result_download_ui"),
        uiOutput("pmet_result_download_ui1")
      ),
      actionButton("test", "Analyze PMET")
    ),
    mainPanel()
  )
)
