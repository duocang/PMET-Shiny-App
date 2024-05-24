# tabPanel(
#   "Data review",
#   uiOutput(("datatable_tabs"))
# )

# output$dataTable <- DT::renderDataTable({
#   validate(need(dim(pmet_result())[1] > 2, "Sorry"))
#   return(pmet_result())
# })

# # Data table -----------------------------------------------------------------
# output$datatable_tabs <- renderUI({
#   tagList(
#     downloadButton("download_result", "Download", class = "btn-success"),
#     tabsetPanel(ui_data("info1", "Info1"))
#   )
# })

# observeEvent(results(), {
#   server_data("info1", results()$pmet_result)
# })

# # download result ------------------------------------------------------------
# output$download_result <- downloadHandler(
#   filename = function() {
#     "a.xlsx"
#   },
#   content = function(file) {
#     results <- results()
#     clusters <- names(results$pmet_result) %>% sort()

#     save.excel.func(results$pmet_result, results$motifs, file)
#   } # end of content
# )
