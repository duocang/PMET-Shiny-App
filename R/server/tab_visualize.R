# Download example PMET result -----------------------------------------------
output$demo_pmet_result_download <- downloadHandler(
  filename = function() {
    "example_pmet_result.txt"
  },
  content = function(file) {
    data <- data.table::fread("data/demo_pmet_analysis/example_pmet_result.txt")
    write.table(data, file, quote = FALSE, sep = "\t")
  }
)


# feedback for file uploaded
showFeedbackDanger(inputId = "pmet_result_file", text = "No PMET result found")
file.status <- reactiveVal("NO")
observeEvent(input$pmet_result_file, {
  req(input$pmet_result_file)
  # remove all UI when loading new data
  removeUI(selector = "#heatmap_module_content")
  removeUI(selector = "#heatmaply.ui")
  # remove all UI when loading new data
  removeUI(selector = "#heatmap_module_content")
  removeUI(selector = "#heatmaply.ui")
  # remove all UI when loading new data
  removeUI(selector = "#heatmap_module_content")
  removeUI(selector = "#heatmaply.ui")

  file.status("NO")
  # indicators for PMET result file uploaded
  switch(ValidatePmetResult(input$pmet_result_file$datapath),
    "NO_FILE" = {
      hideFeedback(inputId = "pmet_result_file")
      showFeedbackDanger(inputId = "pmet_result_file", text = "Upload a txt file of PMET result")
    },
    "NO_CONTENT" = {
      hideFeedback(inputId = "pmet_result_file")
      showFeedbackDanger(inputId = "pmet_result_file", text = "Empty file")
    },
    "WRONG_HEADER" = {
      # print("Wrong format of uploaded file")
      hideFeedback(inputId = "pmet_result_file")
      showFeedbackDanger(inputId = "pmet_result_file", text = "Wrong format of uploaded file content")
    },
    "OK" = {
      hideFeedback(inputId = "pmet_result_file")
      showFeedbackSuccess(inputId = "pmet_result_file")
      file.status("OK")
    }
  )
}, ignoreInit = T)

# feedback for other parameters
observe({
  if (is.na(input$topn_pair) | is.null(input$topn_pair) | input$topn_pair <= 0) {
    hideFeedback(inputId = "topn_pair")
    showFeedbackDanger("topn_pair", "Please enter a positive integer")
  } else {
    hideFeedback("topn_pair")
  }

  if (is.na(input$p_adj) | is.null(input$p_adj) | input$p_adj <= 0 | input$p_adj > 1) {
    hideFeedback(inputId = "p_adj")
    showFeedbackDanger("p_adj", "Please enter a valid p-value")
  } else {
    hideFeedback("p_adj")
  }
  req(input$topn_pair, input$p_adj)

  validate(need(!is.na(input$p_adj) & !is.null(input$p_adj), "Please enter a positive integer."))
  # validate(need(!is.na(input$p_adj), "Please enter a positive number."))
  validate(need(input$p_adj >= 0, "Please enter a positive integer."))
  validate(need(is.integer(as.integer(input$p_adj)), "Please enter a positive integer."))

  validate(need(!is.na(input$topn_pair) & !is.null(input$topn_pair), "Please enter a positive integer."))
  # validate(need(!is.na(input$topn_pair), "Please enter a positive integer."))
  validate(need(input$topn_pair >= 0, "Please enter a positive integer."))
  validate(need(is.integer(as.integer(input$topn_pair)), "Please enter a positive integer."))
})


# reactive raw PMET result ---------------------------------------------------------
pmet.result.raw <- reactive({
  req(input$pmet_result_file)
  req(file.status() == "OK", "PMET result uploaded successfully!")

  withProgress(message = "Reading data", value = 0, {

    incProgress(0.5, detail = "Read PMET result ....")

    tic("Read PMET result ....")
    suppressMessages({
      pmet.result <- data.table::fread(input$pmet_result_file$datapath,
        select = c(
          "Cluster", "Motif 1", "Motif 2",
          "Number of genes in cluster with both motifs",
          "Adjusted p-value (BH)", "Genes"
        ), verbose = FALSE) %>%
        setNames(c("cluster", "motif1", "motif2", "gene_num", "p_adj", "genes")) %>%
        # dplyr::filter(gene_num > 0) %>%
        arrange(desc(p_adj)) %>%
        mutate(`motif_pair` = paste0(motif1, "^^", motif2))
    })
    incProgress(0.8, detail = "Upload PMET result ....")
    toc()
  }) # end of progress
  return(pmet.result)
}) # end of pmet.result.raw <- reactive({


