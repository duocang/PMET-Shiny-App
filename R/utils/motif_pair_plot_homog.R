# plot heatmap of top motifs
# 1. remove shared motifs from each clusters (if exclusive.motifs is true)
# 2. order heatmap (x and y) by groups or alphabetically (if exclusive.motifs and by.cluster are true)
MotifPairPlotHomog <- function( pmet.split       = NULL,
                                motifs.list      = NULL,
                                counts           = "value",
                                exclusive.motifs = TRUE,
                                by.cluster       = FALSE,
                                show.cluster     = FALSE,
                                legend.title     = "Value",
                                nrow_            = 2,
                                ncol_            = 2,
                                show.axis.text   = TRUE,
                                diff.colors      = FALSE,
                                axis.lables      = NULL,
                                respective.plot  = FALSE) {

  motifs.top     <- TopMotifsGenerator(motifs.list, by.cluster, exclusive.motifs)
  plot_data_list <- MotifPairDiagonal(pmet.split, motifs.top, counts)

  # in cases self-defined motifs' names needed
  if (length(axis.lables) > 1) {
    axis_lables_ <- axis.lables
  } else {
    axis_lables_ <- motifs.top
  }

  # ledgent color setting
  colors <- list(
    c("#fac3c3", "#ed3333"),
    c("#a2d5f5", "#11659a"),
    c("#baeed3", "#1a6840"),
    c("#f9cb8b", "#f9a633"),
    c("#bb7fa9", "#8b2671"),
    c("#47484c", "#2f2f35") )[1:length(pmet.split)]
  names(colors) <- names(pmet.split)

  # If parameters "by.cluster" and exclusive.motifs are set to TRUE, motifs
  # from the same cluster will be grouped together.
  # a legend bar will indicate the cluster with different colors
  if (by.cluster & exclusive.motifs) {
    legends <- GGplotLegendGenerator(DiscardSharedItems(motifs.list))
    leg <- legends$vertical
    arm <- legends$horizontal
  }

  # legend range
  a <- do.call(rbind.data.frame, plot_data_list)
  value.min <- min(a$value, na.rm = T)
  value.max <- max(a$value, na.rm = T)

  # create ggplot objects
  p.list <- lapply(names(plot_data_list), function(clu) {
    output <- plot_data_list[[clu]]
    # set different colors for plots of different clusters
    if (diff.colors) {
      color.min <- colors[[clu]][1]
      color.max <- colors[[clu]][2]
    } else {
      color.min <- "#ffe5e5"
      color.max <- "#ff0000"
    }

    p <- ggplot(output, aes(x = motif1, y = motif2, fill = value)) +
      geom_tile(color = "#c4d7d6", lwd = 0) +
      scale_fill_gradient2(
        low      = color.min,
        high     = color.max,
        na.value = "white",
        limits   = c(value.min, value.max),
        name     = legend.title) +
      scale_y_discrete(limits = rev, labels = rev(axis_lables_)) +
      theme_bw() +
      coord_fixed()

    if (show.axis.text) {
      p <- p + theme(
        axis.title.x = element_blank(), axis.title.y = element_blank(),
        axis.line    = element_blank(), axis.text.x  = element_text(angle = 90)
      )
    } else {
      p <- p + theme(
        axis.title.x = element_blank(), axis.title.y = element_blank(),
        axis.text.x  = element_blank(), axis.text.y  = element_blank(),
        axis.line    = element_blank()
      )
    }
    if (by.cluster & show.cluster & exclusive.motifs) {
      p <- p +
        annotation_custom(ggplotGrob(leg), xmin = -0.4, xmax = 0.5, ymin = -2, ymax = Inf) +
        annotation_custom(ggplotGrob(arm), xmin = 0, xmax = Inf, ymin = -0.5, ymax = 0.4)
    }
    return(p)
  }) %>% setNames(names(plot_data_list))
  # create ggplot objects (end)

  if (respective.plot) {
    inch_pre_motif <- 20 / length(motifs.top) * 1.5
    inch_pre_motif <- ifelse(inch_pre_motif > 1, 1, inch_pre_motif)
    font_size <- inch_pre_motif * 22

    for (clu in names(plot_data_list)) {
      p.list[[clu]] <- p.list[[clu]] +
        ggtitle(clu) +
        theme(
          plot.title = element_text(size = 30),
          # legend.title = element_blank(),
          # legend.position = "top",
          axis.line    = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x  = element_text(angle = 90, size = font_size),
          axis.text.y  = element_text(size = font_size),
          legend.text  = element_text(size = 18),
          legend.title = element_text(size = 20)
        )
    }
    return(p.list)
  } else {
    inch_pre_motif <- 10 / length(motifs.top) * 1.3
    inch_pre_motif <- ifelse(inch_pre_motif > 1, 1, inch_pre_motif)
    font_size <- inch_pre_motif * 22

    # add title
    p.list <- lapply(names(plot_data_list), function(clu) {
      p.list[[clu]] +
        ggtitle(clu) +
        theme(
          plot.title = element_text(size = 22),
          # legend.title = element_blank(),
          # legend.position = "top",
          # axis.line = element_blank(),
          # axis.title.x = element_blank(),
          # axis.title.y = element_blank(),
          axis.text.x  = element_text(angle = 90, size = font_size),
          axis.text.y  = element_text(size = font_size),
          legend.text  = element_text(size = 15),
          legend.title = element_text(size = 15)
        )
    })

    p.list <- ggarrange(plotlist = p.list, ncol = ncol_, nrow = nrow_)
    return(p.list)
  }
}