source("R/app.R")

# shinyApp(ui = ui, server = server)
shinyApp(ui = ui, server = server, options = list(port = 9834))
