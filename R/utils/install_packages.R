


# 先确保 remotes 包已经安装 Make sure the remotes package is installed first
if (!requireNamespace("remotes", quietly = TRUE)) {
  suppressMessages(install.packages("remotes", quiet = TRUE))
}
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  suppressMessages(install.packages("BiocManager", quiet = TRUE))
}

if (!require("pacman")) {
  suppressMessages(install.packages("pacman", quiet = TRUE))
}


options(install.packages.compile.from.source = "always")


installed_packages <- character(0)
failed_packages    <- character(0)

##################################### BiocManager #####################################
check_and_install_bioc <- function(package_name) {

  # 如果包没有安装，尝试用BiocManager来安装 If the package is not installed, try to install it using BiocManager
  if (requireNamespace(package_name, quietly = TRUE)) {
    installed_packages <<- c(installed_packages, package_name)
  } else {
    # 如果包未安装，尝试安装 If the package is not installed, try to install
    tryCatch({
      # 使用BiocManager来安装包 Use BiocManager to install the package
      suppressMessages(BiocManager::install(package_name, ask = FALSE))

      # 检查是否安装成功 Check if installation was successful
      if (requireNamespace(package_name, quietly = TRUE)) {
        installed_packages <<- c(installed_packages, package_name)
      } else {
        failed_packages <<- c(failed_packages, package_name)
        message(paste("Installation of", package_name, "from", repo, "failed."))
      }
    },
    error = function(e) {
      failed_packages <<- c(failed_packages, package_name)
      message(paste("Installation of", package_name, "from", repo, "failed."))
    })
  }
}


repos <- c("rtracklayer")

for (repo in repos) {
  check_and_install_bioc(repo)
}

#####################################   Github    #####################################

# 创建一个函数来检查和安装包 Create a function to check and install packages
check_and_install <- function(repo, ...) {
  package_name <- unlist(strsplit(repo, "/"))[2]

  # 如果包已经安装，直接添加到installed_packages If the package is already installed, add it to installed_packages
  if (requireNamespace(package_name, quietly = TRUE)) {
    installed_packages <<- c(installed_packages, package_name)
  } else {
    # 如果包未安装，尝试安装 If the package is not installed, try to install
    tryCatch({
      suppressMessages(remotes::install_github(repo, ...))

      # 检查是否安装成功 Check if installation was successful
      if (requireNamespace(package_name, quietly = TRUE)) {
        installed_packages <<- c(installed_packages, package_name)
      } else {
        failed_packages <<- c(failed_packages, package_name)
        message(paste("Installation of", package_name, "from", repo, "failed."))
      }
    },
    error = function(e) {
      failed_packages <<- c(failed_packages, package_name)
      message(paste("Installation of", package_name, "from", repo, "failed."))
    })
  }
}

repos <- c("daattali/shinydisconnect",
           "RinteRface/fullPage",
           "dreamRs/shinybusy",
           "merlinoa/shinyFeedback",
           "daattali/shinycssloaders",
           "dreamRs/shinyWidgets",
           "测试/测试1")

for (repo in repos) {
  if (repo == "merlinoa/shinyFeedback") {
    check_and_install(repo, build_vignettes = TRUE)
  } else {
    check_and_install(repo)
  }
}

################################   install.packages    ################################
# Used packages
packages <- c(
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


for (package in packages) {
  if (suppressMessages(require(package, character.only = TRUE))) {
    installed_packages <- c(installed_packages, package)
  } else {
    tryCatch(
      {
        # 使用suppressMessages来禁止install.packages的消息
        suppressMessages(install.packages(package, repos = "https://cran.r-project.org", dependencies = TRUE, type = "source"))

        if (suppressMessages(require(package, character.only = TRUE))) {
          installed_packages <- c(installed_packages, package)
        } else {
          failed_packages <- c(failed_packages, package)
          # 这里的消息仍然会显示
          message(paste("Installation of", package, "failed."))
        }
      },
      error = function(e) {
        failed_packages <- c(failed_packages, package)
        # 这里的消息仍然会显示
        message(paste("Installation of", package, "failed."))
      }
    )
  }
}


############################## Installation summary ############################
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