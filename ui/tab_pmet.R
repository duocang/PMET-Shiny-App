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
        id = "promoters_div", class = "div_size",
        div("Type of Sequences:", class = "big_font"),
        radioButtons("a", NULL,
          c("Promoters" = "promoters", "Genomic intervals" = "intervals"),
          inline = TRUE
        )
      ),

      # species
      div(
        id = "species_div", class = "div_size",
        # div("Species", class="big_font"),
        selectInput("species", "Species",
          c("Arabidopsis thaliana"),
          selected = "Arabidopsis thaliana"
        )
      ),
      # input files
      div(
        id = "input_file_div", class = "div_size",
        # div("Input Files:", class="big_font"),
        # motif database
        div(
          id = "motif_db_div",
          selectInput(
            inputId = "motif_db", label = "Motif database",
            choices = c("jaspar_2018", "jaspar_2022", "plant_cistrome_DB"),
            selected = "jaspar2018"
          )
        ),
        div(
          id = "gene_for_pmet_div",
          fileInput("gene_for_pmet", "Gene clusters and genes",
            multiple = FALSE,
            accept = ".txt"
          ),
          # example gene list
          downloadLink("demo_genes_file_link", "Example file"),
          # actionLink("demo_genes_file_link", "Example file"),

          shinyjs::hidden(
            actionLink(
              "skipped_genes_link",
              "Skipped genes",
              icon = icon("info-circle")
          ))
        ) # end of gene_for_pmet_div
      ),


      # parameters
      div(
        id = "parameters_div", class = "div_size",
        div("Parameters", class = "big_font"),
        fluidRow(
          class = "parameters_id",
          selectInput(
            inputId = "promoter_length", label = "Promoter Length",
            choices = c(500, 1000, 1500, 2000), selected = 1000
          ),
          selectInput(
            inputId = "max_motif_matches", label = "Max motif matches",
            choices = c(2, 3, 4, 5, 10, 15, 20), selected = 5
          ),
          selectInput(
            inputId = "promoter_number", label = "Number of selected promoters/intervals",
            choices = c(2000, 3000, 4000, 5000, 10000), selected = 5000
          )
        ),
        radioButtons("utr5", "5' UTR included?",
          c("Yes" = "promoters", "No" = "exp"),
          inline = TRUE
        ),
        radioButtons("promoters_overlap", "Promoters' potential overlaps removed?",
          c("Yes" = "promoters", "No" = "exp"),
          inline = TRUE
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
      )
    ),
    mainPanel()
  )
)
