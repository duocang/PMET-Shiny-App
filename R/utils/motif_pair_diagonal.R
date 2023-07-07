# 各个cluster的top motifs 组成一个motif_top list，用于生成一张matrix，横轴和纵轴都是motif_top
# matrix中的值则是PMET result单独一个cluster中两两motif (motif pair)之间的基因数或者p值
# 若motif pair在PMET reulst中并不存在，则填充NULL。
# 同时要求结果matrix按左下角和右上角对称。
# 再从wide 数据转为长数据用于ggplot绘图
# Generate a plot data list for motif pairs
#
#' This function takes PMET results split by cluster, a motifs vector, and other optional parameters
#' to generate a plot data list for motif pairs. The resulting list contains data frames of only
#' half diagonal part in a long format, suitable for plotting with ggplot.
#'
#' @param pmet_split: A list of PMET results split by cluster
#' @param motifs.top: A vector of motifs
#' @param counts: The type of counts to be used for the plot ("value" or "p_adj")
#' @returns:
#'   A list of plot data frames in a long format, ready for plotting with ggplot.
#'
#' @examples:
# pmet.results <- list(
#   cluster1 = data.frame(motif1 = c("A", "B", "C"), motif2 = c("B", "C", "D"), value = c(10, 15, 8)),
#   cluster2 = data.frame(motif1 = c("B", "C", "D"), motif2 = c("C", "D", "E"), value = c(5, 12, 9))
# )
# motifs.list <- list(
#   cluster1 = c("A", "B", "C"),
#   cluster2 = c("B", "C", "D", "E")
# )
# plot_data_list <- MotifPairDataGenerator(pmet.results, motifs.list, counts = "value", exclusive.motifs = TRUE)
#
#   $cluster1
#     motif1 motif2 value
#   1      A      A    NA
#   2      D      A    NA
#   3      E      A    NA
#   4      A      D    NA
#   5      D      D    NA
#   6      E      D    NA
#   7      A      E    NA
#   8      D      E    NA
#   9      E      E    NA
#   $cluster2
#     motif1 motif2 value
#   1      A      A    NA
#   2      D      A    NA
#   3      E      A    NA
#   4      A      D    NA
#   5      D      D    NA
#   6      E      D    NA
#   7      A      E    NA
#   8      D      E     9
#   9      E      E    NA
# @param pmet_split A list of PMET results split by cluster
# @param motifs_list A list of motifs for each cluster
# @param counts The type of counts to be used for the plot ("value" or "p_adj")
# @param exclusive.motifs A logical value indicating whether shared motifs should be discarded
#
# @return A list of plot data frames in a long format, ready for plotting with ggplot
#
# @import reshape2
# @import dplyr
# @import ggasym
# @importFrom magrittr %>% select
# @importFrom magrittr %>% unname
# @importFrom ggasym asymmetrise
# @importFrom scales round
# @importFrom reshape2 dcast
# @importFrom reshape2 melt
# @importFrom reshape2 remove_rownames
# @importFrom ggplot2 factor
# @importFrom gtools GetUpperTriangle
MotifPairDiagonal <- function(pmet.split,
                              motifs.top,
                              counts = "value") {

  all <- CreateMotifCombs(motifs.top)

  plot.data.list <- lapply(pmet.split, function(dat) {
    dat <- dat %>% select(all_of(c("motif1", "motif2", counts)))

    if (counts == "p_adj") {
      dat[, "p_adj"] <- round(-log10(dat[, "p_adj"]), 2)
    }
    # Asymmetric Matrix with motif1 and motif2 in motifs.top
    dat.asymed <- dat %>%
      filter(motif1 %in% motifs.top & motif2 %in% motifs.top) %>%
      ggasym::asymmetrise(motif1, motif2)

    dat.asymed.join <- dplyr::left_join(all[, 1:2], dat.asymed) %>%
      reshape2::dcast(motif1 ~ motif2) %>%
      tibble::remove_rownames() %>%
      tibble::column_to_rownames(var = "motif1")
    # make matrix have specific column names order
    a <- subset(dat.asymed.join, select = motifs.top)
    a$motif1 <- row.names(a)
    a <- a[match(motifs.top, a$motif1), ]
    # get up right half part of matrix
    a[, 1:length(motifs.top)] <- GetUpperTriangle(a[, 1:length(motifs.top)])

    a <- reshape2::melt(a, "motif1", variable.name = "motif2")
    a$motif1 <- factor(a$motif1, levels = motifs.top)
    a$motif2 <- factor(a$motif2, levels = motifs.top)
    return(a)
  })

  return(plot.data.list)
}
# dat.asymed.join.long
# A  D  E
# A NA NA NA
# D NA NA  9     ->
# E NA  9 NA

# A  D  E
# A NA NA NA
# D NA NA  9     ->
# E NA NA NA

#     motif1 motif2 value
#   1      A      A    NA
#   2      D      A    NA
#   3      E      A    NA
#   4      A      D    NA
#   5      D      D    NA
#   6      E      D    NA
#   7      A      E    NA
#   8      D      E     9
#   9      E      E    NA