# Sys.setenv(R_LIBS_USER = "/usr/local/lib/R/library")
# .libPaths(new = "/usr/local/lib/R/library")

options(shiny.maxRequestSize = 30000 * 1024^2)

suppressMessages({
#   # Used packages
#   pacotes <- c(
#     "emayili",
#     "bslib",              # customizing the appearance of Shiny applications using Bootstrap.
#     "data.table",         # fast data manipulation and analysis.
#     "DT",                 # creating interactive and customizable data tables in R.
#     "dplyr",              # data manipulation and transformation using a consistent grammar.
#     "fullPage",           # creating full-page scrolling websites.
#     "future",
#     "ggasym",             # creating asymmetric visualizations with ggplot2.
#     "ggpubr",             # enhancing ggplot2 visualizations with publication-ready themes and annotations.
#     "glue",               # interpolating strings and expressions in R.
#     "kableExtra",         # creating complex tables in R Markdown documents.
#     "openxlsx",           # reading, writing, and manipulating Microsoft Excel files.
#     "promises",           # creating and managing asynchronous programming in R.
#     "purrr",              # functional programming and iterating over data structures.
#     "reshape2",           # transforming and restructuring data in R.
#     "rintrojs",           # creating interactive and guided tours in Shiny applications.
#     "rjson",              # converts R object into JSON objects and vice-versa.
#     "rtracklayer",        # read gff3
#     "scales",             # controlling the scaling of data in R graphics.
#     "seqinr",             # extract fasta's name
#     "shiny",              # building interactive web applications in R.
#     "shinyBS",            # adding additional Bootstrap functionality to Shiny applications.
#     "shinybusy",          # Automated (or not) busy indicator for Shiny apps & other progress / notifications tools
#     "shinydisconnect",    # handling disconnections and reconnections in Shiny applications.
#     "shinyFeedback",      # providing user feedback and notifications in Shiny applications.
#     "shinycssloaders",    # adding CSS loaders to Shiny applications.
#     "shinyjs",            # easily incorporating JavaScript functions and events in Shiny applications.
#     "shinythemes",        # customizing the appearance of Shiny applications with predefined themes.
#     "shinyvalidate",      # client-side form validation in Shiny applications.
#     "shinyWidgets",       # creating custom UI controls and widgets in Shiny.
#     "snow",               # parallel computing using a simple network of workstations.
#     "tibble",             # creating and manipulating data frames with enhanced features compared to traditional data frames.
#     "tidyverse",          # data manipulation, visualization, and analysis.
#     "tictoc",             # measuring the time taken by R code execution.
#     "shinyvalidate",      # shinyvalidate adds input validation capabilities to Shiny.
#     "zip"                 # reading, writing, and manipulating ZIP archives in R.
# )

# #   # verify required packages installed or not. If some package
# #   # is missing, it will be installed automatically
# #   package.check <- lapply(pacotes, FUN = function(x) {
# #     if (!require(x, character.only = TRUE)) {
# #       print(x)
# #       install.packages(x, dependencies = TRUE)
# #     }
# #   })

#   # 循环引入包
#   lapply(pacotes, function(pkg) {
#     requireNamespace(pkg, quietly = TRUE)
#     library(pkg, character.only = TRUE)
#   })

  # 显式地调用packages是因为renv的package管理需要识别library
  library(jsonlite)
  library(emayili)
  library(bslib)
  library(data.table)
  library(DT)
  library(dplyr)
  library(fullPage)
  library(future)
  library(ggasym)
  library(ggpubr)
  library(glue)
  library(kableExtra)
  library(openxlsx)
  library(promises)
  library(purrr)
  library(reshape2)
  library(rintrojs)
  library(rjson)
  library(rtracklayer)
  library(scales)
  library(seqinr)
  library(shiny)
  library(shinyBS)
  library(shinybusy)
  library(shinydisconnect)
  library(shinyFeedback)
  library(shinycssloaders)
  library(shinyjs)
  library(shinythemes)
  library(shinyvalidate)
  library(shinyWidgets)
  library(snow)
  library(tibble)
  library(tidyverse)
  library(tictoc)
  library(shinyvalidate)
  library(zip)

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

NCPU <- readLines("data/cpu_configuration.txt")[1]

# auto detect the pre-computed motif-DB data: when new species or motif database comes, no need to change code.
species <- list.dirs("./data/indexing", recursive=F) %>%
  sapply(function(i) {
    str <- stringr::str_split_1(i, "/")[4] # %>% tolower() #%>% gsub("(^|\\s)([a-z])", "\\1\\U\\2", ., perl = TRUE) # capitablize first letter
    return(str)
  })
# > species
# ./data/indexing/Arabidopsis_thaliana
#                 "Arabidopsis_thaliana"
# ./data/indexing/Brachypodium_distachyon
#               "Brachypodium_distachyon"
#         ./data/indexing/Brassica_napus
#                       "Brassica_napus"

MOTIF_DB <- lapply(species, function(speci) {

  motif_dbs <- file.path("data/indexing", speci) %>%
    list.dirs(recursive = FALSE, full.names = F)
  list_names <- gsub("_", " ", motif_dbs) #%>% tools::toTitleCase()
  result <- list()
  for (i in seq(length(motif_dbs))) {
    result[[ list_names[i] ]] <- file.path("data/indexing", speci , motif_dbs[i])
  }
  return(result)
}) %>% setNames(unname(species))
# > MOTIF_DB
# $Arabidopsis_thaliana
# $Arabidopsis_thaliana$`CIS-BP2`
# [1] "data/indexing/Arabidopsis_thaliana/CIS-BP2"

# $Arabidopsis_thaliana$`Franco-Zorrilla et al 2014`
# [1] "data/indexing/Arabidopsis_thaliana/Franco-Zorrilla_et_al_2014"

# $Arabidopsis_thaliana$`Jaspar plants non redundant 2022`
# [1] "data/indexing/Arabidopsis_thaliana/Jaspar_plants_non_redundant_2022"

# $Arabidopsis_thaliana$`Plant Cistrome DB`
# [1] "data/indexing/Arabidopsis_thaliana/Plant_Cistrome_DB"

# $Arabidopsis_thaliana$PlantTFDB
# [1] "data/indexing/Arabidopsis_thaliana/PlantTFDB"

SPECIES_LIST <- list()

for (speci in species) {
  temp <- gsub("_", " ", speci)
  SPECIES_LIST[[temp]] <- speci
}
SPECIES_LIST <- list(species = SPECIES_LIST) # to show nothing first of fileInput box
# > SPECIES_LIST
# $species
# $species$`Arabidopsis thaliana`
# [1] "Arabidopsis_thaliana"

# $species$`Brachypodium distachyon`
# [1] "Brachypodium_distachyon"

# $species$`Brassica napus`
# [1] "Brassica_napus"

# $species$`Glycine max`
# [1] "Glycine_max"

MOTF_DB_META <- rjson::fromJSON(file = "data/motif_db_meta.json")
# > MOTF_DB_META
# $Arabidopsis_thaliana
# $Arabidopsis_thaliana$genome_name
# [1] "Arabidopsis_thaliana.TAIR10.dna.toplevel.fa"

# $Arabidopsis_thaliana$annotation_name
# [1] "Arabidopsis_thaliana.TAIR10.56.gff3"

# $Arabidopsis_thaliana$genome_link
