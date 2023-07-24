tabPanel(
  title = "Visualize results",
  value = "heatmap_tabpanel",
  id    = "heatmap_tabpanel",
  tags$head(tags$style(HTML(
    "
      .shiny-output-error-validation{color: red;}

      .modal {
        position: fixed;
        z-index: 1111111111;
        left: 0;
        top: 0;
        width: 100%;
        height: 100%;
        overflow: auto;
        background-color: rgba(0, 0, 0, 0.4);
      }

      .modal-content {
        background-color: #fefefe;
        margin: 15% auto;
        padding: 20px;
        border: 1px solid #888;
        width: 80%;
        max-width: 600px;
      }

      .bold-text {
        font-weight: bold;
        font-size: 1.2em;
      }

      .cluster-text {
        font-weight: bold;
        font-size: 16px;
      }

      .genes-text {
        font-size: 13px;
        white-space: pre-wrap;
      }
      .line-number::before {
        content: attr(data-line-number);
        display: inline-block;
        width: 2em;
        text-align: right;
        padding-right: 0.5em;
        user-select: none;
      }


      .close {
        color: #aaa;
        float: right;
        font-size: 28px;
        font-weight: bold;
      }

      .close:hover,
      .close:focus {
        color: black;
        text-decoration: none;
        cursor: pointer;
      }

    "
  ))),
  sidebarLayout(
    sidebarPanel(
      width = 4,
      # Tell shiny what version of d3 we want
      tags$script(src='//d3js.org/d3.v3.min.js'),
      # Input: Select a file ----
      div(id = "pmet_result_file_div",
        fileInput("pmet_result_file", "Choose a PMET result", multiple = FALSE, accept = ".txt"),
        downloadLink("demo_pmet_result_download", "Example file")
      ),
      div(id = "motif_pair_unique_div",
        selectInput("motif_pair_unique", "Motif-pair UNIQUE in each cluster:",
          c("TRUE" = TRUE, "FALSE" = FALSE),
          multiple = FALSE
        )
      ),
      div(id = "method_div",
        selectInput("method", "Choose a cluster:", c("All"))
      ),
      div(id = "topn_pair_div",
        numericInput("topn_pair", "Top motif-pair:", 5, min = 1, step = 1)
      ),
      div(id = "p_adj_div",
        numericInput("p_adj", "P.adj:", 0.05, min = 0, max = 1, step = 0.001)
      ),
      div(style = "display:flex;justify-content:center;align-items:center;margin-top:30px",
          shinyjs::hidden(actionButton(
            "plot.button",
            "Plot",
            icon = icon("paint-brush"),
            style = "width: 120px;color:#ffff;background-color:#fb8b05;")),
          shinyjs::hidden(downloadButton("download.button",
            "Download",
            class = "btn-success",
            style = "width: 120px;margin-left: 50px;"))
      )
    ),
    mainPanel(
      add_busy_spinner(spin = "cube-grid"),
      tabsetPanel(
        type = "tabs",
        id = "heat_map_tabs",
        tabPanel(
          title = "Heat map",
          value = "heatmap",
          id    = "heatmap",
          div(id = "placeholder", uiOutput("d3"))),
        tabPanel(
          title = "Motifs",
          value = "motifs",
          id    = "motifs",
          verbatimTextOutput("dimension_display")),
        tabPanel("Data viewer", uiOutput(("datatable_tabs")))
      ),
      # tooltip for d3 heatmap
      tags$div(
        id = "tooltip",
        class = "hidden",
        tags$p(
          tags$span(id = "value")
        )
      )
    )
  )
)
