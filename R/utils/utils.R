valid.email.func <- function(x) {
  grepl("\\<[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}\\>", as.character(x), ignore.case = TRUE)
}

# check files uploaded and email before running PMET
valid.files.email.func <- function(input) {
  motif_db   <- input$motif_db
  fasta      <- input$uploaded_fasta$datapath
  annotation <- input$uploaded_annotation$datapath
  genes      <- input$gene_for_pmet$datapath

  if (motif_db == "uploaded_motif") {
    all_files_uploaded <- ifelse(length(c(motif_db, fasta, annotation, genes)) == 4, TRUE, FALSE)
  } else {
    all_files_uploaded <- !is.null(genes)
  }
  return(valid.email.func(input$userEmail) & all_files_uploaded)
}



# prepare all paths/directories needed by PMET
paths.for.pmet.func <- function(input) {

  genes_path <- input$gene_for_pmet$datapath
  project_path <- getwd() # %>% str_replace("/01_shiny", "")

  if (input$motif_db != "uploaded_motif") {
    species <- str_split(input$motif_db, "-")[[1]][1]

    pmetIndex_path <- file.path(project_path, "data/PMETindex", species, input$motif_db)
    folder_name <- str_split(input$userEmail, "@")[[1]] %>%
      paste0(collapse = "_") %>%
      paste0("_", species, "_", input$motif_db) %>%
      paste0("_", format(Sys.time(), "%Y%b%d_%H%M"))
    user_folder <- file.path(project_path, "result", folder_name)
  } else {

    motif_db <- input$uploaded_motif_db$name %>% str_replace(".meme", "") %>%
      paste0(., "_", str_replace(input$userEmail, "@", "-")) %>%
      paste0("_", format(Sys.time(), "%Y%b%d_%H%M"))

    print(motif_db)

    pmetIndex_path <- file.path(project_path, "data/PMETindex", input$motif_db, motif_db)
    folder_name <- str_split(input$userEmail, "@")[[1]] %>%
      paste0(collapse = "_") %>%
      paste0("_", input$motif_db) %>%
      paste0("_", format(Sys.time(), "%Y%b%d_%H%M"))
    user_folder <- file.path(project_path, "result", folder_name)
  }

  return(list(genes_path = genes_path,
              project_path = project_path,
              pmetIndex_path = pmetIndex_path,
              folder_name = folder_name,
              user_folder = user_folder))
}

colors.plotly.func <- function() {
  vals <- c(0, 40)
  o <- order(vals, decreasing = FALSE)
  cols <- scales::col_numeric("Blues", domain = NULL)(vals)
  colz <- setNames(data.frame(vals[o], cols[o]), NULL)
  return(colz)
}


# create an empty data.frame with all pairs of motif-motif combination in a long format to be joined with PMET results
epmty.df.func <- function(motifs) {
  all <- data.frame(matrix(ncol = length(motifs), nrow = length(motifs))) %>%
    `colnames<-`(motifs) %>%
    `rownames<-`(motifs) %>%
    tibble::add_column(motif2 = motifs, .before = motifs[1]) %>%
    reshape2::melt("motif2") %>%
    setNames(c("motif1", "motif2", "value"))
  return(all)
}

# check elements duplicated
allDuplicated <- function(vec) {
  front <- duplicated(vec)
  back <- duplicated(vec, fromLast = TRUE)
  all_dup <- front + back > 0
  return(all_dup)
}

colors.plotly.func <- function() {
  vals <- c(0, 40)
  o <- order(vals, decreasing = FALSE)
  cols <- scales::col_numeric("Blues", domain = NULL)(vals)
  colz <- setNames(data.frame(vals[o], cols[o]), NULL)
  return(colz)
}


