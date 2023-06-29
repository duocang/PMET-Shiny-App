tabPanel(
  title = "Home",
  value = "home_tabpanel",
  actionButton("jump_pmet_bnt", "Run PMET"),
  actionButton("jump_heat_bnt", "Analyze PMET"),

  tags$head(
    tags$style(HTML("
      #photo {
        display: flex;
        justify-content: center;
        align-items: center;
        margin-top: 200px;
      }
    "))
  ),
  imageOutput("photo")
)
