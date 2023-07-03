suppressMessages({
  # Used packages
  pacotes <- c(
    "bslib",              # customizing the appearance of Shiny applications using Bootstrap.
    "data.table",         # fast data manipulation and analysis.
    "DT",                 # creating interactive and customizable data tables in R.
    "dplyr",              # data manipulation and transformation using a consistent grammar.
    "fullPage",           # creating full-page scrolling websites.
    "future",
    "ggasym",             # creating asymmetric visualizations with ggplot2.
    "ggpubr",             # enhancing ggplot2 visualizations with publication-ready themes and annotations.
    "glue",               # interpolating strings and expressions in R.
    "jsonify",
    "kableExtra",         # creating complex tables in R Markdown documents.
    "openxlsx",           # reading, writing, and manipulating Microsoft Excel files.
    "promises",           # creating and managing asynchronous programming in R.
    "purrr",              # functional programming and iterating over data structures.
    "reshape2",           # transforming and restructuring data in R.
    "rintrojs",           # creating interactive and guided tours in Shiny applications.
    "scales",             # controlling the scaling of data in R graphics.
    "shiny",              # building interactive web applications in R.
    "shinyBS",            # adding additional Bootstrap functionality to Shiny applications.
    "shinydashboard",     # creating dashboards with a tabbed layout in Shiny.
    "shinydisconnect",    # handling disconnections and reconnections in Shiny applications.
    "shinyFeedback",      # providing user feedback and notifications in Shiny applications.
    "shinycssloaders",    # adding CSS loaders to Shiny applications.
    "shinyjs",            # easily incorporating JavaScript functions and events in Shiny applications.
    "shinythemes",        # customizing the appearance of Shiny applications with predefined themes.
    "shinyvalidate",      # client-side form validation in Shiny applications.
    "shinyWidgets",       # creating custom UI controls and widgets in Shiny.
    "snow",               # parallel computing using a simple network of workstations.
    "tibble",             # creating and manipulating data frames with enhanced features compared to traditional data frames.
    "tidyverse",          # data manipulation, visualization, and analysis.
    "tictoc",             # measuring the time taken by R code execution.
    "shinyvalidate",      # shinyvalidate adds input validation capabilities to Shiny.
    "zip"                 # reading, writing, and manipulating ZIP archives in R.
)

  # verify required packages installed or not. If some package
  # is missing, it will be installed automatically
  package.check <- lapply(pacotes, FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
      install.packages(x, dependencies = TRUE)
    }
  })

  source("R/utils/utils.R")
  source("R/utils/shiny_busy_indicator.R")
  # source("R/module/heatmap.R")
  source("R/module/tab_table.R")
  source("R/module/promoters.R")
  source("R/module/promoters_precomputed.R")
  source("R/module/intervals.R")
  source("R/utils/command_call_pmet.R")
  source("R/utils/pid_pmet_finder.R")
  source("R/utils/paths_of_repeative_run.R")
  source("R/utils/check_gene_file_fucn.R")
  source("R/utils/process_pmet_result.R")
  source("R/utils/motif_pair_plot_homog.R")
  source("R/utils/motif_pair_plot_hetero.R")
  source("R/utils/motif_pair_diagonal.R")
  source("R/utils/motif_pair_gene_diagonal.R")
})

options(shiny.maxRequestSize = 30000 * 1024^2)
plan(multisession)

