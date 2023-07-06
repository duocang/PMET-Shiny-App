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
source("R/utils/motif_pair_plot_hetero.R")
source("R/utils/motif_pair_diagonal.R")
source("R/utils/motif_pair_gene_diagonal.R")


p_adj = 0.05
topn_pair = 5
motif_pair_unique = TRUE
counts = "p_adj"
by.cluster       = FALSE
exclusive.motifs = TRUE

pmet.file <- "data/demo_pmet_analysis/example_pmet_result.txt"

pmet.result.raw  <- pmet.result <- data.table::fread(pmet.file,
                                                     select = c(
                                                       "Cluster", "Motif 1", "Motif 2",
                                                       "Number of genes in cluster with both motifs",
                                                       "Adjusted p-value (BH)", "Genes"
                                                     ), verbose = FALSE) %>%
  setNames(c("cluster", "motif1", "motif2", "gene_num", "p_adj", "genes")) %>%
  # dplyr::filter(gene_num > 0) %>%
  arrange(desc(p_adj)) %>%
  mutate(`motif_pair` = paste0(motif1, "^^", motif2))


pmet.result.processed <- ProcessPmetResult( pmet_result       = pmet.result.raw,
                                            p_adj_limt        = p_adj,
                                            gene_portion      = 0.05,
                                            topn              = topn_pair,
                                            unique_cmbination = motif_pair_unique)
#
# > length(unlist(pmet.result.processed$motifs))
# [1] 14
# > length(unique(unlist(pmet.result.processed$motifs)))
# [1] 13
pmet.result <- pmet.result.processed$pmet_result
motifs.list <- pmet.result.processed$motifs

motifs <- TopMotifsGenerator(motifs.list, by.cluster = FALSE, exclusive.motifs = TRUE)

motif.pair.diagonal      <- MotifPairDiagonal(pmet.result, motifs, counts)

dat_list <- MotifPairGeneDiagonal(pmet.result, motifs, counts)

clusters   <- names(dat_list) %>% sort()


# merge data into DF[[1]]
dat <- dat_list[[1]]
# move all non-NA values from other DFs to DF[[1]]
for (i in 2:length(dat_list)) {
  indx                 <- which(!is.na(dat_list[[i]][, "cluster"]))
  dat[indx,          ] <- dat_list[[i]][indx, ]
  dat[indx, "cluster"] <- names(dat_list)[i]
}

p <- MotifPairPlotHetero(dat,  "p_adj", motifs, clusters)

ggsave("R/test/heatmap.png", p, width = 16, height = 14, dpi = 320, units = "in")