# process PMET result
# 1. filter
# 2. remove duplicated combinations
pmet.result.proces.func <- function(pmet_result = NULL,
                                    p_adj_limt = 0.05,
                                    gene_portion = 0.05,
                                    topn = 40,
                                    ncol_ = 2,
                                    histgram_dir = NULL,
                                    unique_cmbination = TRUE,
                                    colors = c("#ed3333", "#8b2671", "#11659a", "#1a6840", "#f9a633", "#2f2f35")) {
  suppressMessages({
    # keep the plot result to return later
    results <- list()

    clusters <- unique(pmet_result$cluster) %>% sort()

    colors <- colors[1:length(clusters)]
    names(colors) <- clusters

    ### 1.1 Histogram of p_adj
    if (!is.null(histgram_dir)) {
      p <- clusters %>%
        lapply(function(clu) {
          pmet_result[, c("cluster", "p_adj")] %>%
            filter(cluster == clu) %>%
            ggplot(aes(x = p_adj, fill = cluster)) +
            geom_histogram(fill = colors[[clu]], alpha = 0.6, position = "identity") +
            theme_ipsum() +
            theme_bw() +
            ggtitle(clu) +
            labs(fill = "")
        }) %>%
        ggarrange(plotlist = ., ncol = ncol_, nrow = ceiling(length(clusters) / ncol_))
      ggsave(file.path(histgram_dir, "histgram_padj_before_filter.png"), p)
    }



    ## 2. Full genes of each cluster
    genes.list <- clusters %>%
      lapply(function(clu) {
        genes <- pmet_result %>%
          filter(cluster == clu) %>%
          pull(genes) %>%
          paste(collapse = "") %>%
          str_split(pattern = ";")

        genes[[1]] %>%
          head(-1) %>%
          unique()
      }) %>%
      setNames(clusters)

    genes_list_length <- sapply(genes.list, length)

    print(genes_list_length)

    ## 3. Filter data
    #
    # 1. by p-value, < 0.0005
    # 2. by genes, > 5% * cycle genes
    pmet_filtered <- pmet_result
    for (clu in clusters) {
      gene_num_limt <- gene_portion * genes_list_length[[clu]]
      pmet_filtered <- pmet_filtered %>%
        filter(p_adj <= p_adj_limt) %>%
        filter((cluster == clu & gene_num > gene_num_limt) | cluster != clu) %>%
        arrange(desc(p_adj))
    }

    print(table(pmet_filtered$cluster))

    # update clusters every time after filtering
    clusters <- unique(pmet_filtered$cluster) %>% sort()


    ### 3.1 Histogram of p_adj
    if (!is.null(histgram_dir)) {
      p <- clusters %>%
        lapply(function(clu) {
          pmet_filtered[, c("cluster", "p_adj")] %>%
            filter(cluster == clu) %>%
            ggplot(aes(x = p_adj, fill = cluster)) +
            geom_histogram(fill = colors[[clu]], alpha = 0.6, position = "identity") +
            theme_ipsum() +
            theme_bw() +
            ggtitle(clu) +
            labs(fill = "")
        }) %>%
        ggarrange(plotlist = ., ncol = ncol_, nrow = ceiling(length(clusters) / ncol_))
      ggsave(file.path(histgram_dir, "histgram_padj_after_filter.png"), p)
    }


    ## 4. Remove shared combinations  of  motif  pair
    # find which motif pairs are not unique
    if (unique_cmbination) {
      pmet_filtered <- pmet_filtered[which(allDuplicated(motif_pair) != "TRUE"), ]
    }

    # update clusters every time after filtering
    clusters <- unique(pmet_filtered$cluster) %>% sort()

    print(table(pmet_filtered$cluster))

    ## 5. Split pmet resut by cluster
    pmet_filtered_split_list <- pmet_filtered[, ] %>% split(pmet_filtered$cluster)

    motifs_top_list <- clusters %>%
      lapply(function(clu) {
        dat <- pmet_filtered_split_list[[clu]] %>%
          arrange(p_adj) %>%
          head(topn)
        c(dat$motif1, dat$motif2) %>% unique()
      }) %>%
      setNames(clusters)

    results[["pmet_result"]] <- pmet_filtered_split_list
    results[["motifs"]] <- motifs_top_list
  })

  return(results)
}


