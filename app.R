Sys.setenv(R_LIBS_USER = "/usr/local/lib/R/library")
.libPaths(new = "/usr/local/lib/R/library")

source("R/app.R")

shinyApp(ui = ui, server = server)
# shinyApp(ui = ui, server = server, options = list(port = 9834, shiny.autoreload = TRUE))
