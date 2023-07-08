#' Check if the given value is a valid email address
#'
#' This function checks if the given value is a valid email address.
#'
#' @param x The value to be checked.
#'
#' @return A logical value indicating if the value is a valid email address.
#'
#' @examples
#' ValidEmail("example@example.com")
#'
#' @keywords email address, validation
#' @export
ValidEmail <- function(x) {
  grepl("\\<[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\>", as.character(x), ignore.case = TRUE)
}

#' Generate file paths for PMET analysis
#'
#' This function generates file paths for the PMET analysis based on the input data and selected options.
#'
#' @param input A data object containing user information and selected options.
#' @param mode A character string specifying the mode of analysis ("promoters_pre", "promoters", "intervals").
#'
#' @return A list of file paths and user ID with the following components:
#'   \describe{
#'     \item{genes_path}{Path to the genes file.}
#'     \item{index_dir}{Path to the PMET index file.}
#'     \item{user_id}{Unique user ID.}
#'     \item{pair_dir}{Path to the PMET pair results folder.}
#'   }
#'
#' @examples
#' library(stringr)
#' inputs <- list(email    = "2@gmail.com",
#'               meme = list( path = "xuesong", name = "jaspar.meme"),
#'               genes = list( path = "xuesong", name = "crotex.txt"))
#' mode <- "promoters"
#' PmetPathsGenerator(inputs, mode)
#'
#' $user_id
#' [1] "2-gmail.com_2023Jul05_1331"
#'
#' $genes_path
#' [1] "result/2-gmail.com_2023Jul05_1331/crotex.txt"
#'
#' $index_dir
#' [1] "result/indexing/2-gmail.com_2023Jul05_1331"
#'
#' $pair_dir
#' [1] "result/2-gmail.com_2023Jul05_1331"
#'
#' @keywords PMET analysis, file paths, user ID
#' @export

PmetPathsGenerator <- function(input = NULL, mode = NULL) {

  user_id <- paste0(str_replace(input$email, "@", "-"), "_",
                    format(Sys.time(), "%Y%b%d_%H%M"))

  if (mode == "promoters_pre") {
    index_dir = input$premade
  } else {
    index_dir <- file.path("result/indexing", user_id)
  }
  pair_dir <- file.path("result", user_id)

  genes_path <- file.path(pair_dir, input$genes$name)

  return(list(user_id        = user_id,
              genes_path     = genes_path,
              index_dir = index_dir,
              pair_dir  = pair_dir))
}


#' Move a temporary file to the local directory
#'
#' This function moves a temporary file from a specified temporary folder to the local directory.
#'
#' @param local_dir Character string specifying the path of the local directory.
#' @param temp_folder Character string specifying the name of the temporary folder within the local directory.
#' @param input_file An input file object (e.g., shiny input) with the following components:
#'   \describe{
#'     \item{datapath}{Character string specifying the file path of the input file.}
#'     \item{name}{Character string specifying the new file name.}
#'   }
#'
#' @return Nothing (void function)
#'
#' @examples
#' move_temp_file_to_local(local_dir = "/path/to/local", temp_folder = "temp_folder", input_file)
#'
#' @importFrom shiny file.copy
#'
#' @keywords file manipulation, temporary file, local directory
#' @export
TempToLocal <- function(local_dir, temp_folder, input_file) {

  temp_file     <- input_file$datapath
  new_file_name <- input_file$name

  # create folder
  dir_path <- file.path(local_dir, temp_folder)
  dir.create(dir_path, recursive = TRUE, showWarnings = FALSE)

  # copy file
  # file_path <- file.path(dir_path, new_file_name)
  file.copy(temp_file, dir_path, overwrite = TRUE)
}

#' GenerateColorMapping: Generate a color mapping for numeric values
#'
#' This function generates a color mapping for numeric values based on a specified color palette.
#'
#' @param vals A numeric vector specifying the range of values.
#' @param color A character string specifying the color palette to use (default: "Blues").
#'              Other available options include "Greens", "Oranges", "Purples", "Reds", "Greys",
#'              "YlOrRd", "YlGnBu", and any valid continuous color palette.
#'
#' @return A data frame containing the mapped values and corresponding colors.
#'
#' @examples
#' GenerateColorMapping(vals = c(0, 40), color = "Blues")
#' @export
GenerateColorMapping <- function(vals = c(0, 40), color = "Blues") {
  o <- order(vals, decreasing = FALSE)
  cols <- scales::col_numeric(color, domain = NULL)(vals)
  colz <- setNames(data.frame(vals[o], cols[o]), NULL)
  return(colz)
}
