tabPanel(
  class = "tabPanel_shiny",
  "My Tab",
  tags$head(
    tags$style(HTML("
      /*定义右边纵向滚动条高和宽达到隐藏效果*/
      ::-webkit-scrollbar {
        width: 1px; /*滚动条宽度*/
        height: 1px; /*滚动条高度*/
      }
      * {
        padding: 0;
        margin: 0;
      }
      .container {
        height: 100vh;
        width: 100vw;
        scroll-snap-type: y mandatory;
        overflow-y: scroll;
        overflow-x: hidden;

        justify-content: center; /* 水平居中 */
        align-items: center; /* 垂直居中 */
      }
      .pages {
        scroll-snap-align: start;
        height: 100vh;
        width: 100vw;
      }
      /*注意里面两组高和宽的定义都是vh和vw是填满窗口的意思*/
      /*scroll-snap滚屏方式是直接用CSS完成不需要用到JS代码或插件*/
      /*现在大部分浏览器都支持这种方式，除非老款IE浏览器。*/


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
        font-size: 23px;
        font-weight: bold;
      }

    "))
  ),
  div(class = "container",
    div(class = "pages",
      div(style = "display: flex; justify-content: center; align-items: center; height: 500px; margin-bottom: 30px;",
        img(id="logo", src="https://raw.githubusercontent.com/duocang/images/master/PicGo/202307101446355.png", style = "height: 360px;")
      ),
      div(class = "text_div",
        p(style = "text-align: justify;",
          "PMET is a powerful tool designed to assist researchers in analyzing
          the interactions between transcription factors (TFs) and gene expression.
          By studying the combinations of homotypic and heterotypic motifs within
          transcription regulatory modules, PMET provides a comprehensive framework
          for analyzing and understanding the functional implications and regulatory
          dynamics associated with motif interactions in gene expression.")
      ),
      div(id = "buttons",
        # style = "display: flex; justify-content: center;",
        actionButton("jump_pmet_bnt", "Analyze"  , style = "width: 150px;height:42px;background-color:#DBEDDB;font-weight:bold;margin-right:100px;"),
        actionButton("jump_heat_bnt", "Visualize", style = "width: 150px;height:42px;background-color:#E8F3FC;font-weight:bold;")
      )
    ),
    div(class = "pages",
      div(style = "display: flex; justify-content: center; align-items: center; height: 100%;",
        div(style = "text-align: center;",
          div(class = "title_div",
            p("Why Choose PMET?")
          ),
          div(class = "text_div",
            p(style = "text-align: justify;",
              "PMET is designed to address the limitations of traditional
              analysis tools by considering both homotypic and heterotypic motif
              combinations simultaneously.")
          ),
          div(class = "text_div",
            p(style = "text-align: justify;",
              "PMET is available in both command-line and web-based versions,
              providing flexibility and convenience to researchers.")
          )
        )
      )
    ),
    div(class = "pages",
      div(style = "display: flex; justify-content: center; align-items: center; height: 100%;",
        div(style = "text-align: center;",
          div(class = "title_div",
            p("Functionality of PMET")
          ),
          div(class = "text_div",
            p(style = "text-align: justify;",
              strong("Homotypic Clustering: "), "PMET can identify clusters
                      of homotypic motifs within the genome based on the motif
                      data provided by the user. This analysis helps uncover
                      the significance and functionality of motifs in gene regulation.")
          ),
          div(class = "text_div",
            p(style = "text-align: justify;",
              strong("Heterotypic Clustering: "), "After identifying clusters of homotypic
                      motifs,PMET further analyzes the pairings between these clusters to
                      generate heterotypic clusters. Through this process, PMET reveals
                      the potential interactions between motifs in gene regulation.")
          )
        )
      )
    ),
    div(class = "pages",
      div(style = "display: flex; justify-content: center; align-items: center; height: 700px;",
        img(id="workflow", src="https://raw.githubusercontent.com/duocang/images/master/PicGo/202307202238627.png", style = "height: 700px;")
      )
    )
  )
)
