tabPanel(
  title = "Test",
  value = "Test_tabpanel",
  fluidPage(
    div(
      HTML('
        <html lang="en" >
        <head>
          <link rel="stylesheet" href="https://unpkg.com/fullpage.js/dist/fullpage.min.css">
          <style>
            .section {
              text-align:center;
              // font-size: 3em;
            }

             /* Center the div horizontally */
            .title_div {
              display: flex;
              justify-content: center;
            }
            /* Set font size of p to 15px */
            .title_div p {
              width: 900px;
            }
          </style>

        </head>
        <body>
          <div id="fullpage">
            <div class="section">
              <div> <img src="https://raw.githubusercontent.com/duocang/images/master/PicGo/202307101446355.png" height="350" alt=""> </div>
              <div class = "text_div">
                <p style="text-align: left; font-size: 17px">
                  "PMET is a powerful tool designed to assist researchers in analyzing
                  the interactions between transcription factors (TFs) and gene expression.
                  By studying the combinations of homotypic and heterotypic motifs within
                  transcription regulatory modules, PMET provides a comprehensive framework
                  for analyzing and understanding the functional implications and regulatory
                  dynamics associated with motif interactions in gene expression.")
                </p>
              </div>

              <div id="buttons">
                <button id="jump_pmet_bnt" style="width: 150px; margin-right: 100px; background-color: #DBEDDB; border: none; color: ##0000; padding: 10px 20px; text-align: center; text-decoration: none; display: inline-block; font-size: 16px; font-weight: bold; border-radius: 4px; box-shadow: 0px 2px 3px rgba(0, 0, 0, 0.4);">Run PMET</button>
                <button id="jump_heat_bnt" style="width: 150px; margin-right: 100px; background-color: #E8F3FC; border: none; color: ##0000; padding: 10px 20px; text-align: center; text-decoration: none; display: inline-block; font-size: 16px; font-weight: bold; border-radius: 4px; box-shadow: 0px 2px 3px rgba(0, 0, 0, 0.4);">Run PMET</button>
              </div>
            </div>

          <div class="section">
            <div class="title_div">
              <p style="text-align: center; font-size: 21px; font-weight:bold">
                Why Choose PMET?
              </p>
            </div>

            <div class="text_div">
              <p style="text-align: left; font-size: 17px">
                PMET is designed to address the limitations of traditional analysis tools by considering both homotypic and heterotypic motif combinations simultaneously.
              </p>
            </div>

            <div class="text_div">
              <p style="text-align: left; font-size: 17px">
                PMET is available in both command-line and web-based versions, providing flexibility and convenience to researchers.
              </p>
            </div>
          </div>

          <div class="section">
            <div class="title_div">
              <p style="text-align: center; font-size: 21px; font-weight:bold">
                Functionality of PMET
              </p>
            </div>

            <div class="text_div">
              <p style="text-align: left; font-size: 17px">
                <strong>Homotypic Clustering: </strong>PMET can identify clusters of homotypic motifs within the genome based on the motif data provided by the user. This analysis helps uncover the significance and functionality of motifs in gene regulation.</p>
            </div>

            <div class="text_div">
              <p style="text-align: left; font-size: 17px">
                <strong>Heterotypic Clustering: </strong>After identifying clusters of homotypic motifs, PMET further analyzes the pairings between these clusters to generate heterotypic clusters. Through this process, PMET reveals the potential interactions between motifs in gene regulation.</p>
            </div>

          </div>

          <div class="section">
            <p style="text-align: center; font-size: 21px; font-weight:bold">
              Workflow
            </p>
            <div>
              <img src="https://raw.githubusercontent.com/duocang/images/master/PicGo/202307101459490.png" height="650px">
            </div>
          </div>
          </div>
          <script src="//cdnjs.cloudflare.com/ajax/libs/jquery/2.1.3/jquery.min.js"></script>
          <script src="https://unpkg.com/fullpage.js/dist/fullpage.min.js"></script>
          <script>
            new fullpage("#fullpage", {
              anchors: ["page1", "page2", "page3", "page4"],
              licenseKey: "gplv3-license"
            });

            //adding the actions to the buttons
            $(document).on("click", "#destroy", function(){ fullpage_api.destroy("all"); });
          </script>

          </body>
        </html>

      ')
    )
  )
)

