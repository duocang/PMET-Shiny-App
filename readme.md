This is a Shiny app developed for PMET.

[www.PMET.online](http://pmet.online/)

![](www/figures/logo.png)

## 1. File tree

```shell
.
├── conf                        * # configure for shiny server and nginx
├── data
├── dockerfiles
├── PMETdev
├── indexing
├── R
│   ├── app.R
│   ├── global.R
│   ├── module
│   ├── server
│   ├── ui
│   └── utils
├── result
├── www
├── 01_deploy_via_Docker.sh
├── 01_deploy_via_singularity.sh  * # Recommended installation method
├── app.R                         * # Shiny app
├── docker-compose.yml
├── PMET-Shiny-App.Rproj
└── readme.md
```

## 2. Quick deployment

### 2.1 (option one) Install on Docker (Recommended)

```bash
bash 01_deploy_via_singularity.sh
```

### 2.2 (option two) Bash install on current Debian-like OS

```bash
bash 01_deploy_via_Docker.sh
```

### 2.3 (discarded) Bash install on current Debian-like OS

1. Install `Shiny Server` and `Nginx` [[details](#setup-shiny-server-and-nginx)]

2. `git clone` in the folder of Shiny Server (default: `/srv/shiny-server`) or git clone anywhere and then create a link under `/srv/shiny-server` as shown below:
   ![](https://raw.githubusercontent.com/duocang/images/master/PicGo/202309191728114.png)

3. Run `01_deploy_via_bash.sh`

        ```
        bash archive/01_deploy_via_bash.sh
        ```

   - 1. set email and CPU

   - 2. assign execute permissions

   - 3. download data of homotypic motif hits of 21 speices [[details](#index-data)]

   - 4. compile binaries needed by Shiny app [[details](#compile)]

   - 5. install R packages

   - 6. install python packages

   - 7. Install tools (`GNU Parallel`, `bedtools`, `samtools`, `MEME`...)[[details](#tools)]


    ![](https://raw.githubusercontent.com/duocang/images/master/PicGo/202310190148145.png)

---

**If not necessary, there is no need to read the following content.**

---

## <span id="index-data">3. Pre-computed homotypic motif hits of plant species (PMET indexing data)</span>

Given that the PMET indexing calculation takes a very long time, we have already performed pre-calculation for some plants and several common plant transcription factor databases.

The data can be accessed by running the script `deploy_one_bash.sh` from [Homotypic motifs from 5 databases in the promoters of 21 plant species](https://zenodo.org/record/8435321).

```bash
bash deploy_one_bash.sh


```shell
# file tree
data/indexing
|-- Arabidopsis_thaliana                      # species
│   |-- CIS-BP2                               # motif database
│   |-- Franco-Zorrilla_et_al_2014            # motif database
│   |-- Jaspar_plants_non_redundant_2022      # motif database
│   |-- PlantTFDB                             # motif database
│   |-- Plant_Cistrome_DB                     # motif database
│   `-- universe.txt                          # complete gene list
|-- Brachypodium_distachyon
|-- Brassica_napus
|-- Glycine_max
|-- Hordeum_vulgare
|-- Hordeum_vulgare_Morex_V3
|-- Hordeum_vulgare_R1
|-- Hordeum_vulgare_goldenpromise
|-- Hordeum_vulgare_v082214v1
|-- Medicago_truncatula
|-- Oryza_sativa_indica_9311
|-- Oryza_sativa_indica_IR8
|-- Oryza_sativa_indica_MH63
|-- Oryza_sativa_indica_ZS97
|-- Oryza_sativa_japonica_Ensembl
|-- Oryza_sativa_japonica_Kitaake
|-- Oryza_sativa_japonica_Nipponbare
|-- Oryza_sativa_japonica_V7.1
|-- Solanum_lycopersicum
|-- Solanum_tuberosum
|-- Triticum_aestivum
`-- Zea_mays
```

In the future, if there are more plants or new databases to be added to the shiny app, we just need to copy the new indexing results to the indexing directory. the PMET shiny app will automatically recognize the new additions without the need to change the code.

## <span id="compile">4. PMET index and pair compile</span>

There are a few tools that need to be compiled before deploying the Shiny app, and we provide a script that does all the work.
If you don't really want to know the details, you can just run the following script.

```bash
cd PMETdev

chmod a+x binary_compile.sh

bash binary_compile.sh
```

After compilation, the executable will be saved in the `PMETdev/scripts` directory for the Shiny app to call.

## <span id="setup-shiny-server-and-nginx">5. Shiny server and nginx</span>

**5.1 Shiny-server and nginx install**

Please follow [Shiny Server Deployment](https://cran.r-project.org/web/packages/ReviewR/vignettes/deploy_server.html) for more details.

**5.2 Shiny config**

Once Shiny Server is installed, you can access the Shiny Server welcome page by visiting your local IP address followed by port 3838 (127.0.0.1:3838 in your PC, if not in a server with a static IP ).

The configuration file for Shiny Server is located at `/etc/shiny-server/shiny-server.conf`. Various parameters can be modified in this file. By default, newly created Shiny app projects should be stored in `/srv/shiny-server`, allowing Shiny Server to access and render them as web pages.

You can either directly copy the `pmet` folder to `/srv/shiny-server` or create a link to it in that directory.

```bash
ln -s /home/shiny/pmet_nginx /srv/shiny-server
```

![](https://raw.githubusercontent.com/duocang/images/master/PicGo/202304181455329.png)

**5.3 nginx config**

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

## PMET workflow

![](www/figures/pmet_workflow_with_interval_option.png)

[GitHub Ribbons](https://github.blog/2008-12-19-github-ribbons/)
[GitHub Corners](https://tholman.com/github-corners/)