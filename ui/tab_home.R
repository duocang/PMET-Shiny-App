tabPanel(
  title = "Home",
  value = "home_tabpanel",
  actionButton("jump_pmet_bnt", "Run PMET"),
  actionButton("jump_heat_bnt", "Analyze PMET"),

  # # a button on the right side of narbar
  # style = "padding: 0px;", # no gap in navbar
  # actionButton("logout", "Log Out", icon = icon("user"),
  #              style = "position: absolute; top: 5px; right: 5px; z-index:10000;")
)
