tabPanel(
  introjsUI(),
  useShinyFeedback(),
  title = "Run job",
  value = "pmet_tabpanel",
  pageWithSidebar(
    dashboardHeader(disable = TRUE),
    sidebarPanel(
      width = 4,
      # promoters
      div(id = "mode_div",
        div("Choose type of input sequences",
          class = "control-label",
          style = "display:inline-block",
          id = "pmet_tooltip",
          tags$i(class = "fas fa-question-circle", style = "margin-left: 5px"),
          bsTooltip(
            "pmet_tooltip",
            paste0(
              "<b>Promoters (precomputed):</b><br>Motifs have been mapped to the promoters of all genes. The motif-pairs of the uploaded genes will be collected from these mappings.<br><br>",
              "<b>Promoters:</b><br>Motifs will be mapped to the promoters of genes, extracted from the uploaded genome and annotation. The motif-pairs of the uploaded genes will be collected from these mappings.<br><br>",
              "<b>Genomic intervals:</b><br> Same as the Promoters mode."
            ),
              placement = "right",
              options = list(container = "body", html = TRUE, width = "600px")
          )
        ),
        radioButtons("mode", NULL,
          c("Promoters (Pre-computed species)" = "promoters_pre",
            "Promoters"                        = "promoters",
            "Genomic intervals"                = "intervals"),
          inline = FALSE
        )
      ),
      uiOutput("mode_ui"),
      div(id = "emai_div", textInput("email", "Email", value = "")
      ),
      div(class = "run_pmet_div",
        style = "margin-top:30px;display:flex;justify-content:center;align-items:center;margin-top:30px",
        shinyjs::hidden(
          div(id = "run_pmet_btn_div",
            loadingButton("run_pmet_btn",
              label = "Run PMET",
              style = "width: 130px;color:#ffff; background-color:#fb8b05;"
            )
          )
        ),
        uiOutput("pmet_result_download_ui"),
        # Use this function somewhere in UI
        use_busy_spinner(spin = "fading-circle", position = "bottom-left")
      )
    ),
    mainPanel(
      uiOutput("txt_species"),
      uiOutput("txt_genome"),
      uiOutput("txt_annotation"),
      uiOutput("txt_motif_db"),
    )
  )
)
