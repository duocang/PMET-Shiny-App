tabPanel(
  introjsUI(),
  useShinyFeedback(),
  title = "START",
  value = "run_start",
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
      div(id = "userEmail_div",
        textInput("userEmail", "Email", value = ""),
      ),
      # action button
      div(class = "run_pmet_div",
        shinyjs::hidden(
          shiny::div(
            id = "run_pmet_button_div",
            withBusyIndicatorUI(
              loadingButton("run_pmet_button",
                label = "Run PMET",
                loadingLabel = "Running...",
                style = "width: 135px"
              )
            )
          )
        )
      ),
      # Download PMET result button
      div(id = "pmet_result_download_ui_div",
        style = "margin-bottom:30px; margin-top:20px;",
        uiOutput("pmet_result_download_ui"),
        uiOutput("pmet_result_download_ui1")
      )
    ),
    mainPanel({
    })
  )
)
