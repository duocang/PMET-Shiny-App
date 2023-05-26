suppressMessages({
  library(tibble)
  library(jsonify)
  library(shinyjs)
  library(openxlsx)
  library(rintrojs)
  library(fullPage)
  library(shinyWidgets)
  library(bslib)
  library(purrr)

  # Used packages
  pacotes <- c(
    "tictoc",
    "shiny",
    "shinyBS",
    "shinydashboard",
    "shinythemes",
    "shinyvalidate",
    "shinycssloaders",
    "DT",
    "data.table",
    "tidyverse",
    "scales",
    "kableExtra",
    "dplyr",
    "reshape2",
    "ggpubr",
    "ggasym",
    "zip",
    "shinyFeedback",
    "promises",
    "future",
    "glue"
  )

  source("utils/utils.R")
  source("utils/helpers.R")
  # source("module/heatmap.R")
  source("module/tab_table.R")
  source("utils/command_call_pmet.R")
  source("utils/create_forked_task.R")
  source("utils/send_mail.R")
  # Run the following command to verify that the required packages are installed. If some package
  # is missing, it will be installed automatically
  package.check <- lapply(pacotes, FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE)
    }
  })
})

options(shiny.maxRequestSize = 30000 * 1024^2)
plan(multisession)

# Get lower triangle of the correlation matrix
get_lower_tri <- function(cormat) {
  cormat[upper.tri(cormat)] <- NA
  return(cormat)
}
# Get upper triangle of the correlation matrix
get_upper_tri <- function(cormat) {
  cormat[lower.tri(cormat)] <- NA
  return(cormat)
}
