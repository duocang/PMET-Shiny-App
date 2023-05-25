ui_data <- function(id, title) {
  ns <- NS(id)
  tabPanel(uiOutput(ns("body")))
}

server_data <- function(id, input_data) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    sampledata <- reactive(mtcars)

    output$body <- renderUI({
      all_cyl <- names(input_data) %>% sort()

      tabs <- lapply(all_cyl, function(cyl) {
        tabPanel(cyl, shinydashboard::box(dataTableOutput(ns(cyl))))
      }) # tabs
      do.call(tabsetPanel, tabs)
    }) # end of renderUI

    observe({
      all_cyl <- names(input_data) %>% sort()

      lapply(all_cyl, function(cyl) {
        output[[cyl]] <- renderDataTable({
          input_data[[cyl]]
        })
      })
    })
  })
}
