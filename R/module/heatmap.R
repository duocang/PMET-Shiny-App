heatmapUI <- function(id, height = 800, width = 850) {
  div(
    id = "heatmap_module_content",
    column(8, plotlyOutput(NS(id, "plot"), height = height, width = width))
  )
}

headmapServer <- function(id, data, title = NA, ncol = 2, show_legend = "No Legend",
                          tickangle.x = 45,
                          tickangle.y = -45,
                          yshift = 40,
                          axis.size = 8,
                          val_max = 0,
                          val_min = 1,
                          shareX = FALSE,
                          shareY = FALSE) {
  moduleServer(id, function(input, output, session) {
    p <- reactive({
      zmax <- val_max()
      zmin <- ifelse(val_min() == 0, 1, val_min())

      dat <- isolate({
        data()
      })
      plot.cout <- length(dat)

      p.list <- lapply(names(dat), function(category) {
        dat.cat <- dat[[category]]
        # dat.cat$gene_num <- as.numeric(dat.cat$gene_num)
        dat.cat$p_adj <- as.numeric(dat.cat$p_adj)

        dat.cat$`p_adj_genes` <- paste0(dat.cat$`p_adj`, "<br>", "Genes: ", dat.cat$genes)

        p <- plot_ly(
          data = dat.cat,
          x = ~motif1,
          y = ~motif2,
          # z = ~gene_num,
          z = ~p_adj,
          type = "heatmap",
          zauto = FALSE,
          zmin = 1,
          zmax = zmax,
          colorscale = colors.plotly.func(),
          text = ~p_adj_genes,
          hovertemplate = paste0(
            "Motif X:          %{x}<br>",
            "Motif Y:          %{y}<br>",
            "Value:            %{z}<br>",
            "-log10(p_adj):    %{text}<br>",
            "<extra></extra>"
          )
        ) %>%
          add_annotations(
            text = category,
            x = 0.01,
            y = 0.95,
            yref = "paper",
            xref = "paper",
            xanchor = "left",
            yanchor = "top",
            yshift = yshift,
            showarrow = FALSE,
            font = list(size = 15)
          )

        if (show_legend != category) {
          p <- p %>% hide_colorbar()
        }

        # p %>% layout(xaxis = list(tickfont = list(size = axis.size), tickangle = tickangle.x),
        #              yaxis = list(tickfont = list(size = axis.size), tickangle = tickangle.y))
        p
      })

      widths <- rep(round(1 / length(dat), 2), length(dat))
      plotly::subplot(plotlist = p.list, nrows = 1, margin = 0.008, widths = widths, shareY = TRUE)
    })

    output$plot <- renderPlotly(p())
  })
}