# filter data and update selection box -----------------------------------------
# 1. check if p-value is to harsh
# 2. filtering data and split pmet result into individual clusters
# 3. update cluster selection box
# this step should (could) be put into the progress of pmet.result.raw().
# But it is put here dedicatly because the sild-effect of input$p_adj and input$topn_pair
# will only trigger data processing itself instead of forcing PMET result uploading agai
#
pmet.result.processed <- reactive({
  req(input$p_adj)
  req(input$topn_pair)
  req(pmet.result.raw())
  # 1.
  # feedback: validate if there will be no data left after filtering
  if (min(pmet.result.raw()$p_adj) > input$p_adj) {
    hideFeedback("p_adj")
    showFeedbackDanger(inputId = "p_adj", text = "No records left, please consider less p.ad restriction")
    validate(need(min(pmet.result.raw()$p_adj) < input$p_adj, "You may need to make less p.adj restriction"))
  } else if (min(pmet.result.raw()$p_adj) == 1) {
    hideFeedback("p_adj")
    showFeedbackDanger(inputId = "p_adj", text = "No meaninful records left after filtering")
    validate(need(min(pmet.result.raw()$p_adj) < 1, "No meaninful records left after filtering"))
  } else {
    hideFeedback("p_adj")
  }
  # 2.
  # filtering data and split pmet result into individual clusters
  withProgress(message = "Filtering data", value = 0.3, {
    incProgress(0.3, detail = "Filtering data....")
    pmet.result.processed <- ProcessPmetResult( pmet_result       = pmet.result.raw(),
                                                p_adj_limt        = input$p_adj,
                                                gene_portion      = 0.05,
                                                topn              = input$topn_pair,
                                                unique_cmbination = input$motif_pair_unique)
    incProgress(0.7)

    # 3.
    # update cluster selection box
    clusters <- pmet.result.processed$motifs %>% names() %>% sort()
    if (input$motif_pair_unique == "TRUE") {
      clusters <- c("Overlap", "All", clusters)
    } else {
      # clusters <- c("All", "Aggregation", clusters)
      clusters <- c("All", "Aggregation", clusters)
    }
    updateSelectInput(session, "method", choices = clusters, selected = input$method)

    incProgress(0.9)
    return(pmet.result.processed)
  }) # withProgress
})


# show buttons of data viewer and plot when data loaded
observe({
  req(pmet.result.processed())
  shinyjs::hide("plot.button")
  shinyjs::hide("download.button")

  if (!is.null(pmet.result.processed())) {
    shinyjs::show("plot.button")
  }
})
# show download button after ploting
observeEvent(input$plot.button, {
  if (input$plot.button > 0) {
    shinyjs::show("placeholder")
    shinyjs::show("download.button")
  }
})

# hide download button every time parameters changed
observe({
  req(input$pmet_result)
  req(input$method)
  req(input$topn_pair)
  req(input$p_adj)

  shinyjs::hide("download.button")
})

# display motif text ---------------------------------------------------------
output$dimension_display <- renderText({

  results <- pmet.result.processed()
  motifs_top_clusters_list <- results$motifs
  if (!is.null(motifs_top_clusters_list)) {
    names(motifs_top_clusters_list) %>%
      lapply(function(clu) {
        genes.pasted <- paste0(motifs_top_clusters_list[[clu]], collapse = ", ", sep = "")

        paste0(clu, ":\n", genes.pasted, "\n\n", sep = "")
      }) %>%
      unlist() %>%
      paste0(collapse = "")
  }
})

