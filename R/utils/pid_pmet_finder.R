library(dplyr)
library(stringr)
# 执行命令并提取符合条件的 Command 信息
# Execute a command and extract Command information that matches a given pattern
# Arguments:
#   pattern: The pattern to match in the Command information
# Returns:
#   A character vector containing the matched Command information
pid_pmet_finder_func <- function(pattern) {
  # 使用系统命令和管道获取所有 Command 信息
	# Execute a system command with a pipe to retrieve all Command information
  command <- paste("ps -e -o pid,command", sep = "")
  output <- system(command, intern = TRUE)

  # 使用正则表达式匹配 Command 信息
	# Use regular expressions to match Command information
	# matched_commands example:
	# 323 PMETdev/scripts/pmetParallel_linux
	# 	-d data/PMETindex/at/at-jaspar_2018
	# 	-g result/tt_gmail.com_at_at-jaspar_2018_2023Jun15_0015/genes_used_PMET.txt
	# 	-i 24
	# 	-p promoter_lengths.txt
	# 	-b binomial_thresholds.txt
	#		-c IC.txt -f fimohits -t 8
	# 	-o /Users/nuioi/projects/pmet_shiny_nginx/result/TT_gmail.com_at_at-jaspar_2018_2023Jun15_0015
  matched_commands <- grep("(fimo|pmetParallel|pmetindex|PMET|PMETindex|PMETdev)", output, value = TRUE) %>%
		grep(pattern, ., value = TRUE)

	if (identical(matched_commands, character(0))) {
		return(0)
	}

	pids <- lapply(matched_commands, function (i) {
			pid <- str_extract(i, "^\\s*\\d+") %>% as.numeric()
    }) %>% unlist()

  return(pids)
}


# # Extract Command information containing "pmetParallel" in R
# # 提取 Command 信息中含有 "pmetParallel" 的命令
# pattern <- "bidopsis_thaliana-jaspar_plants_non_redundant_2018_2"
# matched_commands <- pid.pmet.finder.func(pattern)

# # 打印符合条件的 Command 信息
# print(matched_commands)
