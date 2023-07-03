source("R/global.R")

ui <- fluidPage(
  # shinythemes::themeSelector(),  # <--- Add this somewhere in the UI
  disconnectMessage2(),
  useShinyjs(),
  navbarPage(
    id = "navbar",
    theme = shinytheme("paper"),
    header = includeCSS("www/shiny.css"),
    title = "PMET",
    source("R/ui/tab_home.R"   , local = TRUE)$value,
    source("R/ui/tab_start.R"  , local = TRUE)$value,
    source("R/ui/tab_visualize.R", local = TRUE)$value,
    source("R/ui/tab_about.R"  , local = TRUE)$value,
    source("R/ui/tab_author.R" , local = TRUE)$value
  ),
  style = "padding: 0px;"
  # , # no gap in navbar
  # actionButton("show_tutorial", "Tips", style = "position: absolute; top: 15px; right: 5px; z-index:10000;")
)

server <- function(input, output, session) {
  source("R/server/tab_home.R"   , local = TRUE)$value
  source("R/server/tab_start.R"  , local = TRUE)$value
  source("R/server/tab_visualize.R", local = TRUE)$value
  source("R/server/tab_about.R"  , local = TRUE)$value
  source("R/server/tab_author.R" , local = TRUE)$value
}
