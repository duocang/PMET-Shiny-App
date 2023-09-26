MotifPairPlotHetero <- function(plot.data = NULL,
                                counts = "p_adj",
                                motifs = NULL,
                                clusters = NULL) {

  colors <- c("#ed3333", "#11659a", "#1a6840", "#f9a633", "#8b2671", "#2f2f35")[seq_along(clusters)]
  names(colors) <- clusters

  inch_pre_motif <- 20 / length(motifs) * 1.5
  font_size <- inch_pre_motif * 22

  p <- plot.data %>%
    ggplot(aes(motif1, motif2, alpha = p_adj, fill = factor(cluster))) +
    geom_tile(color = "white") +
    scale_alpha(range = c(0.3, 1)) +
    # scale_fill_brewer(palette = "Set1", na.value = "white") +
    scale_fill_manual(values = colors, na.value = "white") +
    scale_y_discrete(limits = rev, labels = rev(motifs)) +
    theme_bw() +
    theme(
      legend.title = element_blank(),
      legend.position = "top",
      axis.line = element_blank(),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      axis.text.x = element_text(angle = 90, size = font_size),  # 设置x轴文本字号
      axis.text.y = element_text(size = font_size),              # 设置y轴文本字号
      legend.text = element_text(size = 25)
    ) +
    # guides(fill = "none", alpha = "none") +
    coord_fixed() +
    labs(x = NULL, y = NULL) # , title = "", subtitle = "")
  return(p)
}