# display D3 heat map --------------------------------------------------------
# serve plot data to D3
observeEvent(input$plot.button, {

  motifs <- TopMotifsGenerator(pmet.result.processed()$motifs, by.cluster = FALSE, exclusive.motifs = TRUE)
  num.motifs <- length(motifs)

  # expend ggplot with genes for hover information
  dat_list   <- MotifPairGeneDiagonal(pmet.result.processed()$pmet_result, motifs, counts = "p_adj")
  clusters   <- names(dat_list) %>% sort()

  # Overlap mode: merge all non-NA data into one heat map (different colors for different clusters)
  if (input$method == "Overlap") {
    # merge data into DF[[1]]
    dat <- dat_list[[1]]
    # move all non-NA values from other DFs to DF[[1]]
    for (i in 2:length(dat_list)) {
      indx                 <- which(!is.na(dat_list[[i]][, "cluster"]))
      dat[indx,          ] <- dat_list[[i]][indx, ]
      dat[indx, "cluster"] <- names(dat_list)[i]
    }

    dat[, "motif1"] <- match(dat[, "motif1"], motifs)
    dat[, "motif2"] <- match(dat[, "motif2"], motifs)
  } else if (input$method == "All") {
    for (clu in clusters) {
      dat_list[[clu]][, "motif1"] <- match(dat_list[[clu]][, "motif1"], motifs)
      dat_list[[clu]][, "motif2"] <- match(dat_list[[clu]][, "motif2"], motifs)
    }
    dat <- dat_list
  } else if (input$method %in% clusters) {
    dat <- dat_list[[input$method]]

    dat[, "motif1"] <- match(dat[, "motif1"], motifs)
    dat[, "motif2"] <- match(dat[, "motif2"], motifs)
  } else if (input$method == "Aggregation") {
    # top_motif_list <- pmet.result.processed()$motifs

    # dat <- list()

    # for (clu_motif in clusters) {
    #   top_motifs <- top_motif_list[[clu_motif]]
    #   a <- pmet_result() %>% filter(motif1 %in% top_motifs & motif2 %in% top_motifs)
    #   a$p_adj <- round(-log10(a$p_adj), 2)

    #   for (clu_dat in clusters) {
    #     dat[[paste0(clu_motif, "_", clu_dat)]] <- a %>%
    #       filter(cluster == clu_dat) %>%
    #       arrange(motif1, desc(motif2))
    #   }
    # }
  }

  dat <- list(
    method = input$method,
    data = dat,
    clusters = clusters,
    motifs = motifs
  )

  # json data for D3
  json_pmet <- pretty_json(jsonify::to_json(dat))

  # send json from the session to javascript
  session$sendCustomMessage(type = "jsondata", json_pmet)
  }, ignoreNULL = FALSE, ignoreInit = FALSE)

# This tells shiny to run javascript file and send it to the UI for rendering
output$d3 <- renderUI({
  HTML('<script type="text/javascript", src="heatmap.js">  </script>')
})

# download heat map ---------------------------------------------------------
output$download.button <- downloadHandler(
  filename = function() {
    "heatmap.png"
  },
  content = function(file) {
    results  <- pmet.result.processed()
    clusters <- names(results$pmet_result) %>% sort()

    if (input$method == "Overlap") {

      motifs <- TopMotifsGenerator(pmet.result.processed()$motifs, by.cluster = FALSE, exclusive.motifs = TRUE)
      num.motifs <- length(motifs)

      # expend ggplot with genes for hover information
      dat_list   <- MotifPairGeneDiagonal(pmet.result.processed()$pmet_result, motifs, counts = "p_adj")
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
    } else {
      if (input$method == "All") {
        respective.plot <- FALSE
      } else if (input$method %in% clusters) {
        respective.plot <- TRUE
      }

      p <- MotifPairPlotHomog(results$pmet_result,
                              results$motifs,
                              counts            = "p_adj",
                              exclusive.motifs  = TRUE,
                              by.cluster        = FALSE,
                              show.cluster      = FALSE,
                              legend.title      = "-log10(p.adj)",
                              nrow_             = ceiling(length(clusters)/2),
                              ncol_             = 2,
                              axis.lables       = "",
                              show.axis.text    = TRUE,
                              diff.colors       = TRUE,
                              respective.plot   = respective.plot
      )

      if (input$method %in% clusters) {
        p <- p[[input$method]]
      }
    }

    # set size of saved plot
    if (input$method == "Overlap") {
      wid <- 20
      hei <- 20
    } else {
      if (input$method == "All") {
        wid <- 20
        hei <- 10 * ceiling(length(clusters)/2)
      } else if (input$method %in% clusters) {
        wid <- 20
        hei <- 20
      }
    }
    ggsave(file, p, width = wid, height = hei, dpi = 320, units = "in")
  }
)


# Data table -----------------------------------------------------------------
output$datatable_tabs <- renderUI({
  tagList(
    # downloadButton("download_result", "Download", class = "btn-success"),
    tabsetPanel(ui_data("info1", "Info1"))
  )
})


observeEvent(pmet.result.processed(), {
  result <- lapply(pmet.result.processed()$pmet_result, function(res) {
    res[, c("cluster", "motif1", "motif2", "gene_num", "p_adj")]
  })
  server_data("info1", result)
})