# process cooked PMET result
# 1. asymmetric
# 2. lower half data
plot_data_func <- function(df, top_motifs, present.opt = "p_adj") {
  suppressMessages({
    empty.mtofis.df <- epmty.df.func(top_motifs)

    # make data asymmetric
    df.asymmetrised <- df %>%
      filter(motif1 %in% top_motifs & motif2 %in% top_motifs) %>%
      ggasym::asymmetrise(motif1, motif2) %>%
      dplyr::left_join(empty.mtofis.df[, 1:2], .) %>%
      cbind(motif = paste0(.$motif1, "^^", .$motif2))

    if (present.opt == "gene_num") {
      # get lower half data
      df <- df.asymmetrised %>%
        select(motif1, motif2, gene_num) %>%
        reshape2::dcast(motif1 ~ motif2) %>%
        remove_rownames() %>%
        column_to_rownames(var = "motif1") %>%
        # get_upper_tri() %>% select(rev(colnames(.))) %>%
        get_upper_tri() %>%
        select(colnames(.)) %>%
        tibble::add_column(., motif2 = row.names(.), .before = 1) %>%
        reshape2::melt("motif2") %>%
        setNames(c("motif1", "motif2", "gene_num")) %>%
        cbind(motif = paste0(.$motif1, "^^", .$motif2)) # %>%dplyr::select(gene_num, motif)

      # left join
      df <- left_join(df, df.asymmetrised, by = c("motif", "gene_num")) %>%
        dplyr::select(motif1.x, motif2.x, gene_num, p_adj, genes) %>%
        setNames(c("motif1", "motif2", "gene_num", "p_adj", "genes")) # %>%mutate(gene_num = coalesce(gene_num, 0))

      df$gene_num <- df$gene_num %>% replace_na(0)
    } else {
      # get lower half data
      df <- df.asymmetrised %>%
        select(motif1, motif2, p_adj) %>%
        reshape2::dcast(motif1 ~ motif2) %>%
        remove_rownames() %>%
        column_to_rownames(var = "motif1") %>%
        get_upper_tri() %>%
        select(rev(colnames(.))) %>%
        # get_upper_tri() %>% select(colnames(.)) %>%
        tibble::add_column(., motif2 = row.names(.), .before = 1) %>%
        reshape2::melt("motif2") %>%
        setNames(c("motif1", "motif2", "p_adj")) %>%
        cbind(motif = paste0(.$motif1, "^^", .$motif2))

      # left join，to get extra info
      df <- left_join(df, df.asymmetrised, by = c("motif", "p_adj")) %>%
        dplyr::select(cluster, motif1.x, motif2.x, gene_num, p_adj, genes) %>%
        setNames(c("cluster", "motif1", "motif2", "gene_num", "p_adj", "genes"))

      df$p_adj <- df$p_adj %>% replace_na(1)
      df$p_adj <- round(-log10(df$p_adj), 2)

      # print(df[, c("motif1", "motif2", "gene_num", "p_adj")])
    }

    df$genes.orgi <- df$genes
    # break down genes into multiple lines for better plotly view
    df$genes <- sapply(df$genes, function(x) {
      stringr::str_replace_all(x, ";", " ") %>%
        trimws() %>%
        strwrap(width = 40) %>%
        paste(collapse = ";\n") %>%
        stringr::str_replace_all(" ", ";") %>%
        stringr::str_replace_all("\n", "\n             ")
    })
    # df$genes <- df$genes %>% str_replace_na(replacement = "")

    df$gene_num <- replace_na(df$gene_num, 0)
  }) # suppressMessage

  return(df)
}

# top_motifs <- c("AAA", "BBB", "FFF")
#
# a <- data.frame(motif1=c("aa", "AAA", "BBB"),
#                 motif2=c("aa", "ccc", "AAA"),
#                 value=c(1,2,3))
#
# a %>%
#   filter(motif1 %in% top_motifs & motif2 %in% top_motifs) %>%
#   ggasym::asymmetrise(motif1, motif2) %>%
#   dplyr::right_join(epmty.df.func(top_motifs)[, c(1,2)])



