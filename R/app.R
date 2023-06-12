source("R/global.R")

ui <- fluidPage(
  useShinyjs(),
  navbarPage(
    id = "navbar",
    theme = shinytheme("paper"),
    header = includeCSS("R/www/shiny.css"),
    title = "PMET",
    # include the UI for each tab
    source("R/ui/tab_home.R", local = TRUE)$value,
    source("R/ui/tab_pmet.R", local = TRUE)$value,
    source("R/ui/tab_heatmap.R", local = TRUE)$value,
    # source("ui/tab_dataviewer.R", local = TRUE)$value,
    source("R/ui/tab_about.R", local = TRUE)$value,
    source("R/ui/tab_author.R", local = TRUE)$value
  ),
  style = "padding: 0px;", # no gap in navbar
  actionButton("show_tutorial", "Tips",
    style = "position: absolute; top: 15px; right: 5px; z-index:10000;"
  )
)

server <- function(input, output, session) {
  # Include the logic (server) for each tab
  source("R/server/tab_home.R", local = TRUE)$value
  source("R/server/tab_pmet.R", local = TRUE)$value
  source("R/server/tab_heatmap.R", local = TRUE)$value
  # source("server/tab_dataviewer.R", local = TRUE)$value
  source("R/server/tab_about.R", local = TRUE)$value
  source("R/server/tab_author.R", local = TRUE)$value


  # workthrough tips of Run PMET ------------------------------------------------------
  navbar_visited <- c()
  pmet_tips <- reactive({
    elements <- c(
      "#promoters_div",
      "#motif_db_class",
      "#uploaded_fasta_div",
      "#uploaded_annotation_div",
      "#gene_for_pmet_div",
      "#parameters_div",
      "#userEmail_div"
    )
    intors <- c(
      "Choose type of input sequences",
      "Upload your own motif file or choose from the available defaults",
      "Genome file",
      "Annotation file",
      "A tab separated file containing the gene set number and gene.",
      "Fine tuning of PMET",
      "Email address to receive notifications"
    )
    data.frame(element = elements, intro = intors)
  })

  heatmap_tips <- reactive({
    elements <- c(
      "#pmet_result_div",
      "#motif_pair_unique_div",
      "#method_div",
      "#topn_pair_div",
      "#p_adj_div"
    )

    intors <- c("a", "b", "c", "d", "e")
    data.frame(element = elements, intro = intors)
  })
  observe({
    # when current page is in records of visited, then show no workthrough
    if (!(input$navbar %in% navbar_visited)) {
      switch(input$navbar,
        # "home_tabpanel"    = introjs(session, options = list(steps = home_steps())),
        "run_tabpanel"     = introjs(session, options = list(steps = pmet_tips())),
        "heatmap_tabpanel" = introjs(session, options = list(steps = heatmap_tips())))
    }
    # update records of visited page
    navbar_visited <<- c(navbar_visited, input$navbar) %>% unique()
  })

  # show walk through when button is clicked
  observeEvent(input$show_tutorial, {
    switch(input$navbar,
      # "home_tabpanel"    = introjs(session, options = list(steps = home_steps())),
      "run_tabpanel"     = introjs(session, options = list(steps = pmet_tips())),
      "heatmap_tabpanel" = introjs(session, options = list(steps = heatmap_tips())))
  })
}