tabPanel(
  title = "Home",
  value = "home_tabpanel",
  actionButton("jump_pmet_bnt", "Run PMET"),
  actionButton("jump_heat_bnt", "Analyze PMET"),
  # p(
  #   tags$img(
  #     src = "pmet_workflow.png",
  #     alt = "Workflow of PMET",
  #     width = 900
  #   ),
  #   style = "display: block; margin-left: auto; margin-right: auto;"
  # ),
  imageOutput("photo")
  # # a button on the right side of narbar
  # style = "padding: 0px;", # no gap in navbar
  # actionButton("logout", "Log Out", icon = icon("user"),
  #              style = "position: absolute; top: 5px; right: 5px; z-index:10000;")
)
