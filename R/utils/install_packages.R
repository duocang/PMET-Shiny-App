# 设置 CRAN 仓库
r <- getOption("repos")
r["CRAN"] <- "https://cloud.r-project.org/"
options(repos = r)
options(install.packages.compile.from.source = "auto")

Sys.setenv(R_LIBS_USER = "/usr/local/lib/R/library")
.libPaths(new = "/usr/local/lib/R/library")

################################ install basic packages #################################
# 1. remotes and devtools
# 2. BiocManager
# 3. pak
# 定义一个辅助函数来安装包并在失败时终止程序
install_and_check_func <- function(package) {
  result <- suppressWarnings(suppressMessages(capture.output({
    if (!requireNamespace(package, quietly = TRUE)) {
      install.packages(package, quiet = TRUE)
      if (!requireNamespace(package, quietly = TRUE)) {
        return(FALSE)  # 如果再次检查仍然未安装，返回 FALSE
      }
    }
    return(TRUE)  # 如果已安装或安装成功，返回 TRUE
  })))
  return(result)
}

# 安装 devtools remotes 和 BiocManager 包
install_and_check_func("devtools")
install_and_check_func("remotes")
install_and_check_func("BiocManager")

# 尝试安装 pak 包
suppressWarnings(suppressMessages(capture.output(
  if (!requireNamespace("pak", quietly = TRUE)) {
    install.packages("pak", quiet = TRUE)
    if (!requireNamespace("pak", quietly = TRUE)) {
      remotes::install_github("r-lib/pak", quiet = TRUE)
      if (!requireNamespace("pak", quietly = TRUE)) {
        stop("Failed to install pak from both CRAN and GitHub. Terminating the program.")
      }
    }
  }
)))

################################ install function #################################
install_package_func <- function(package_name) {
  package_name_to_check <- ifelse(grepl("/", package_name), sub(".*/", "", package_name), package_name)
  if (requireNamespace(package_name_to_check, quietly = TRUE)) {
    return(TRUE)
  }

  install_functions <- list(
    bio_install      = function() BiocManager::install(package_name, ask = FALSE, quietly = TRUE),
    devtools_install = function() devtools::install_github(package_name, quiet = TRUE),
    remotes_install  = function() remotes::install_github(package_name, quiet = TRUE),
    normal_install   = function() install.packages(package_name, repos = "https://cran.r-project.org", dependencies = TRUE, type = "source", quiet = TRUE),
    pak_install      = function() pak::pak(package_name, ask = FALSE)
  )

  for (install_func in install_functions) {
    suppressWarnings(suppressMessages(capture.output(
      tryCatch({
        install_func()
        if (requireNamespace(package_name, quietly = TRUE)) {
          return(TRUE)
        }
      }, error = function(e) {})
    )))
  }
  return(FALSE)
}

################################   installation    ################################
# bio
# packages_bio <- c("rtracklayer", "DESeq2", "WGCNA", "GEOqueary", "limma", "edgeR",
#                   "GSEABase", "clusterProfiler", "ConsensusClusterPlus", "GSVA",
#                   "pheatmap", "scFeatureFilter", "AUCell", "ComplexHeatmap")
packages_bio <- c("rtracklayer")

# normal packages
packages_normal <- c(
  "jsonlite",
  "jsonify",
  "ddpcr",
  "rlang",
  "pander",
  "pacman",
  "eulerr",
  "Hmisc",
  "pryr",
  "plotly",
  "enrichplot",
  "RcppRoll",
  "msigdbr",
  "xlsxjars",
  "svglite",
  "pak",
  "devtools",
  "av",
  "magick",
  "systemfonts",
  "textshaping",
  "rsvg",
  "gapminder",
  "qpdf",
  "tesseract",
  "pdftools",
  "ragg",
  "stringr",
  "usethis",
  "httpuv",
  "rJava",
  "bslib",                # Bootstrap themes and styles
  "data.table",           # efficient handling of large datasets
  "DT",                   # interactive data tables
  "dplyr",                # Provides powerful data manipulation and operations
  "emayili",              # Send email
  "future",               # support for parallel and asynchronous programming
  "ggasym",               # symmetric scatter plots and bubble charts
  "ggplot2",              # creation of beautiful graphics
  "ggpubr",               # graph publication-ready formatting and annotations
  "glue",                 # string interpolation and formatting
  "kableExtra",           # creation of nice tables and adding formatting
  "openxlsx",             # reading and writing Excel files
  "promises",             # deferred evaluation and asynchronous programming
  "reshape2",             # data reshaping and transformation
  "rintrojs",             # interactive tour integration
  "shiny",                # creation of interactive web applications
  "shinyBS",              # Bootstrap styling
  "shinybusy",            # Automated (or not) busy indicator for Shiny apps & other progress / notifications tools
  "shinyFeedback",        # user feedback integration
  "shinycssloaders",      # loading animation integration
  "shinyjs",              # JavaScript operations
  "shinythemes",          # theme customization
  "shinyvalidate",        # form validation
  "shinyWidgets",         # creation of interactive widgets
  "shinydisconnect",
  "shinydashboard",
  "scales",               # data scaling and transformation
  "seqinr",                # extract fasta's name
  "tibble",               # extended data frames
  "tidyverse",            # a collection of R packages for data manipulation and visualization
  "tictoc",               # simple and accurate timers
  "xfun",                 # Xie Yihui's functions
  "zip"                   # creation and extraction of ZIP files
)
# pak packages
pak_packages <- c("r-lib/ragg", "r-lib/usethis", "r-lib/rlang")
# github
packages_github <- c(
    "jeroen/jsonlite",
    "kassambara/ggpubr",
    "SymbolixAU/jsonify",
    "daattali/shinydisconnect",
    "datawookie/emayili",
    "RinteRface/fullPage",
    "dreamRs/shinybusy",
    "merlinoa/shinyFeedback",
    "daattali/shinycssloaders",
    "dreamRs/shinyWidgets",
    "r-lib/textshaping",
    "r-lib/systemfonts",
    "rstudio/httpuv",
    "r-rust/gifski",
    "jhrcook/ggasym")

installed_packages <- character(0)
failed_packages    <- character(0)

packages <- c(packages_bio, packages_github, pak_packages, packages_normal)

for (package in packages) {
  flag <- install_package_func (package)
  if (flag) {
      installed_packages <- c(installed_packages, package)
  } else {
      failed_packages <- c(failed_packages, package)
  }
}

for (package in packages) {
  flag <- install_package_func (package)
  if (flag) {
      installed_packages <- c(installed_packages, package)
  } else {
      failed_packages <- c(failed_packages, package)
  }
}

for (package in packages) {
  flag <- install_package_func (package)
  if (flag) {
      installed_packages <- c(installed_packages, package)
  } else {
      failed_packages <- c(failed_packages, package)
  }
}
##############################       summary         ############################
# Print installed packages
cat("The installed packages are as follows:\n")
print(sort(unique(installed_packages)))

# Print failed packages
if (length(failed_packages) > 0) {
  cat("\nThe following packages could not be installed:\n")
  print(unique(failed_packages))
} else {
  cat("\nAll packages were successfully installed.\n")
}