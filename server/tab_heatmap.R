# workthrough heat map--------------------------------------------------------
heatmap_steps <- reactive({
  elements <- c(
    "#pmet_result_div",
    "#motif_pair_unique_div",
    "#method_div",
    "#topn_pair_div",
    "#p_adj_div"
  )

  intors <- c("a", "b", "c", "d", "e")
  data.frame(element = elements, intro = intors)
})


# Download example PMET result -----------------------------------------------
output$example_pmet_result_file_download <- downloadHandler(
  filename = function() {
    "example_pmet_result.txt"
  },
  content = function(file) {
    data <- data.table::fread("data/example_pmet_result.txt")
    write.table(data, file, quote = FALSE, sep = "\t")
  }
)

# observeEvent(input$demo_pmet_result_link, {
#   print("demo_genes_file_link")

#   dat <- data.table::fread("data/example_pmet_result.txt")
#   Sys.sleep(0.5)
#   showModal(modalDialog(
#     title = "Example PMET result:",
#     DT::renderDataTable({dat}, options = list(scrollX=TRUE, scrollCollapse=TRUE)),
#     footer = tagList(
#       # tags$span(style="color:red;font-weight:bold;float:left;","No column names needed"),
#       downloadButton("demo_pmet_result_down_btn", "Download"),
#       modalButton("Cancel"))
#   )) # end of showModal
# })

# # Download demo PMET result when button clicked ---------------------------------------
# output$demo_pmet_result_down_btn <- downloadHandler(
#   filename = function() {
#     "example_pmet_result.txt"
#   },
#   content = function(file) {
#     write.table(data.table::fread("data/example_pmet_result.txt"), file, quote = FALSE, sep = "\t")
#   }
# ) # downLoadHandler end



# feedback for no file uploaded when page first opened
showFeedbackDanger(inputId = "pmet_result", text = "No PMET result found")

# upload PMET result ---------------------------------------------------------
pmet_result <- reactive({
  withProgress(message = "Reading data", value = 0, {
    # remove all UI when loading new data
    removeUI(selector = "#heatmap_module_content")
    removeUI(selector = "#heatmaply.ui")
    # remove all UI when loading new data
    removeUI(selector = "#heatmap_module_content")
    removeUI(selector = "#heatmaply.ui")
    # remove all UI when loading new data
    removeUI(selector = "#heatmap_module_content")
    removeUI(selector = "#heatmaply.ui")

    incProgress(0.2)

    # indicators for file uploaded
    if (!is.null(input$pmet_result)) {
      hideFeedback("pmet_result")
      showFeedbackSuccess(inputId = "pmet_result")
    } else {
      showFeedbackDanger(inputId = "pmet_result", text = "No PMET result found")
    }

    file <- input$pmet_result
    ext <- tools::file_ext(file$datapath)
    req(file)
    validate(need(ext == "txt", "Please upload a txt file"))

    incProgress(0.3)

    dat_first_row <- tryCatch(
      {
        readLines(input$pmet_result$datapath, n = 1)
      },
      error = function(e) {
        message("Error: ", e$message)
        NULL
      }
    ) # end of tryCatch

    print(dat_first_row) # print)

    pmet_result_rowname <- "Cluster\tMotif 1\tMotif 2\tNumber of genes in cluster with both motifs\tTotal number of genes with both motifs\tNumber of genes in cluster\tRaw p-value\tAdjusted p-value (BH)\tAdjusted p-value (Bonf)\tAdjusted p-value (Global Bonf)\tGenes"

    print(identical(dat_first_row, pmet_result_rowname))

    if (identical(dat_first_row, character(0))) {
      hideFeedback("pmet_result")
      showFeedbackDanger(inputId = "pmet_result", text = "Empty file")
    } else if (!identical(dat_first_row, pmet_result_rowname)) {
      print("Wrong format of uploaded file")
      hideFeedback("pmet_result")
      showFeedbackDanger(inputId = "pmet_result", text = "Wrong format of uploaded file")
    }
    incProgress(0.5)

    validate(need(identical(dat_first_row, pmet_result_rowname), "Please upload a corret PMET result file."))

    tic("Read data")
    df <- data.table::fread(input$pmet_result$datapath,
      select = c(
        "Cluster", "Motif 1", "Motif 2",
        "Number of genes in cluster with both motifs",
        "Adjusted p-value (BH)", "Genes"
      ),
      verbose = FALSE
    ) %>%
      setNames(c("cluster", "motif1", "motif2", "gene_num", "p_adj", "genes")) %>%
      # dplyr::filter(gene_num > 0) %>%
      arrange(desc(p_adj)) %>%
      mutate(`motif_pair` = paste0(motif1, "^^", motif2))
    toc()
  }) # end of progress
  return(df)
}) # end of pmet_result <- reactive({


