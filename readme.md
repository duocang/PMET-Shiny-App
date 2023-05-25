

This is a Shiny app developed for PMET.

```shell
.
├── app.R       # start shiny app
├── global.R    # packages needed in shiny app
├── data        # results of FIMO, processed by PMETindex
├── module		# not used for now
├── result		# PMETresult
├── server		# server side of shiny
├── ui			# UI-side of hiny
├── utils		# functions and PMET (with source code)
├── www			# JS with D3 for heatmap, used in tab_heatmap.R
└── readme.md
```

### Setup Shiny server and nginx

Please follow [Shiny Server Deployment](https://cran.r-project.org/web/packages/ReviewR/vignettes/deploy_server.html) for more details.

**Shiny config**

Once Shiny Server is installed, you can access the Shiny Server welcome page by visiting your local IP address followed by port 3838 (127.0.0.1:3838 in your PC, if not in a server with a static IP ).

The configuration file for Shiny Server is located at `/etc/shiny-server/shiny-server.conf`. Various parameters can be modified in this file. By default, newly created Shiny app projects should be stored in `/srv/shiny-server`, allowing Shiny Server to access and render them as web pages.

You can either directly copy the `pmet` folder to `/srv/shiny-server` or create a link to it in that directory.

```bash
ln -s /home/shiny/pmet_nginx /srv/shiny-server
```

![](https://raw.githubusercontent.com/duocang/images/master/PicGo/202304181455329.png)

**nginx config**

Add the following in the end of `/etc/nginx/sites-enabled/default`

```shell
# vim /etc/nginx/sites-enabled/default
server {
        listen 127.0.0.1:84;
        server_name 127.0.0.1;
        location /result {
                alias /home/shiny/pmet_nginx/result;
        }
}
```
**Download function based on nginx**

After PMET calculation is completed, Shiny will generate a download button that is specifically for the PMET result archive. This functionality can be found in `utils/command_call_pmet.R` line 115.

```R
result_link <- paste0("http://127.0.0.1:84/result/", paste0(user_folder_name, ".zip"))
```



#### CPU

Currently, PMET uses 4 CPU cores by default. If you have abundant computing resources, you can modify the -t parameter in `utils/command_call_pmet.R`. It seems that 4 CPU cores should be sufficient for the performance.

<img src="https://raw.githubusercontent.com/duocang/images/master/PicGo/202304181500980.png" style="zoom: 50%;" />





### R packages

To avoid any inconvenience, I will provide you with the required R packages here.

```R
install.packages("devtools")
install.packages("remotes")
devtools::install_github("SymbolixAU/jsonify")
remotes::install_github("daattali/shinyjs")
devtools::install_github("carlganz/rintrojs")
remotes::install_github("RinteRface/fullPage")
remotes::install_github("dreamRs/shinyWidgets")
install.packages("shiny")mailR
install.packages("bslib")
 devtools::install_github("collectivemedia/tictoc")
install.packages("shinydashboard")
remotes::install_github("merlinoa/shinyFeedback", build_vignettes = TRUE)
devtools::install_github("jhrcook/ggasym")
devtools::install_github("haozhu233/kableExtra")
remotes::install_github("rstudio/shinyvalidate")
remotes::install_github("daattali/shinycssloaders")
install.packages('DT')
install.packages("tidyverse")
install.packages("zip")
install.packages("mailR")
devtools::install_github("kassambara/ggpubr")
```



```R
# Used packages
pacotes <- c(
    "tibble",
    "jsonify",
    "shinyjs",
    "openxlsx",
    "rintrojs",
    "fullPage",
    "shinyWidgets",
    "bslib",
    "tictoc",
    "shiny",
    "shinyBS",
    "shinydashboard",
    "shinythemes",
    "shinyvalidate",
    "shinycssloaders",
    "DT",
    "data.table",
    "tidyverse",
    "scales",
    "kableExtra",
    "dplyr",
    "reshape2",
    "ggpubr",
    "ggasym",
    "zip",
    "shinyFeedback",
    "promises",
    "future")
package.check <- lapply(pacotes, FUN = function(x) {
    if (!require(x, character.only = TRUE)) {
        install.packages(x, dependencies = TRUE)
    }
})
```

### PMET

If necessary, it is possible to compile pmet. The source code can be found in `utils/pmetParallel_src`.

```bash
g++  -g -Wall -std=c++11 main.cpp Output.cpp motif.cpp motifComparison.cpp -o pmetParallel -pthread
```

