This is a Shiny app developed for PMET.

![](www/figures/logo.png)

## 1. File tree

```shell
.
├── PMETdev
├── R
│   ├── app.R
│   ├── global.R
│   ├── module
│   ├── server
│   ├── ui
│   └── utils
├── data
│   ├── indexing
├── deploy_one_bash.sh    *    # ONLY to run this bash to deploy
├── result
├── www
├── PMET-Shiny-App.Rproj
├── app.R
└── readme.md
```

## 2. Quick deployment

1. Install `Shiny Server` and `Nginx` [[details](#setup-shiny-server-and-nginx)]
2. `git clone` or `git pull` in the folder of Shiny Server (default: `/srv/shiny-server`)![](https://raw.githubusercontent.com/duocang/images/master/PicGo/202309191728114.png)

3. Run `deploy_one_bash.sh`

   - 1. set email and CPU
   - 2. assign execute permissions
   - 3. download data of homotypic motif hits of 21 speices [[details](#index-data)]
   - 4. compile binaries needed by Shiny app [[details](#compile)]
   - 5. install R packages
   - 6. install python packages
   - 7. Install tools (`GNU Parallel`, `bedtools`, `samtools`, `MEME`...)[[details](#tools)]
   ```bash
    bash deploy_one_bash.sh
   ```
   ![](https://raw.githubusercontent.com/duocang/images/master/PicGo/202310190148145.png)

## <span id="index-data">3. Pre-computed homotypic motif hits of plant species (PMET indexing data)</span>

Given that the PMET indexing calculation takes a very long time, we have already performed pre-calculation for some plants and several common plant transcription factor databases.

The data can be accessed by running the script `deploy_one_bash.sh` from [Homotypic motifs from 5 databases in the promoters of 21 plant species](https://zenodo.org/record/8435321).

```bash
bash deploy_one_bash.sh

# ...
# 3. Would you like to download data of homotypic motif hits? [y/N]: Y
```

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

## <span id="setup-shiny-server-and-nginx">Setup 5. Shiny server and nginx</span>

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

<!-- **Download function based on nginx**

After PMET calculation is completed, Shiny will generate a download button that is specifically for the PMET result archive. This functionality can be found in `utils/command_call_pmet.R` line 12.

```R
result_link <- paste0("http://127.0.0.1:84/result/", paste0(pmetPair_path_name, ".zip"))
``` -->

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
mkdir -p ./tools

cd ./tools
wget https://meme-suite.org/meme/meme-software/5.5.2/meme-5.5.2.tar.gz
tar zxf meme-5.5.2.tar.gz

cd meme-5.5.2
./configure --prefix=$(pwd) --enable-build-libxml2 --enable-build-libxslt
make
make install

echo "export PATH=$(pwd)/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc
cd ..
rm meme-5.5.2.tar.gz
```


**6.3 Install samtools**
Install from conda or mamba:

```bash
conda install -c bioconda samtools
```

Install from source:

```bash
mkdir -p ./tools

cd ./tools
wget https://github.com/samtools/samtools/releases/download/1.17/samtools-1.17.tar.bz2
tar -xjf samtools-1.17.tar.bz2

cd samtools-1.17
./configure --prefix=$(pwd)
make
make install
# Add following into bash profile file or .zshrc (if zsh used).
echo "export PATH=$(pwd)/bin:\$PATH" >> ~/.bashrc
source ~/.bashrc

cd ..
rm samtools-1.17.tar.bz2
```

**6. 4 Install bedtools**
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