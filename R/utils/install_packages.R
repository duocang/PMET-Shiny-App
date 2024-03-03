# 设置 CRAN 仓库
r <- getOption("repos")
r["CRAN"] <- "http://cran.us.r-project.org"
options(repos = r)
options(install.packages.compile.from.source = "always")

################################ install basic packages #################################
# 1. remotes and devtools
# 2. BiocManager
# 3. pak
# 定义一个辅助函数来安装包并在失败时终止程序
install_and_check_func <- function(package) {
  if (!requireNamespace(package, quietly = TRUE)) {
    suppressMessages(install.packages(package, quiet = TRUE))
    if (!requireNamespace(package, quietly = TRUE)) {
      stop(paste("Failed to install", package, ". Terminating the program."))
    }
  }
}

# 安装 devtools remotes 和 BiocManager 包
install_and_check_func("devtools")
install_and_check_func("remotes")
install_and_check_func("BiocManager")

# 尝试安装 pak 包
if (!requireNamespace("pak", quietly = TRUE)) {
  suppressMessages(install.packages("pak", quiet = TRUE))
  if (!requireNamespace("pak", quietly = TRUE)) {
    suppressMessages(remotes::install_github("r-lib/pak"))
    if (!requireNamespace("pak", quietly = TRUE)) {
      stop("Failed to install pak from both CRAN and GitHub. Terminating the program.")
    }
  }
}

################################ install function #################################
install_package_func <- function(package_name) {
  # 提取包名：如果包名包含 '/', 提取斜线后的部分
  package_name_to_check <- ifelse(grepl("/", package_name), sub(".*/", "", package_name), package_name)

  # 检查包是否已经安装
  if (requireNamespace(package_name_to_check, quietly = TRUE)) {
    return(TRUE)
  }

  # 定义一个列表，包含尝试安装包的不同函数
  install_functions <- list(
    bio_install      = function() suppressMessages(BiocManager::install(package_name, ask = FALSE)),
    devtools_install = function() suppressMessages(devtools::install_github(package_name, quiet = TRUE)),
    remotes_install  = function() suppressMessages(remotes::install_github(package_name, quiet = TRUE)),
    normal_install   = function() suppressMessages(install.packages(package_name, repos = "https://cran.r-project.org", dependencies = TRUE, type = "source", quiet = TRUE)),
    pak_install      = function() suppressMessages(pak::pak(package_name))
  )

  # 遍历安装函数，尝试安装包
  for (install_func in install_functions) {
    tryCatch({
      install_func()

      # 检查是否安装成功
      if (requireNamespace(package_name, quietly = TRUE)) {
        return(TRUE) # 成功安装，返回 TRUE
      }
    }, error = function(e) {})
  }
  # 所有方法尝试完毕，安装失败
  return(FALSE)
}

################################   installation    ################################
# bio
packages_bio <- c("rtracklayer", "DESeq2", "WGCNA", "GEOqueary", "limma", "edgeR",
                  "GSEABase", "clusterProfiler", "ConsensusClusterPlus", "GSVA",
                  "pheatmap", "scFeatureFilter", "AUCell", "ComplexHeatmap")

# normal packages
packages_normal <- c(
  "future",
  "qs",
  "ddpcr",
  "rlang",
  "pander",
  "pacman",
  "pagoda2",
  "eulerr",
  "Hmisc",
  "pryr",
  "plotly",
  "enrichplot",
  "RcppRoll",
  "msigdbr",
  "xlsxjars",
  "shiny",
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
  "Seurat",
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
  "jsonify",              # JSON data processing and transformation
  "kableExtra",           # creation of nice tables and adding formatting
  "mailR",                # Interface to Apache Commons Email to send emails from R
  "openxlsx",             # reading and writing Excel files
  "promises",             # deferred evaluation and asynchronous programming
  "reshape2",             # data reshaping and transformation
  "rintrojs",             # interactive tour integration
  "rjson",                # Converts R object into JSON objects and vice-versa
  "shiny",                # creation of interactive web applications
  "rJava",
  "shinyBS",              # Bootstrap styling
  "shinybusy",            # Automated (or not) busy indicator for Shiny apps & other progress / notifications tools
  "shinydashboard",       # creation of dashboard-style Shiny apps
  "shinyFeedback",        # user feedback integration
  "shinycssloaders",      # loading animation integration
  "shinyjs",              # JavaScript operations
  "shinythemes",          # theme customization
  "shinyvalidate",        # form validation
  "shinyWidgets",         # creation of interactive widgets
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
           "daattali/shinydisconnect",
           "RinteRface/fullPage",
           "dreamRs/shinybusy",
           "merlinoa/shinyFeedback",
           "daattali/shinycssloaders",
           "dreamRs/shinyWidgets",
           "r-lib/textshaping",
           "r-lib/systemfonts",
           "jhrcook/ggasym",
           "rpremrajGit/mailR",
           "r-lib/textshaping",
           "rstudio/httpuv",
           "r-rust/gifski",
           "jhrcook/ggasym",
           "satijalab/seurat-data",
           "satijalab/azimuth",
           "satijalab/seurat-wrappers",
           "stuart-lab/signac",
           "satijalab/seurat",
           "jhrcook/ggasym",
           "kharchenkolab/pagoda2",
           "NMikolajewicz/scMiko")

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
print(sort(installed_packages))

# Print failed packages
if (length(failed_packages) > 0) {
  cat("\nThe following packages could not be installed:\n")
  print(failed_packages)
} else {
  cat("\nAll packages were successfully installed.\n")
}