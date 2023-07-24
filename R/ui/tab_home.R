# tabPanel(
#   title = "Test",
#   value = "Test_tabpanel",
#   tags$head(
#     tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/fullPage.js/3.1.2/fullpage.min.css"),
#     tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/fullPage.js/3.1.2/fullpage.min.js")
#   ),
#   tags$script("
#     $(document).ready(function() {
#       new fullpage('#my-fullpage', {
#         // fullPage.js options
#       });
#     });
#   "),
#   div(id = "my-fullpage",
#     div(class = "section",
#       actionButton("a", "a"),
#       h1("Section 1")
#     ),
#     div(class = "section",
#       h1("Section 2")
#     ),
#     div(class = "section",
#       h1("Section 3")
#     )
#   )
# )
tabPanel(
  "Introduce",
  value= "home_tabpanel",
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
        overflow-y: auto;
        overflow-x: hidden;

        justify-content: center; /* 水平居中 */
        align-items: center; /* 垂直居中 */
      }
      .pages {
        scroll-snap-align: start;
        height: 100vh;
        width: 100vw;
        transition: background-color 1s ease;
      }
      /*注意里面两组高和宽的定义都是vh和vw是填满窗口的意思*/
      /*scroll-snap滚屏方式是直接用CSS完成不需要用到JS代码或插件*/
      /*现在大部分浏览器都支持这种方式，除非老款IE浏览器。*/


      /*点的样式定义 */
      .dot {
        height: 8px;
        width: 8px;
        background-color: #bbb;
        border-radius: 50%;
        display: block; /* 使点垂直排列 */
        transition: background-color 0.6s ease, transform 0.6s ease;
        margin-bottom: 12px; /* 设置点之间的间距 */
      }
      .dot.active {
        background-color: #717171;
        transform: scale(2);
      }
      #scroll-dots {
        position: fixed;
        top: 50%;
        right: 30px;
        transform: translateY(-50%);
      }
      #dot1 {
        top: 45%;
      }
      #dot2 {
        top: 50%;
      }
      #dot3 {
        top: 55%;
      }
      #dot4 {
        top: 60%;
      }
      #dot5 {
        top: 65%;
      }

      .center {
        display: flex;
        justify-content: center;
        align-items: center;
        flex-direction: column;
        text-align: center;
        height: 100%;
        transform: translateY(-10%);
      }

      # .center img {
      #   max-height: 35vh;
      #   object-fit: contain;
      #   margin-top: -10vh;
      # }
      # .center h2 {
      #   margin-top: 30px;
      # }
      # body {
      #   transition: background-color 2s ease;
      #   background-color: #cdd1d3;
      # }

    /* Center the div horizontally */
      .text_div {
        display: flex;
        justify-content: center;
      }
      /* Set font size of p to 15px */
      .text_div p {
        text-align: justify;
        font-size: 20px;
        width: 700px;
      }

      #scroll-arrow {
        position: fixed;
        bottom: 50px;
        left: 50%;
        transform: translateX(-50%);
        height: 50px;
        width: 50px;
        background-color: rgba(128, 128, 128, 0.5);
        border-radius: 50%;
        display: flex;
        justify-content: center;
        align-items: center;
        cursor: pointer;
      }

      #scroll-arrow svg {
        fill: white;
      }

      .hidden {
        display: none;
      }

      @keyframes pulse {
        0% {
          opacity: 1;
          transform: scale(1);
        }
        50% {
          opacity: 0.5;
          transform: scale(1.25);
        }
        100% {
          opacity: 1;
          transform: scale(1);
        }
      }
      #scroll-arrow {
        animation: pulse 2s infinite;
      }

    "))
  ),
  div(class = "container",
    div(id = "page1", class = "pages",
      div(class = "center",
        div(
          img(style = "max-height: 35vh;object-fit: contain;margin-top: -5vh;",
            id="logo",
            src="https://raw.githubusercontent.com/duocang/images/master/PicGo/202307101446355.png"
          )
        ),
        h2("PMET", style="font-weight: bold;"),
        h2(""),
        h3("Find Co-Occurrences of TF Binding Site Motifs on Sequences"),
        h1(""),
        h1(""),
        div(id = "buttons",
          style = "display: flex; justify-content: center;",
          actionButton("jump_pmet_bnt", "Run job"          , style = "width: 150px;height:42px;font-weight:bold;margin-right:100px;margin-left:-20px;"),
          actionButton("jump_heat_bnt", "Visualize results", style = "width: 150px;height:42px;font-weight:bold;")
        )
      )
    ),
    div(id = "page2", class = "pages",
      div(class = "center",
        h2("Why Choose PMET?"),
        h2(""),
        h2(""),
        div(class = "text_div",
          p("PMET is a powerful tool designed to assist researchers in identifying the interactions
            of transcription factors (TFs) to regulate gene network. By studying the combinations
            of homotypic and heterotypic motifs within transcription regulatory modules, PMET
            provides a comprehensive framework for analyzing and understanding the functional
            implications and regulatory dynamics associated with motif interactions in gene expression.")
        ),
        div(class = "text_div",
          p("PMET is designed to address the limitations of traditional
            analysis tools by considering both homotypic and heterotypic motif
            combinations simultaneously.")
        ),
        div(class = "text_div",
          p("PMET is available in both command-line and web-based versions,
            providing flexibility and convenience to researchers.")
        )
      )
    ),
    div(id = "page3", class = "pages",
      div(class = "center",
        h2("How to Use PMET"),
        h2(""),
        h4("Run job", style = "font-weight: bold;"),
        div(style = "text-align: left;font-size: 20px;",
          p("Using PMET is intuitive and straightforward. Simply follow these steps:"),
          p("1. Select PMET Running Mode: PMET provides three running modes..."),
          p("2. Upload Gene File: Upload your gene file to PMET..."),
          p("3. Set Parameters: Adjust parameters as needed..."),
          p("After completing the steps above, you can initiate PMET for analysis.")
        ),
        h4("Visualization", style = "font-weight: bold;"),
        div(style = "text-align: left;width: 640px;font-size: 20px;",
          p("PMET also offers visualization tools to analyze the distribution of paired
            motifs on genes. It is often found that genes in different clusters exhibit
            enrichment for specific motif-pairs.")
        )
      )
    ),
    div(id = "page4", class = "pages",
      div(class = "center",
        h2("Functionality of PMET"),
        h2(""),
        div(class = "text_div",
          p(strong("Homotypic Clustering: "),"PMET can identify clusters
                    of homotypic motifs within the genome based on the motif
                    data provided by the user. This analysis helps uncover
                    the significance and functionality of motifs in gene regulation.")
        ),
        div(class = "text_div",
          p(strong("Heterotypic Clustering: "), "After identifying clusters of homotypic
                    motifs,PMET further analyzes the pairings between these clusters to
                    generate heterotypic clusters. Through this process, PMET reveals
                    the potential interactions between motifs in gene regulation.")
        )
      )
    ),
    div(id = "page5", class = "pages",
      div(class = "center",
        h1(""),
        h1(""),
        h3("Workflow of PMET compution"),
        div(#style = "display: flex; justify-content: center; align-items: center; flex-direction: column; height: 100%;",
          img(id="workflow",
              src="https://raw.githubusercontent.com/duocang/images/master/PicGo/202307202339573.png",
              style = "height: 75vh; width: auto;")
        )
      )
    ),
    tags$div(id = "scroll-arrow", class = "hidden breathe",
      tags$svg(
        xmlns="http://www.w3.org/2000/svg",
        width="50",
        height="50",
        viewBox="0 0 50 50",
        tags$line(x1="25", y1="14", x2="25", y2="40", style="stroke:white;stroke-width:5; stroke-linecap:round"),
        tags$line(x1="15", y1="30", x2="25", y2="40", style="stroke:white;stroke-width:5; stroke-linecap:round"),
        tags$line(x1="35", y1="30", x2="25", y2="40", style="stroke:white;stroke-width:5; stroke-linecap:round")
      )
    ),
    div(id="scroll-dots",
      tags$div( id = "dot1", class = "dot" ),
      tags$div( id = "dot2", class = "dot" ),
      tags$div( id = "dot3", class = "dot" ),
      tags$div( id = "dot4", class = "dot" ),
      tags$div( id = "dot5", class = "dot" )
    ),
    # 用于控制滚动点活动状态的JavaScript代码
    tags$script(HTML("

      $(document).ready(function() {
        // Check the initial state of the page
        var currentPageIndex = $('.dot.active').index('.dot') + 1;  // Get the index of the current active dot
        if (currentPageIndex !== $('.pages').length) {
          $('#scroll-arrow').removeClass('hidden');
        }

        $('#scroll-arrow').click(function() {
          var currentPageIndex = $('.dot.active').index('.dot') + 1;
          var nextPage = $('.pages').eq(currentPageIndex);
          if (nextPage.length > 0) {
            var nextScrollTop = $('.container').scrollTop() + $(window).height();
            $('.container').animate({
              scrollTop: nextScrollTop
            }, 500);
          }
        });

        $('.container').on('scroll', function() {
          var viewportHeight = $(window).height();
          var viewportWidth = $(window).width();
          var centerElement = document.elementFromPoint(viewportWidth / 2, viewportHeight / 2);
          var currentPage = $(centerElement).closest('.pages');
          var currentPageIndex = $(currentPage).index('.pages') + 1;

          $('.dot').removeClass('active');
          $('#dot' + currentPageIndex).addClass('active');

          // Switch the visibility of the arrow and the circle
          if (currentPageIndex === $('.pages').length) {
            $('#scroll-arrow').addClass('hidden');
          } else {
            $('#scroll-arrow').removeClass('hidden');
          }
        });
      });

      // Make the first dot active at the start
      $('#dot1').addClass('active');  //新增这一行

      $('.container').on('scroll', function() {
        var viewportHeight = $(window).height();
        var viewportWidth = $(window).width();
        var centerElement = document.elementFromPoint(viewportWidth / 2, viewportHeight / 2);
        var currentPage = $(centerElement).closest('.pages');
        var currentPageIndex = $(currentPage).index('.pages') + 1;

        $('.dot').removeClass('active');
        $('#dot' + currentPageIndex).addClass('active');
      });
    "))
  )
)
