source("global.R")

cat("Click the Link\n\n\n")
cat("Click the Link\n\n\n")
cat("Click the Link\n\n\n")

options(servr.port = 9999)
ui <- fluidPage(
  useShinyjs(),
  navbarPage(
    id = "navbar",
    theme = shinytheme("paper"),
    header = includeCSS("www/shiny.css"),
    title = "PMET",
    # include the UI for each tab
    source("ui/tab_home.R", local = TRUE)$value,
    source("ui/tab_pmet.R", local = TRUE)$value,
    source("ui/tab_heatmap.R", local = TRUE)$value,
    # source("ui/tab_dataviewer.R", local = TRUE)$value,
    source("ui/tab_about.R", local = TRUE)$value,
    source("ui/tab_author.R", local = TRUE)$value
    # tags$script(
    #   HTML("var header = $('.navbar > .container-fluid');
    #         header.append('<div style=\"float:right; padding-top: 8px\"><button id=\"signin\" type=\"button\" class=\"btn btn-primary action-button\" onclick=\"signIn()\">Shoe me</button></div>')")
    # )
  ),
  style = "padding: 0px;", # no gap in navbar
  actionButton("show_tutorial", "Tutorial",
    style = "position: absolute; top: 15px; right: 5px; z-index:10000;"
  )
)

server <- function(input, output, session) {
  # Include the logic (server) for each tab
  source("server/tab_home.R", local = TRUE)$value
  source("server/tab_pmet.R", local = TRUE)$value
  source("server/tab_heatmap.R", local = TRUE)$value
  # source("server/tab_dataviewer.R", local = TRUE)$value
  source("server/tab_about.R", local = TRUE)$value
  source("server/tab_author.R", local = TRUE)$value


  # walk through
  navbar_visited <- c()
  observe({
    # when current page is in records of visited, then show no workthrough
    if (!(input$navbar %in% navbar_visited)) {
      switch(input$navbar,
        # "home_tabpanel"    = introjs(session, options = list(steps = home_steps())),
        "run_tabpanel"     = introjs(session, options = list(steps = run_pmet_steps())),
        "heatmap_tabpanel" = introjs(session, options = list(steps = heatmap_steps()))
      )
    }
    # update records of visited page
    navbar_visited <<- c(navbar_visited, input$navbar) %>% unique()
  })

  # show walk through when button is clicked
  observeEvent(input$show_tutorial, {
    switch(input$navbar,
      # "home_tabpanel"    = introjs(session, options = list(steps = home_steps())),
      "run_tabpanel"     = introjs(session, options = list(steps = run_pmet_steps())),
      "heatmap_tabpanel" = introjs(session, options = list(steps = heatmap_steps()))
    )
  })
}

# shinyApp(ui = ui, server = server)
shinyApp(ui = ui, server = server, options = list(port = 9834))