# filter data ----------------------------------------------------------------
# observeEvent(input$topn_pair, {
#   updateNumericInput(session, "topn_pair",
#     value = ({
#       if (!(is.numeric(input$topn_pair))) {
#         5
#       } else if (!(is.null(input$topn_pair) || is.na(input$topn_pair))) {
#         if (input$topn_pair < 1) {
#           1
#         } else if (input$topn_pair > 80) {
#           80
#         } else {
#           return(isolate(input$topn_pair))
#         }
#       } else {
#         5
#       }
#     }) # value
#   ) # updateNumericInput
# }) # observeEvent

# observeEvent(input$p_adj, {
#   print(input$p_adj)
#   print("fdasfa词的放大法")
#   updateNumericInput(session, "p_adj",
#     value = ({
#       if (!(is.numeric(input$p_adj))) {
#         0.05
#       } else if (!(is.null(input$p_adj) || is.na(input$p_adj))) {
#         if (input$p_adj < 0) {
#           0.05
#         } else if (input$p_adj > 1) {
#           1
#         } else {
#           return(isolate(input$p_adj))
#         }
#       } else {
#         0.05
#       }
#     }) # value
#   ) # updateNumericInput
# }) # observeEvent


iv <- InputValidator$new()
iv$add_rule("topn_pair", sv_numeric())
iv$add_rule("p_adj", sv_numeric())

# Finally, `enable()` the validation rules
iv$enable()


# filter data and update selection box -----------------------------------------
results <- reactive({
  validate(need(!is.null(input$p_adj), "Please enter a positive integer."))
  validate(need(!is.na(input$p_adj), "Please enter a positive integer."))
  validate(need(input$p_adj >= 0, "Please enter a positive integer."))
  validate(need(is.integer(as.integer(input$p_adj)), "Please enter a positive integer."))

  validate(need(!is.null(input$topn_pair), "Please enter a positive integer."))
  validate(need(!is.na(input$topn_pair), "Please enter a positive integer."))
  validate(need(input$topn_pair >= 0, "Please enter a positive integer."))
  validate(need(is.integer(as.integer(input$topn_pair)), "Please enter a positive integer."))

  # validate if there will be no data left after filtering
  if (min(pmet_result()$p_adj) > input$p_adj) {
    hideFeedback("p_adj")
    showFeedbackDanger(inputId = "p_adj", text = "No records left after filtering")
  } else if (min(pmet_result()$p_adj) == 1) {
    hideFeedback("p_adj")
    showFeedbackDanger(inputId = "p_adj", text = "No meaninful records left after filtering")
  } else {
    hideFeedback("p_adj")
  }
  validate(need(
    min(pmet_result()$p_adj) < input$p_adj,
    "You may need to make less p.adj restriction."
  ))

  # filtering data
  withProgress(message = "Filtering data", value = 0.3, {
    # filter data
    pmet_result_processed <- pmet.result.proces.func(
      pmet_result = pmet_result(),
      p_adj_limt = input$p_adj,
      gene_portion = 0.05,
      topn = input$topn_pair,
      unique_cmbination = input$motif_pair_unique
    )

    incProgress(0.8)
    clusters <- pmet_result_processed$motifs %>%
      names() %>%
      sort()

    # update cluster selection box
    if (input$motif_pair_unique == "TRUE") {
      clusters <- c("Overlap", "All", clusters)
    } else {
      clusters <- c("All", "Aggregation", clusters)
    }
    updateSelectInput(session, "method", choices = clusters, selected = input$method)

    incProgress(0.9)
    return(pmet_result_processed)
  }) # withProgress
})

# clusters of processed data -------------------------------------------------


# reshape processed data -----------------------------------------------------
result_reshaped <- reactiveVal()

observe({
  results <- results()

  withProgress(message = "Creating data for heatmap", value = 20, {
    # update data for plot
    result_reshaped(data.reshape.func11(results$pmet_result, results$motifs, counts = "p_adj"))
  }) # withProgress
})


