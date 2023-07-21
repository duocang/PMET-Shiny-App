observeEvent(input$jump_pmet_bnt, {
  updateTabsetPanel(session, "navbar",
    selected = "pmet_tabpanel"
  )
})

observeEvent(input$jump_heat_bnt, {
  updateTabsetPanel(session, "navbar",
    selected = "heatmap_tabpanel"
  )
})


observeEvent(input$navbar, {
  # print(input$navbar)
  # js_code <- paste0("console.log('Switched to tab: ", input$navbar, "');")
  # runjs(js_code)
  # if (input$navbar != "home_tabpanel") {
  #   js_code <- "$('body').css('background-color', '#ffffff');"
  #   runjs(js_code)
  # } else {
  #   runjs("$('body').css('background-color', '#76b7b2';")
  # }

  # js_code <- paste0("console.log('Switched to tab: ", input$navbar, "');")
  # runjs(js_code)
  # if (input$navbar == "Test_tabpanel") {
  #   js_code <-
  #     '
  #       new fullpage("#my-fullpage", {
  #         licenseKey: "GPLv3"
  #       });
  #     '
  # } else {
  #   js_code <- 'fullpage_api.destroy("all");'
  # }
  # runjs(js_code)
})