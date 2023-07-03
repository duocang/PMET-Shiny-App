suppressPackageStartupMessages({
  library(mailR)
  library(stringr)
  library(dplyr)

  source("R/utils/send_mail.R")
})

# Monitor the creation of new folders in the specified directory
# and send notifications when result done
# Arguments:
#   folder_path: The path of the folder to monitor
WatchFolder <- function(folder_path) {
  previous_folders <- list.files(folder_path)

  while (TRUE) {
    current_folders <- list.files(folder_path)

    # Check if there are new folders created
    new_items <- setdiff(current_folders, previous_folders)
    zip_files <- new_items[base::endsWith(new_items, ".zip")]
    num_zip_files <- length(zip_files)

    if (num_zip_files > 0) {
      for(zip_file in zip_files) {
        # Send an email notification
        recipient <- stringr::str_split(zip_file, "_")[[1]][1:2] %>% paste(collapse = "@")
        result_link <- paste0("https://bar.utoronto.ca/pmet_result/", zip_file)

        Sys.sleep(5)
        # send the result link via email
        SendResultMail(recipient, result_link)
        print(paste0("Sned result to user: ", zip_file))
        Sys.sleep(5)
        bash_rm <- paste0("rm -rf ", "result/", str_remove(zip_file, ".zip"))
        # system(bash_rm)
      }
    }
    # else {
    #   print("No result generated yet")
    # }

    # Update the list of known folders
    previous_folders <- current_folders
    # Sleep for a specified interval (e.g., check every minute)
    Sys.sleep(60)
  }
}

# Specify the path of the folder to monitor
folder_path <- "result"

# Start monitoring the folder
WatchFolder(folder_path)
