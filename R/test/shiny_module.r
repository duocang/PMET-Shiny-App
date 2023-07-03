library(shiny)

numericInputModUI <- function (id) {
  ns <- NS(id)
  tagList(
    numericInput(ns("val"), "Value", value = 0),
    textOutput(ns("text"))
  )
}

numericInputMod <- function (input, output, session, updateVal = NA,
                             displayText = "default text", trig) {

  output$text <- renderText(displayText())

  observeEvent(trig(), ignoreInit = TRUE, {
    updateNumericInput(session, "val", value = updateVal())
  })

}

ui = fluidPage(
  numericInputModUI("module"),
  actionButton("updateBad", label = "Bad Update"),
  actionButton("updateBetter", label = "Better Update")
)

server = function(input, output, session) {

  vals <- reactiveValues(dText = "original text", uVal = NA, trig = 0)

  observeEvent(input$updateBad, {
    vals$dText <- "default text"
    vals$uVal <- 1
    vals$trig <- vals$trig + 1
  })

  observeEvent(input$updateBetter, {
    vals$dText <- "original text"
    vals$uVal <- 2
    vals$trig <- vals$trig + 1
  })

  callModule(numericInputMod, "module", 
             displayText = reactive(vals$dText), 
             updateVal = reactive(vals$uVal),
             trig = reactive(vals$trig))

}

shinyApp(ui, server)