# data (reactive value) for heat map -----------------------------------------
plot_data <- reactive({
  dat_list <- result_reshaped()
  clusters <- names(dat_list) %>% sort()

  # Overlap --------------------------------------------------
  if (input$method == "Overlap") {
    # merge data into DF[[1]]
    dat <- dat_list[[1]]

    # move all non-NA row from other DFs to DF[[1]]
    for (i in 2:length(dat_list)) {
      indx <- which(!is.na(dat_list[[i]][, "cluster"]))

      dat[indx, ] <- dat_list[[i]][indx, ]
      dat[indx, "cluster"] <- names(dat_list)[i]
    }
  }
  # All ---------------------------------------------------
  else if (input$method == "All") {
    dat <- dat_list
  } # each cluster ----------------------------------------------
  else if (input$method %in% clusters) {
    dat <- dat_list[[input$method]]
  } # Aggregation ----------------------------------------------
  else if (input$method == "Aggregation") {
    top_motif_list <- results()$motifs

    dat <- list()

    for (clu_motif in clusters) {
      top_motifs <- top_motif_list[[clu_motif]]
      a <- pmet_result() %>% filter(motif1 %in% top_motifs & motif2 %in% top_motifs)
      a$p_adj <- round(-log10(a$p_adj), 2)

      for (clu_dat in clusters) {
        dat[[paste0(clu_motif, "_", clu_dat)]] <- a %>%
          filter(cluster == clu_dat) %>%
          arrange(motif1, desc(motif2))
      }
    }
  }
  return(dat)
})

# show buttons of data viewer and plot when data loaded
observe({
  shinyjs::hide("plot.button")
  shinyjs::hide("download.button")
  # shinyjs::hide("dataviewer_btn")

  if (!is.null(plot_data())) {
    shinyjs::show("plot.button")
    # shinyjs::show("dataviewer_btn")
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
  shinyjs::hide("placeholder") # hide  d3 plot
})


# display motif text ---------------------------------------------------------
output$dimension_display <- renderText({
  # print screen size
  # paste(input$dimension[1]/12*8, input$dimension[2], input$dimension[2]/input$dimension[1])
  results <- results()
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
# Lets look for changes in our vehicle class dropdown then crunch the data and serve it to D3
observeEvent(input$plot.button,
  {
    dat <- list(
      method = input$method,
      data = plot_data(),
      clusters = sort(names(result_reshaped()))
    )

    # json data for D3 -----------------------------------------
    json_pmet <- pretty_json(jsonify::to_json(dat))

    # S end that json from the session to our javascript --------
    session$sendCustomMessage(type = "jsondata", json_pmet)
  },
  ignoreNULL = FALSE,
  ignoreInit = FALSE
)

# This tells shiny to run our javascript file "script.js" and send it to the UI for rendering
output$d3 <- renderUI({
  HTML('<script type="text/javascript", src="script.js">  </script>')
})

# download heat map ---------------------------------------------------------
output$download.button <- downloadHandler(
  filename = function() {
    "a.png"
  },
  content = function(file) {
    results <- results()
    clusters <- names(results$pmet_result) %>% sort()

    if (input$method == "Overlap") {
      p <- plot.moti.pair.overlap.func(results$pmet_result, results$motifs)
    } else {
      if (input$method == "All") {
        respective_plot <- FALSE
      } else if (input$method %in% clusters) {
        respective_plot <- TRUE
      }

      p <- plot.motif.pair.func(results$pmet_result,
        results$motifs,
        counts = "p_adj",
        exclusive_motifs = TRUE,
        by_cluster = FALSE,
        show_cluster = FALSE,
        legend_title = "-log10(p.adj)",
        nrow_ = 2,
        ncol_ = 2,
        axis_lables = "",
        show_axis_text = TRUE,
        diff_colors = TRUE,
        respective_plot = respective_plot,
        return.data = FALSE
      )

      if (input$method %in% clusters) {
        p <- p[[input$method]]
      }
    }
    ggsave(file, p, width = 20, height = 20, dpi = 320, units = "in")
  }
)


# Data table -----------------------------------------------------------------
output$datatable_tabs <- renderUI({
  tagList(
    # downloadButton("download_result", "Download", class = "btn-success"),
    tabsetPanel(ui_data("info1", "Info1"))
  )
})

observeEvent(results(), {
  server_data("info1", results()$pmet_result)
})
