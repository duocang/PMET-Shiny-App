tabPanel(
  title = "Home",
  value = "home_tabpanel",
  actionButton("jump_pmet_bnt", "Run PMET"),
  actionButton("jump_heat_bnt", "Analyze PMET"),

  imageOutput("photo")
)
