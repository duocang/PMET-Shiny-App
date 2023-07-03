# # workthrough of home --------------------------------------------------------
# home_steps <- reactive({
#   elements <- c("#jump_pmet_bnt", "#jump_heat_bnt")
#   intors   <- c(
#                 "A tool for finding enrichment of pairs of transcription factor binding motifs within a set of sequences.",
#                 "Heat map")
#   data.frame(element = elements, intro = intors)
# })

observeEvent(input$jump_pmet_bnt, {
  updateTabsetPanel(session, "navbar",
    selected = "run_tabpanel"
  )
})

observeEvent(input$jump_heat_bnt, {
  updateTabsetPanel(session, "navbar",
    selected = "heatmap_tabpanel"
  )
})

output$photo <- renderImage({
  list(
    src = file.path("www/figures/PMET_workflow_with_interval_option.png"),
    contentType = "image/png",
    width = 1000
  )
}, deleteFile = FALSE)
