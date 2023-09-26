#!/bin/bash

print_red(){
    RED='\033[0;31m'
    NC='\033[0m' # No Color
    printf "${RED}$1${NC}\n"
}

print_green(){
    GREEN='\033[0;32m'
    NC='\033[0m' # No Color
    printf "${GREEN}$1${NC}\n"
}

print_green_no_br(){
    GREEN='\033[0;32m'
    NC='\033[0m' # No Color
    printf "${GREEN}$1${NC}"
}

print_orange(){
    ORANGE='\033[0;33m'
    NC='\033[0m' # No Color
    printf "${ORANGE}$1${NC}\n"
}

print_fluorescent_yellow(){
    FLUORESCENT_YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
    printf "${FLUORESCENT_YELLOW}$1${NC}\n"
}

print_white(){
    WHITE='\033[1;37m'
    NC='\033[0m' # No Color
    printf "${WHITE}$1${NC}"
}

print_middle(){
    FLUORESCENT_YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
    # 获取终端的宽度
    COLUMNS=$(tput cols)
    # 遍历每一行
    while IFS= read -r line; do
        # 计算需要的空格数来居中文本
        padding=$(( (COLUMNS - ${#line}) / 2 ))
        printf "%${padding}s" ''
        printf "${FLUORESCENT_YELLOW}${line}${NC}\n"
    done <<< "$1"
}

echo ""
echo ""
print_middle "The purpose of this script is to                         \n"
print_middle "  1. download data of homotypic motif hits of 21 speices   "
print_middle "  2. compile binaries needed by Shiny app                  "
print_middle "  3. install R package                                   \n"
print_middle "Make sure you have correctly set up Shiny Server and Nginx "
print_middle "                                                       \n\n"


############################# download homotypic dat ##############################
# 询问用户是否开始下载
print_green_no_br "Would you like to download data of homotypic motif hits? (Y/yes to confirm): "
read -p "" answer

urls=(
    "https://zenodo.org/record/8221143/files/Arabidopsis_thaliana.7z"
    "https://zenodo.org/record/8221143/files/Brachypodium_distachyon.7z"
    "https://zenodo.org/record/8221143/files/Brassica_napus.7z"
    "https://zenodo.org/record/8221143/files/Glycine_max.7z"
    "https://zenodo.org/record/8221143/files/Hordeum_vulgare_goldenpromise.7z"
    "https://zenodo.org/record/8221143/files/Hordeum_vulgare_Morex_V3.7z"
    "https://zenodo.org/record/8221143/files/Hordeum_vulgare_R1.7z"
    "https://zenodo.org/record/8221143/files/Hordeum_vulgare_v082214v1.7z"
    "https://zenodo.org/record/8221143/files/Medicago_truncatula.7z"
    "https://zenodo.org/record/8221143/files/Oryza_sativa_indica_9311.7z"
    "https://zenodo.org/record/8221143/files/Oryza_sativa_indica_IR8.7z"
    "https://zenodo.org/record/8221143/files/Oryza_sativa_indica_MH63.7z"
    "https://zenodo.org/record/8221143/files/Oryza_sativa_indica_ZS97.7z"
    "https://zenodo.org/record/8221143/files/Oryza_sativa_japonica_Ensembl.7z"
    "https://zenodo.org/record/8221143/files/Oryza_sativa_japonica_Kitaake.7z"
    "https://zenodo.org/record/8221143/files/Oryza_sativa_japonica_Nipponbare.7z"
    "https://zenodo.org/record/8221143/files/Oryza_sativa_japonica_V7.1.7z"
    "https://zenodo.org/record/8221143/files/Solanum_lycopersicum.7z"
    "https://zenodo.org/record/8221143/files/Solanum_tuberosum.7z"
    "https://zenodo.org/record/8221143/files/Triticum_aestivum.7z"
    "https://zenodo.org/record/8221143/files/Zea_mays.7z")


if [ "$answer" == "Y" ] || [ "$answer" == "yes" ]; then

    read -p "Do you have p7zip-full installed? (Y/yes to confirm): " answer
    if [ "$answer" == "Y" ] || [ "$answer" == "yes" ]; then
        mkdir -p data/indexing

        for url in "${urls[@]}"; do
            filename=$(basename $url .7z)
            print_fluorescent_yellow "Downloading homotypic motifs hits of ${filename//_/ }"

            wget $url
            7za x "$filename.7z" -odata/indexing
            rm "$filename.7z"
        done
    else
        print_red "Please install p7zip-full first!"
        exit 1
    fi
else
    print_red "No data download"
fi


################################## compile binary #################################

print_green_no_br "\nWould you like to compile binaries? (Y/yes to confirm):"
read -p " " answer

if [ "$answer" == "Y" ] || [ "$answer" == "yes" ]; then

    cd PMETdev

    rm scripts/pmetindex
    rm scripts/pmetParallel_linux
    rm scripts/pmet
    rm scripts/fimo

    ############################# fimo with pmet index ##############################
    print_fluorescent_yellow "Compiling FIMO with PMET homotopic (index) binary..."
    cd src/meme-5.5.3

    make distclean

    currentDir=$(pwd)
    echo $currentDir/build

    if [ -d "$currentDir/build" ]; then
        rm -rf "$currentDir/build"
    fi

    mkdir -p $currentDir/build

    chmod a+x ./configure
    ./configure --prefix=$currentDir/build  --enable-build-libxml2 --enable-build-libxslt
    make
    make install
    cp build/bin/fimo ../../scripts/
    make distclean
    rm -rf build
    print_fluorescent_yellow "make distclean finished...\n"


    ################################### pmetindex ####################################
    print_fluorescent_yellow "Compiling PMET homotopic (index) binary...\n"
    cd ../indexing
    chmod a+x build.sh
    bash build.sh
    mv bin/pmetindex ../../scripts/


    ################################## pmetParallel ##################################
    print_fluorescent_yellow "Compiling PMET heterotypic (pair) binary...\n"
    cd ../pmetParallel
    chmod a+x build.sh
    bash build.sh
    mv bin/pmetParallel_linux ../../scripts/

    # pmet
    print_fluorescent_yellow "Compiling PMET heterotypic (pair) binary...\n"
    cd ../pmet
    chmod a+x build.sh
    bash build.sh
    mv bin/pmet ../../scripts/



    cd ../../
    pwd
    ################### Check if the compilation was successful ########################
    exists=""
    not_exists=""

    for file in scripts/pmetindex scripts/pmetParallel_linux scripts/pmet scripts/fimo; do
        if [ -f "$file" ]; then
            exists="$exists $file"
        else
            not_exists="$not_exists $file"
        fi
    done

    if [ ! -z "$exists" ]; then
        echo
        echo
        echo
        print_green "Compilation Success:$exists"
    fi


    if [ ! -z "$not_exists" ]; then
        echo
        echo
        echo
        print_red "Compilation Failure:$not_exists"
    fi


    ############# Give execute permission to all users for the file. ##################
    chmod a+x scripts/pmetindex
    chmod a+x scripts/pmetParallel_linux
    chmod a+x scripts/pmet
    chmod a+x scripts/fimo

    # print_green "\n\npmet, pmetParallel_linux, pmetindex and NEW fimo are ready in 'scripts' folder.\n"

    print_green "DONE"
else
    print_red "No data download"
fi

############################# install R packages ##############################
print_green_no_br "\nWould you like to install R packages? (Y/yes to confirm): "
# read -p "Would you like to install R packages? (Y/yes to confirm): " answer
read -p " " answer


if [ "$answer" == "Y" ] || [ "$answer" == "yes" ]; then
    chmod a+x R/utils/install_packages.R
    Rscript R/utils/install_packages.R
else
    print_red "Not to install R packages"
fi