#!/bin/bash

if [ true ]; then
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
    print_orange_no_br(){
        ORANGE='\033[0;33m'
        NC='\033[0m' # No Color
        printf "${ORANGE}$1${NC}"
    }

    print_fluorescent_yellow(){
        FLUORESCENT_YELLOW='\033[1;33m'
        NC='\033[0m' # No Color
        printf "${FLUORESCENT_YELLOW}$1${NC}\n"
    }
    print_fluorescent_yellow_no_br(){
        FLUORESCENT_YELLOW='\033[1;33m'
        NC='\033[0m' # No Color
        printf "${FLUORESCENT_YELLOW}$1${NC}"
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
fi

############################# 17. download homotypic data ##############################
if [ true ]; then
    data_path="data/indexing"

    print_orange "Data path: $data_path"
    urls=(
        "https://zenodo.org/record/8435321/files/Arabidopsis_thaliana.tar.gz"
        "https://zenodo.org/record/8435321/files/Brachypodium_distachyon.tar.gz"
        "https://zenodo.org/record/8435321/files/Brassica_napus.tar.gz"
        "https://zenodo.org/record/8435321/files/Glycine_max.tar.gz"
        "https://zenodo.org/record/8435321/files/Hordeum_vulgare_goldenpromise.tar.gz"
        "https://zenodo.org/record/8435321/files/Hordeum_vulgare_Morex_V3.tar.gz"
        "https://zenodo.org/record/8435321/files/Hordeum_vulgare_R1.tar.gz"
        "https://zenodo.org/record/8435321/files/Hordeum_vulgare_v082214v1.tar.gz"
        "https://zenodo.org/record/8435321/files/Medicago_truncatula.tar.gz"
        "https://zenodo.org/record/8435321/files/Oryza_sativa_indica_9311.tar.gz"
        "https://zenodo.org/record/8435321/files/Oryza_sativa_indica_IR8.tar.gz"
        "https://zenodo.org/record/8435321/files/Oryza_sativa_indica_MH63.tar.gz"
        "https://zenodo.org/record/8435321/files/Oryza_sativa_indica_ZS97.tar.gz"
        "https://zenodo.org/record/8435321/files/Oryza_sativa_japonica_Ensembl.tar.gz"
        "https://zenodo.org/record/8435321/files/Oryza_sativa_japonica_Kitaake.tar.gz"
        "https://zenodo.org/record/8435321/files/Oryza_sativa_japonica_Nipponbare.tar.gz"
        "https://zenodo.org/record/8435321/files/Oryza_sativa_japonica_V7.1.tar.gz"
        "https://zenodo.org/record/8435321/files/Solanum_lycopersicum.tar.gz"
        "https://zenodo.org/record/8435321/files/Solanum_tuberosum.tar.gz"
        "https://zenodo.org/record/8435321/files/Triticum_aestivum.tar.gz"
        "https://zenodo.org/record/8435321/files/Zea_mays.tar.gz"
        )

    mkdir -p $data_path
    # download and unzip
    for url in "${urls[@]}"; do
        filename=$(basename $url .tar.gz)
        print_orange "Downloading homotypic motifs hits of ${filename//_/ }"
        wget $url
        tar -xzvf  "$filename.tar.gz" -C data/indexing > /dev/null 2>&1
        rm "$filename.tar.gz"
    done
fi
