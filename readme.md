This is a Shiny app developed for PMET.

![](www/figures/logo.png)

## 1. File tree

```shell
.
├── PMETdev              # PMET/PMET_index (C/C++ source code)
├── R                    # R code of Shiny app
│   ├── app.R            # integrate all UIs and Servers
│   ├── global.R         # packages and configs needed in shiny app
│   ├── module           # modulaity of UIs, shiny heatmap (ggplot) and data-table view
│   ├── server           # server side of shiny
│   ├── ui               # UI-side of shiny
│   └── utils            # R functions
├── data                 # demo data for PMETindex and PMET
│   ├── indexing         # Pre-computed homotypic motif hits
├── result               # result of Shiny app
│   ├── indexing         # newly generated homotypic motif hits as user requested
├── www                  # JS with D3 for heatmap, used in tab_visualize.R
├── PMET-Shiny-App.Rproj # project file for RStudio (development only)
├── app.R                # start shiny app (Run with Rscript app.R, development only)
└── readme.md
```

## 2. Quick deploy

1. Install tools [[details](#tools)]
2. Install and configure Shiny Server and Nginx correctly [[details](#setup-shiny-server-and-nginx)]
3. `git clone` in the folder of Shiny Server (default: `/srv/shiny-server`)![](https://raw.githubusercontent.com/duocang/images/master/PicGo/202309191728114.png)
4. Run `deploy_one_bash.sh`
   - set email and CPU
   - assign execute permissions
   - download data of homotypic motif hits of 21 speices [[details](#index-data)]
   - compile binaries needed by Shiny app [[details](#compile)]
   - install R packages
   - install python packages
     
     ```bash
     bash deploy_one_bash.sh
     ```

## <span id="index-data">3. Pre-computed homotypic motif hits of plant species (PMET indexing data)</span>

Given that the PMET indexing calculation takes a very long time, we have already performed pre-calculation for some plants and several common plant transcription factor databases.

The data can be accessed by running the script `deploy_one_bash.sh` from [Homotypic motifs from 4 databases in the promoters of 21 plant species](https://zenodo.org/record/8221143).

```bash
bash deploy_one_bash.sh
```

```shell
# file tree
data/indexing
|-- Arabidopsis_thaliana                      # species
│   |-- CIS-BP2                               # motif database
│   |-- Franco-Zorrilla_et_al_2014
│   |-- Jaspar_plants_non_redundant_2022
│   |-- PlantTFDB
│   `-- universe.txt
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

## <span id="setup-shiny-server-and-nginx">Setup 5. Shiny server and nginx</span>

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

After PMET calculation is completed, Shiny will generate a download button that is specifically for the PMET result archive. This functionality can be found in `utils/command_call_pmet.R` line 12.

```R
result_link <- paste0("http://127.0.0.1:84/result/", paste0(pmetPair_path_name, ".zip"))
```

## <span id="tools">6. Tools needed</span>

**6.1 Install GNU Parallel**

GNU Parallel helps PMET index (FIMO and PMET index) to run in parallel mode.

```bash
sudo apt-get install parallel

# Put GNU Parallel silent
parallel --citation
```



**6.2 Install The MEME Suite (FIMO and fasta-get-markov)**

```bash
# cd a folder you want to put the software
wget https://meme-suite.org/meme/meme-software/5.5.2/meme-5.5.2.tar.gz

tar zxf meme-5.5.2.tar.gz
cd meme-5.5.2
./configure --prefix=$HOME/meme --enable-build-libxml2 --enable-build-libxslt
make
make test
make install
```

Add following into bash profile file.

```bash
# assuming you put meme folder under your home folder
export PATH=$HOME/meme/bin:$HOME/meme/libexec/meme-5.5.2:$PATH
```

**6.3 Install samtools**

Install from conda or mamba:

```bash
conda install -c bioconda samtools
```

Install from source:

> assuming you create a directory named `samtools` in home directory (~) and install samtools there.

```bash
wget https://github.com/samtools/samtools/releases/download/1.17/samtools-1.17.tar.bz2

cd samtools-1.17    # and similarly for bcftools and htslib
./configure --prefix=$HOME/samtools
make
make install

# Add following into bash profile file or .zshrc (if zsh used).
# assuming you put samtools-1.17 folder under your home folder
export PATH=$HOME/samtools/bin:$PATH
```

**6. 4 Install bedtools**

```bash
conda install -c bioconda bedtools
```

or

```bash
# Debian/Ubuntu
apt-get install bedtools
# Fedora/Centos
yum install BEDTools
```

or

```bash
wget https://github.com/arq5x/bedtools2/releases/download/v2.29.1/bedtools-2.29.1.tar.gz
tar -zxvf bedtools-2.29.1.tar.gz
cd bedtools2
make
```

![](www/figures/pmet_workflow_with_interval_option.png)

[GitHub Ribbons](https://github.blog/2008-12-19-github-ribbons/)
[GitHub Corners](https://tholman.com/github-corners/)