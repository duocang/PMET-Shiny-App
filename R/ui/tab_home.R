tabPanel(
  title = "Home",
  value = "home_tabpanel",
  tags$head(
    tags$style(HTML("
      #logo_div {
        height: 250px;
      }
      #logo {
        display: flex;
        justify-content: center;
      }

      #buttons {
        display: flex;
        justify-content: center;
        margin-bottom: 50px;
      }

      /* Center the div horizontally */
      .text_div {
        display: flex;
        justify-content: center;
      }
      /* Set font size of p to 15px */
      .text_div p {
        font-size: 16px;
        width: 900px;

      }

      /* Center the div horizontally */
      .title_div {
        display: flex;
        justify-content: center;
      }
      /* Set font size of p to 15px */
      .title_div p {
        font-size: 20px;
        font-weight: bold;
      }

      #workflow {
        display: flex;
        justify-content: center;
        align-items: center;
        margin-top: 210px;
      }
    "))
  ),
  div(id = "logo_div", imageOutput("logo")),

  div(class = "text_div",
    tags$p("PMET is a powerful tool designed to assist researchers in analyzing
            the interactions between transcription factors (TFs) and gene expression.
            By studying the combinations of homotypic and heterotypic motifs within
            transcription regulatory modules, PMET provides a comprehensive framework
            for analyzing and understanding the functional implications and regulatory
            dynamics associated with motif interactions in gene expression.")
  ),

  div(id = "buttons",
    # style = "display: flex; justify-content: center;",
    actionButton("jump_pmet_bnt", "Run PMET", style = "width: 150px;margin-right: 100px;background-color:#DBEDDB"),
    actionButton("jump_heat_bnt", "Analyze PMET", style = "width: 150px;background-color:#E8F3FC;")
  ),

  div(class = "title_div", tags$p("Why Choose PMET?")),
  div(class = "text_div",
    tags$p("PMET is designed to address the limitations of traditional
            analysis tools by considering both homotypic and heterotypic motif
            combinations simultaneously.")
  ),
  div(class = "text_div",
    tags$p("PMET is available in both command-line and web-based versions,
            providing flexibility and convenience to researchers.")
  ),

  div(class = "title_div", tags$p("Functionality of PMET")),
  div(class = "text_div",
    tags$p(tags$strong("Homotypic Clustering: "), "PMET can identify clusters
                        of homotypic motifs within the genome based on the motif
                        data provided by the user. This analysis helps uncover
                        the significance and functionality of motifs in gene regulation.")
  ),
  div(class = "text_div",
    tags$p(tags$strong("Heterotypic Clustering: "), "After identifying clusters of homotypic
                        motifs,PMET further analyzes the pairings between these clusters to
                        generate heterotypic clusters. Through this process, PMET reveals
                        the potential interactions between motifs in gene regulation.")
  ),

  div(imageOutput("workflow"))
)

# display: flex;
# justify-content: center;
# align-items: center;
# margin-top: 100px;