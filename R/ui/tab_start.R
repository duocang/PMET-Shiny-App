tabPanel(
  introjsUI(),
  useShinyFeedback(),
  title = "START",
  value = "pmet_tabpanel",
  pageWithSidebar(
    dashboardHeader(disable = TRUE),
    sidebarPanel(
      width = 4,
      # promoters
      div(id = "mode_div",
        div("PMET mode:", class = "control-label"),
        radioButtons("mode", NULL,
          c("Promoters (precomputed)" = "promoters_pre",
            "Promoters"               = "promoters",
            "Genomic intervals"       = "intervals"),
          inline = FALSE
        )
      ),
      uiOutput("mode_ui"),
      # personal info
      div(id = "emai_div",
        textInput("email", "Email", value = ""),
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
    mainPanel({
      div(id = "workflow_mode", imageOutput("image"))
    })
  )
)
