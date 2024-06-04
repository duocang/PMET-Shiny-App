library(shiny)
library(dplyr)
library(ggplot2)
library(gapminder)

# Specify the application port
options(shiny.host = "0.0.0.0")
options(shiny.port = 8180)

# ui <- fluidPage(
#   sidebarLayout(
#     sidebarPanel(
#       tags$h4("Gapminder Dashboard"),
#       tags$hr(),
#       selectInput(inputId = "inContinent", label = "Continent", choices = unique(gapminder$continent), selected = "Europe"),
#       tags$p(id = "currentDir", "Current Shiny Directory: "),
#       tags$p(id = "libPaths", "Library Paths: ")
#     ),
#     mainPanel(
#       plotOutput(outputId = "outChartLifeExp"),
#       plotOutput(outputId = "outChartGDP"),
#       actionButton(inputId = "printInfo", label = "Print Info")
#     )
#   )
# )
ui <- fluidPage(
  sidebarLayout(
    sidebarPanel(
      tags$h4("Gapminder Dashboard"),
      tags$hr(),
      selectInput(inputId = "inContinent", label = "Continent", choices = unique(gapminder$continent), selected = "Europe"),
      tags$p(id = "currentDirLabel", "Current Shiny Directory: "),
      tags$p(id = "currentDir", "", class = "infoText"),
      tags$p(id = "libPathsLabel", "Library Paths: "),
      tags$p(id = "libPaths", "", class = "infoText")
    ),
    mainPanel(
      plotOutput(outputId = "outChartLifeExp"),
      plotOutput(outputId = "outChartGDP"),
      actionButton(inputId = "printInfo", label = "Print Info")
    )
  )
)



server <- function(input, output, session) {
  # Filter data and store as reactive value
  data <- reactive({
    gapminder %>%
      filter(continent == input$inContinent) %>%
      group_by(year) %>%
      summarise(
        AvgLifeExp = round(mean(lifeExp)),
        AvgGdpPercap = round(mean(gdpPercap), digits = 2)
      )
  })

  # Common properties for charts
  chart_theme <- ggplot2::theme(
    plot.title = element_text(hjust = 0.5, size = 20, face = "bold"),
    axis.title.x = element_text(size = 15),
    axis.title.y = element_text(size = 15),
    axis.text.x = element_text(size = 12),
    axis.text.y = element_text(size = 12)
  )

  # Render Life Exp chart
  output$outChartLifeExp <- renderPlot({
    ggplot(data(), aes(x = year, y = AvgLifeExp)) +
      geom_col(fill = "#0099f9") +
      geom_text(aes(label = AvgLifeExp), vjust = 2, size = 6, color = "#ffffff") +
      labs(title = paste("Average life expectancy in", input$inContinent)) +
      theme_classic() +
      chart_theme
  })

  # Render GDP chart
  output$outChartGDP <- renderPlot({
    ggplot(data(), aes(x = year, y = AvgGdpPercap)) +
      geom_line(color = "#f96000", size = 2) +
      geom_point(color = "#f96000", size = 5) +
      geom_label(
        aes(label = AvgGdpPercap),
        nudge_x = 0.25,
        nudge_y = 0.25
      ) +
      labs(title = paste("Average GDP per capita in", input$inContinent)) +
      theme_classic() +
      chart_theme
  })

  # Function to print current directory and library paths
  printInfo <- function() {
    currentDir <- getwd()
    libPaths <- .libPaths()
    updateTextInput(session, "currentDir", value = paste("Current Shiny Directory: ", currentDir))
    updateTextInput(session, "libPaths", value = paste("Library Paths: ", paste(libPaths, collapse = ", ")))
  }

  # Observe the action button and update text when clicked
  observeEvent(input$printInfo, {
    printInfo()
  })
}

# shinyApp(ui = ui, server = server)


shinyApp(ui = ui, server = server)