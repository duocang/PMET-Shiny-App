tabPanel(
  title = "Analyze PMET",
  value = "heatmap_tabpanel",
  id    = "heatmap_tabpanel",
  tags$head(tags$style(HTML(".shiny-output-error-validation{color: red;}"))),
  sidebarLayout(
    sidebarPanel(
      width = 4,
      # get window size and access via input$dimension[1] and input$dimension[2] in server side
      tags$head(tags$script('
          var dimension = [0, 0];
          $(document).on("shiny:connected", function(e) {
            dimension[0] = window.innerWidth;
            dimension[1] = window.innerHeight;
            Shiny.onInputChange("dimension", dimension);
          });
          $(window).resize(function(e) {
              dimension[0] = window.innerWidth;
              dimension[1] = window.innerHeight;
              Shiny.onInputChange("dimension", dimension);
          });')),
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
      div(
        actionButton(
          "plot.button",
          "Plot",
          icon = icon("paint-brush"),
          style = "color: #ffff; background-color: #fb8b05;"),
        downloadButton("download.button", "Download", class = "btn-success")
      ),
      div(
        actionButton("download.svg", "Download SVG")
      )
    ),
    mainPanel(
      # bsCollapse(id = "heat_map_tabs", open = "Heat map",
      #   bsCollapsePanel("Heat map"    , div(id = "placeholder", uiOutput("d3"))),
      #   bsCollapsePanel("Motifs"      , verbatimTextOutput("dimension_display")),
      #   bsCollapsePanel("Data viewer" , uiOutput(("datatable_tabs")) )
      # )
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