data.reshape.func11 <- function(pmet_split, motifs_list, counts = "p_adj") {
  suppressMessages({
    # pmet data for each cluster has been shaped in ggplot2 (long) format, but no gene info
    a <- plot.motif.pair.func(pmet_split, motifs_list, counts = counts, return.data = TRUE)

    # join with original pmet result to gain gene info
    lapply(names(pmet_split), function(clu) {
      names(a[[clu]]) <- c("motif1", "motif2", counts)
      # left joined with original pmet result by motif-pair (empty gene column gained)
      dat <- a[[clu]] %>%
        cbind(motif_pair = paste0(.$motif1, "^^", .$motif2)) %>%
        left_join(pmet_split[[clu]])

      # motif_pairs from non-empty rows from each ggplot2-format result (with gene
      # column gained from above-mentioned join)
      motif_pairs <- dat %>%
        filter(!is.na(!!counts)) %>%
        pull(motif_pair)

      pmet_non_empty <- pmet_split[[clu]] %>% filter(motif_pair %in% motif_pairs)

      for (i in 1:length(motif_pairs)) {
        indx <- which(dat$motif_pair == pmet_non_empty$motif_pair[i])

        if (counts == "p_adj") {
          dat[indx, c("cluster", "gene_num", "genes")] <- pmet_non_empty[i, c("cluster", "gene_num", "genes")]
        } else if (counts == "gene_num") {
          dat[indx, c("cluster", "p_adj", "genes")] <- pmet_non_empty[i, c("cluster", "p_adj", "genes")]
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
    }) %>% setNames(names(pmet_split))
  }) # suppressMessages
}


# plot heatmap of top motifs
# 1. remove shared motifs from each clusters
plot.motif.pair.func <- function(pmet_split,
                                 motifs_list,
                                 counts = "value",
                                 exclusive_motifs = TRUE,
                                 by_cluster = FALSE,
                                 show_cluster = FALSE,
                                 legend_title = "Value",
                                 nrow_ = 2,
                                 ncol_ = 2,
                                 axis_lables = "",
                                 show_axis_text = TRUE,
                                 diff_colors = FALSE,
                                 respective_plot = FALSE,
                                 return.data = FALSE) {
  suppressMessages({
    # ledgent color setting
    colors <- list(
      c("#fac3c3", "#ed3333"),
      c("#a2d5f5", "#11659a"),
      c("#baeed3", "#1a6840"),
      c("#f9cb8b", "#f9a633"),
      c("#bb7fa9", "#8b2671"),
      c("#47484c", "#2f2f35")
    )[1:length(pmet_split)]
    names(colors) <- names(pmet_split)

    # remove shared motifs
    if (exclusive_motifs) {
      motifs_list <- names(motifs_list) %>%
        lapply(function(clu) {
          motifs_clu <- motifs_list[[clu]]
          motifs_rest <- motifs_list[setdiff(names(motifs_list), clu)] %>%
            unlist() %>%
            unique()
          setdiff(motifs_clu, motifs_rest)
        }) %>%
        setNames(names(motifs_list))
    }

    # order motifs by clusters
    if (by_cluster & exclusive_motifs) {
      motifs_top <- motifs_list %>%
        unlist() %>%
        unname()

      samp_id <- 1:length(motifs_top)
      group <- names(motifs_list) %>%
        lapply(function(clu) {
          rep(clu, length(motifs_list[[clu]]))
        }) %>%
        unlist()

      # Build a legend "bar"
      groups <- data.frame(samp_id = samp_id, group = group)
      leg <- ggplot(groups, aes(y = samp_id, x = 0)) +
        geom_point(aes(color = group), shape = 15, size = 8, show.legend = F) +
        theme_classic() +
        theme(
          axis.title = element_blank(), axis.line = element_blank(),
          axis.text = element_blank(), axis.ticks = element_blank(),
          plot.margin = unit(c(0, 0, 0, 0), "cm")
        )

      arm <- ggplot(groups, aes(y = rev(samp_id), x = 0)) +
        geom_point(aes(color = group), shape = 15, size = 8, show.legend = F) +
        theme_classic() +
        theme(
          axis.title = element_blank(), axis.line = element_blank(),
          axis.text = element_blank(), axis.ticks = element_blank(),
          plot.margin = unit(c(0, 0, 0, 0), "cm")
        ) +
        coord_flip()
    } else {
      motifs_top <- motifs_list %>%
        unlist() %>%
        unique() %>%
        sort() %>%
        unname()
    }

    # in cases self-defined motifs' names needed
    if (length(axis_lables) > 1) {
      axis_lables_ <- axis_lables
    } else {
      axis_lables_ <- motifs_top
    }


    all <- epmty.df.func(motifs_top)

    plot_data_list <- lapply(pmet_split, function(dat) {
      dat <- dat %>% select(all_of(c("motif1", "motif2", counts)))

      if (counts == "p_adj") dat[, "p_adj"] <- round(-log10(dat[, "p_adj"]), 2)

      dat.asymed <- dat %>%
        filter(motif1 %in% motifs_top & motif2 %in% motifs_top) %>%
        ggasym::asymmetrise(motif1, motif2)

      dat.asymed.join.long <- dplyr::left_join(all[, 1:2], dat.asymed) %>%
        reshape2::dcast(motif1 ~ motif2) %>%
        remove_rownames() %>%
        column_to_rownames(var = "motif1")
      # make matrix have specific column names order
      a <- subset(dat.asymed.join.long, select = motifs_top)
      a$motif1 <- row.names(a)
      a <- a[match(motifs_top, a$motif1), ]
      a[, 1:length(motifs_top)] <- get_upper_tri(a[, 1:length(motifs_top)])

      a <- reshape2::melt(a, "motif1", variable.name = "motif2")
      a$motif1 <- factor(a$motif1, levels = motifs_top)
      a$motif2 <- factor(a$motif2, levels = motifs_top)
      return(a)
    })

    # return data
    if (return.data) {
      return(plot_data_list)
    }


    # legend range
    a <- do.call(rbind.data.frame, plot_data_list)
    value.min <- min(a$value, na.rm = T)
    value.max <- max(a$value, na.rm = T)

    # create ggplot objects
    p_list <- lapply(names(plot_data_list), function(clu) {
      output <- plot_data_list[[clu]]


      if (diff_colors) {
        color.min <- colors[[clu]][1]
        color.max <- colors[[clu]][2]
      } else {
        color.min <- "#ffe5e5"
        color.max <- "#ff0000"
      }

      p <- ggplot(output, aes(x = motif1, y = motif2, fill = value)) +
        geom_tile(color = "#c4d7d6", lwd = 0) +
        scale_fill_gradient2(
          low = color.min,
          high = color.max,
          na.value = "white",
          limits = c(value.min, value.max),
          name = legend_title
        ) +
        scale_y_discrete(limits = rev, labels = rev(axis_lables_)) +
        theme_bw() +
        coord_fixed()
      if (show_axis_text) {
        p <- p + theme(
          axis.line = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_text(angle = 90)
        )
      } else {
        p <- p + theme(
          axis.line = element_blank(),
          axis.title.x = element_blank(),
          axis.title.y = element_blank(),
          axis.text.x = element_blank(),
          axis.text.y = element_blank()
        )
      }

      if (by_cluster & show_cluster) {
        p <- p +
          annotation_custom(ggplotGrob(leg), xmin = -0.4, xmax = 0.5, ymin = -2, ymax = Inf) +
          annotation_custom(ggplotGrob(arm), xmin = 0, xmax = Inf, ymin = -0.5, ymax = 0.4)
      }
      p
    }) %>%
      setNames(names(plot_data_list))
    # create ggplot objects (end)

    if (respective_plot) {
      return(p_list)
    }

    p_list <- lapply(names(plot_data_list), function(clu) {
      p_list[[clu]] + ggtitle(clu)
    })


    ggarrange(plotlist = p_list, ncol = ncol_, nrow = nrow_)
  })
}






plot.moti.pair.overlap.func <- function(pmet_split, motifs_list, counts = "p_adj", by_cluster = FALSE) {
  # remove shared motifs
  motifs_list <- names(motifs_list) %>%
    lapply(function(clu) {
      motifs_clu <- motifs_list[[clu]]
      motifs_rest <- motifs_list[setdiff(names(motifs_list), clu)] %>%
        unlist() %>%
        unique()
      return(setdiff(motifs_clu, motifs_rest))
    }) %>%
    setNames(names(motifs_list))

  motifs_top <- motifs_list %>%
    unlist() %>%
    sort() %>%
    unname()

  # order motifs
  plot_motif_pairs <- plot.motif.pair.func(pmet_split, motifs_list, counts = counts, return.data = T, by_cluster = by_cluster)

  # merge data into one df
  plot_data <- plot_motif_pairs[[1]]
  plot_data$cluster <- NA # new column to provide color(cluster) info in heat map

  # move all non-NA row from other DFs to DF[[1]]
  for (i in 1:length(plot_motif_pairs)) {
    indx <- which(!is.na(plot_motif_pairs[[i]][, "value"]))

    plot_data[indx, ] <- plot_motif_pairs[[i]][indx, ]
    plot_data[indx, "cluster"] <- names(plot_motif_pairs)[i]
  }

  # colors <- c("#ed3333","#11659a","#1a6840","#f9a633", "#8b2671", "#2f2f35")[1: length(names(pmet_split))]
  colors <- c("#ed3333", "#11659a", "#1a6840", "#f9a633", "#8b2671", "#2f2f35")[seq_along(names(pmet_split))]
  names(colors) <- names(pmet_split)

  p <- plot_data %>%
    ggplot(aes(motif1, motif2, alpha = value, fill = factor(cluster))) +
    geom_tile(color = "white") +
    scale_alpha(range = c(0.3, 1)) +
    # scale_fill_brewer(palette = "Set1", na.value = "white") +
    scale_fill_manual(values = colors, na.value = "white") +
    scale_y_discrete(limits = rev, labels = rev(motifs_top)) +
    theme_bw() +
    theme(
      legend.title = element_blank(),
      legend.position = "top",
      axis.line = element_blank(),
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      axis.text.x = element_text(angle = 90)
    ) +
    # guides(fill = "none", alpha = "none") +
    coord_fixed() +
    labs(x = NULL, y = NULL) # , title = "", subtitle = "")
  return(p)
}

# Save top motifs (pairs) to excel
save.excel.func <- function(pmet_split, motifs_list, path) {
  motifs_top <- motifs_list %>%
    unlist() %>%
    unique() %>%
    sort() %>%
    unname()

  wb <- createWorkbook()

  for (clu in names(pmet_split)) {
    dat <- pmet_split[[clu]] %>%
      filter(motif1 %in% motifs_top & motif2 %in% motifs_top) %>%
      arrange(!!rlang::sym("p_adj"))

    addWorksheet(wb, clu)
    writeData(wb, clu, dat)
  }
  addWorksheet(wb, "all")
  pmet_merged <- bind_rows(pmet_split, .id = "cluster")



  colors <- c("#ed3333", "#11659a", "#1a6840", "#f9a633", "#8b2671", "#2f2f35")[seq_along(names(pmet_split))]
  names(colors) <- names(pmet_split)
  pmet_merged$highlighted <- FALSE
  # highlight rows in heat map
  for (clu in names(pmet_split)) {
    print(clu)
    color <- createStyle(fgFill = colors[[clu]])

    indx <- which(pmet_merged$motif1 %in% motifs_top &
      pmet_merged$motif2 %in% motifs_top &
      pmet_merged$cluster == clu)
    print(indx)
    pmet_merged[indx, "highlighted"] <- TRUE
    addStyle(
      wb = wb, sheet = "all", style = color,
      rows = indx + 1, cols = 1:ncol(pmet_merged), gridExpand = T
    )
  }


  writeData(wb, sheet = "all", pmet_merged)
  saveWorkbook(wb, path, overwrite = T)
}
