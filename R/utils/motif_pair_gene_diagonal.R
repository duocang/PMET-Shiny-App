# motifs_list <- list(
#   `me-G1` = c("SRS1_CISBP2", "ASR1_JASPAR2022", "STY1_ARABD_PBM"),
#   `me-G2` = c("AT5G05550_COLAMP_ARABD_DAP"),
#   `me-M` = c("MYB3R4_JASPAR2022", "AGL6_COL_ARABD_DAP", "SOL1_COL_ARABD_DAP"),
#   `me-S` = c("DEL1_COLAMP_ARABD_DAP", "GATA1_COLAMP_ARABD_DAP", "GATA26_CISBP2")
# )
# GGplotLegendGenerator(motifs_list)

GGplotLegendGenerator <- function(motifs.list) {
  motifs.top <- motifs.list %>% unlist() %>% unname()

  samp.id <- 1:length(motifs.top)
  group <- names(motifs.list) %>%
    lapply(function(clu) { rep(clu, length(motifs.list[[clu]])) }) %>% unlist()

  # Build a legend "bar"
  groups <- data.frame(samp.id = samp.id, group = group)
  leg <- ggplot(groups, aes(y = samp.id, x = 0)) +
    geom_point(aes(color = group), shape = 15, size = 8, show.legend = F) +
    theme_classic() +
    theme(
      axis.title = element_blank(), axis.line = element_blank(),
      axis.text = element_blank(), axis.ticks = element_blank(),
      plot.margin = unit(c(0, 0, 0, 0), "cm")
    )

  arm <- ggplot(groups, aes(y = rev(samp.id), x = 0)) +
    geom_point(aes(color = group), shape = 15, size = 8, show.legend = F) +
    theme_classic() +
    theme(
      axis.title = element_blank(), axis.line = element_blank(),
      axis.text = element_blank(), axis.ticks = element_blank(),
      plot.margin = unit(c(0, 0, 0, 0), "cm")) +
    coord_flip()

  return(list(vertical = leg, horizontal = arm))
}


# 从每个cluster的top PMET result选出top motifs (按pvalue或者基因数量)
# 去除cluster之间重叠的top motifs, 用得到的所有motifs创建一个matrix, x和y轴
# 都是top motifs. 而值则有每个cluster下的PMET result出，pvalue或者基因数量填充。
# matrix变化为"motif1", "motif2", counts这样的三列数据，与原来pmet result 相交
# 获取一个motif pair对应的基因列表
#' Reshape PMET Data for Motif Pairs
#'
#' This function reshapes the PMET data for motif pairs, selecting the top motifs from each cluster
#' and removing overlapping motifs between clusters. The resulting data is transformed into a matrix,
#' where both the x and y axes represent the top motifs, and the values represent the PMET results
#' (p-values or gene counts) for each motif pair in each cluster. The resulting matrix is then
#' reshaped into a data frame with three columns: "motif1", "motif2", and the specified counts metric.
#' Additionally, the function joins the reshaped data with the original PMET result to obtain gene information
#' for each motif pair.
#'
#' @param pmet.split A list of PMET data split by clusters.
#' @param motifs A vector of motifs.
#' @param counts The metric to be used for counts ("p_adj" for p-values or "gene_num" for gene counts).
#'
#' @return A list of reshaped data frames, one for each cluster.
#'
#' @examples
#' pmet.split <- list(cluster1 = data.frame(motif1 = c("aa", "bb"),
#'                                          motif2 = c("bb", "cc"),
#'                                          p_adj = c(0.05, 0.01),
#'                                          cluster = c(1, 1),
#'                                          genes = c("gene1; gene2", "gene2; gene3"),
#'                                          gene_num = c(1,2),
#'                                          motif_pair = c("aa^^bb", "bb^^cc")),
#'                    cluster2 = data.frame(motif1 = c("motif21", "motif31"),
#'                                          motif2 = c("motif31", "motif41"),
#'                                          p_adj = c(0.02, 0.001),
#'                                          gene_num = c(11,21),
#'                                          cluster = c(2, 2),
#'                                          motif_pair = c("motif21^^motif31", "motif31^^motif41"),
#'                                          genes = c("gene2; gene3", "gene3; gene4")))
#' motifs.list <- list(cluster1 = c("aa", "bb", "cc" "motif21", "motif31", "motif41")
#' reshaped_data <- MotifPairGeneDiagonal(pmet.split, motifs.list, counts = "p_adj")
#'
#' @importFrom dplyr %>%
#' @importFrom dplyr pull
#' @importFrom dplyr left_join
#' @importFrom dplyr arrange
#' @importFrom dplyr desc
#' @importFrom dplyr filter
#' @importFrom dplyr cbind
#' @importFrom dplyr mutate
#' @importFrom dplyr arrange
#' @importFrom dplyr setNames
#' @importFrom dplyr suppressMessages
#' @importFrom . TopMotifsGenerator
#' @importFrom . MotifPairDiagonal
#'
#' @export
MotifPairGeneDiagonal <- function(pmet.split = NULL,
                                  motifs     = NULL,
                                  counts     = "p_adj") {
  suppressMessages({
    # motifs.top <- TopMotifsGenerator(motifs.list, by.cluster = FALSE, exclusive.motifs = TRUE)

    # pmet data for each cluster has been shaped in ggplot2 (long) format, but no gene info
    dat.diag <- MotifPairDiagonal(pmet.split, motifs, counts = counts)

    # join with original pmet result to gain gene info
    dat.diag.gene <- lapply(names(pmet.split), function(clu) {
      dat <- dat.diag[[clu]]

      names(dat) <- c("motif1", "motif2", counts)
      # left joined with original pmet result by motif-pair (empty gene column gained)
      dat <- dat %>%
        cbind(motif_pair = paste0(.$motif1, "^^", .$motif2)) %>%
        left_join(pmet.split[[clu]])

      # motif_pairs from non-empty rows from each ggplot2-format result (with gene
      # column gained from above-mentioned join)
      motif_pairs <- dat %>% filter(!is.na(!!counts)) %>% pull(motif_pair)

      pmet.non.empty <- pmet.split[[clu]] %>% filter(motif_pair %in% motif_pairs)

      for (i in 1:length(motif_pairs)) {
        indx <- which(dat$motif_pair == pmet.non.empty$motif_pair[i])

        if (counts == "p_adj") {
          dat[indx, c("cluster", "gene_num", "genes")] <- pmet.non.empty[i, c("cluster", "gene_num", "genes")]
        } else if (counts == "gene_num") {
          dat[indx, c("cluster", "p_adj", "genes")] <- pmet.non.empty[i, c("cluster", "p_adj", "genes")]
        }
      }

      # # add line breakers into gene string
      # dat$genes.orgi <- dat$genes
      #
      # dat$genes <- sapply(dat$genes, function(x){
      #   stringr::str_replace_all(x, ";", " ") %>% trimws() %>% strwrap(width = 40) %>%
      #     paste(collapse = ";<br>") %>%
      #     stringr::str_replace_all(" ", ";") %>%
      #     stringr::str_replace_all("<br>", "<br>             ")})

      dat <- dat %>% arrange(motif1, desc(motif2))
      return(dat)
    }) %>% setNames(names(pmet.split))
  }) # suppressMessages

  return(dat.diag.gene)
}