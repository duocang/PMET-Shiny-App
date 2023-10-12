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

echo ""
echo ""
print_middle "The purpose of this script is to                                      \n"
print_middle "  1. set email and CPU                                                  "
print_middle "  2. assign execute permissions to all users for bash and perl files    "
print_middle "  3. download data of homotypic motif hits of 21 speices                "
print_middle "  4. compile binaries needed by Shiny app                               "
print_middle "  5. install R package                                                  "
print_middle "  6. install python package                                           \n"
print_middle "Make sure you have correctly set up Shiny Server and Nginx              "
print_middle "                                                                    \n\n"


if [ -d .git ]; then
    git config core.fileMode false
fi



# ############################ 1. set email and CPU #############################
print_green "1. Configurations of email and CPU\n"

credential_path="data/email_credential.txt"

# 检查文件是否存在 Check if the file exists
if [[ ! -f "$credential_path" ]]; then
    touch "$credential_path"
    print_green "Creating 'data/email_credential.txt' for email dispatch."
    print_green "A one-time input is required and subsequently, no further attention is needed."
    print_green "This file will not be tracked by Git."
fi

# 检查文件是否包含两行内容 Check if the file contains two lines
line_count=$(wc -l < "$credential_path")

if [[ $line_count -ne 2 ]]; then
    if [[ $line_count -gt 0 ]]; then
        # 不为空但也不是两行，清空文件并显示错误信息 Not empty but not two lines either, clear the file and display error message.
        > "$credential_path"
        print_red "Error: $credential_path should contain exactly 2 lines (user name and password), but it contains $line_count."
    fi

    # 要求用户输入信息并将其存储到文件中 Ask the user to enter information and store it in a file
    echo "Please enter new email information: "
    read -p  "    User name: " username
    read -sp "    Password : " password
    echo

    # 存储信息到文件 Store information to file
    echo "$username" > "$credential_path"
    echo "$password" >> "$credential_path"
    # show message
    {
        read -r username
        read -r password
    } < "$credential_path"
    print_green "User name: $username"
    print_green "Password : $password"
else
    # 如果文件存在并且包含两行内容，显示内容 If the file exists and contains two lines, display the content
    {
        read -r username
        read -r password
    } < "$credential_path"

    print_green "Please check the credential for email:"

    echo "    User name: $username"
    echo "    Password : $password"

    print_fluorescent_yellow_no_br "Is the above information correct? [Y/n]: "
    read is_correct

    # Default to 'Y' if no input provided
    is_correct=${is_correct:-Y}

    # wrong email
    if [[ "$is_correct" != "y" && "$is_correct" != "Y" ]]; then
        > "$credential_path"
        # 要求用户输入信息并将其存储到文件中 Ask the user to enter information and store it in a file
        echo "Please enter the correct email information: "
        read -p  "User name: " username
        read -sp "Password : " password
        echo

        # 存储信息到文件
        echo "$username" > "$credential_path"
        echo "$password" >> "$credential_path"
        echo "Information stored successfully!"
    fi
fi




# Function to get user input for CPU number
get_cpu_number() {
    while true; do
        read -p "Please enter a number for CPU configuration: " cpu_number
        if [[ "$cpu_number" =~ ^[0-9]+$ ]]; then
            echo "$cpu_number" > "$file_path"
            echo "CPU number saved: $cpu_number"
            break
        else
            echo "Invalid input. Please enter a numeric value."
        fi
    done
}


file_path="data/cpu_configuration.txt"

# Check if the file exists; if not, create it and ask for user input
if [ ! -f "$file_path" ]; then
    print_fluorescent_yellow "$file_path does not exist. Creating it now..."
    get_cpu_number
else
    cpu_number=$(cat "$file_path")
    print_green "\nCPU: $cpu_number"
fi


# Ask user if they want to modify the CPU number
while true; do
    print_fluorescent_yellow_no_br "Do you want to modify the CPU number? [y/N]: "
    read modify

    modify=${modify:-N} # Default to 'N' if no input provided

    case "$modify" in
        [Yy]* )
            echo "Modifying the CPU number..."
            get_cpu_number
            break
            ;;
        [Nn]* )
            echo "Keeping the existing CPU configuration: $cpu_number"
            break
            ;;
        * )
            echo "Please answer yes (y) or no (n)."
            ;;
    esac
done




############################ 2. assign execute permissions #############################

print_green "\n2. Would you like to assign execute permissions to all users for bash and perl files? [Y/n]: "
read -p "" answer
answer=${answer:-Y} # Default to 'Y' if no input provided

if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
    # 遍历 PMETdev/scripts 目录及其所有子目录中的 .sh 和 .pl 文件
    find . -type f \( -name "*.sh" -o -name "*.pl" \) -exec chmod a+x {} \;
else
    print_fluorescent_yellow "No assignment"
fi





############################# 3. download homotypic data ##############################
current_dir=$(pwd)

# 拼接路径
data_path="${current_dir}/data/indexing"

# 询问用户是否开始下载
print_green "\n3. Would you like to download data of homotypic motif hits? [y/N]: "
print_green_no_br "Data path: $data_path"

read -p "" answer
answer=${answer:-N} # Default to 'N' if no input provided

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
    "https://zenodo.org/record/8435321/files/Zea_mays.tar.gz")


if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then

    mkdir -p data/indexing
    # 检查目录是否存在 Check if the directory exists
    if [ ! -d "$data_path" ]; then
        echo "Directory $data_path does not exist. Exiting script."
        exit 1
    fi

    # 检查目录是否为空 Check if the directory is empty
    if [ "$(find "$data_path" -mindepth 1 -maxdepth 1 -type d)" ]; then
        print_red "Directory data/indexing contains subdirectories.\n"

        # 提示用户是否要清空目录 Prompts the user if they want to empty the directory
        read -p "Do you want to clear the directory? [y/N]: " user_response

        # 判断用户响应并处理 Determine user response and process
        case $user_response in
            [yY])
                # delete all except .gitkeep
                find "$data_path" -mindepth 1 ! -name '.gitkeep' -exec rm -r {} +
                ;;
            *)
                echo "Exiting script."
                exit 1
                ;;
        esac
    fi

    # download and unzip
    for url in "${urls[@]}"; do
        filename=$(basename $url .tar.gz)
        print_fluorescent_yellow "Downloading homotypic motifs hits of ${filename//_/ }"

        wget $url
        tar -xzvf  "$filename.tar.gz" -C data/indexing
        rm "$filename.tar.gz"
    done
else
    print_fluorescent_yellow "No data downloaded"
fi


################################## 4. compile binary #################################

print_green_no_br "\n4. Would you like to compile binaries? [Y/n]:"
read -p " " answer
answer=${answer:-N} # Default to 'N' if no input provided

if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then

    cd PMETdev

    rm scripts/pmetindex
    rm scripts/pmetParallel_linux
    rm scripts/pmet
    rm scripts/fimo

    ############################# 4.1 fimo with pmet index ##############################
    print_fluorescent_yellow "Compiling FIMO with PMET homotopic (index) binary..."
    cd src/meme-5.5.3

    make distclean

    # update congifure files according to different system
    aclocal
    automake

    currentDir=$(pwd)
    echo $currentDir/build

    if [ -d "$currentDir/build" ]; then
        rm -rf "$currentDir/build"
    fi
    mkdir -p $currentDir/build

    # compile
    chmod a+x ./configure
    # 抑制输出，但仍想在出现错误时得到反馈 Suppress output, but still want feedback when errors occur.
    ./configure --prefix=$currentDir/build  --enable-build-libxml2 --enable-build-libxslt > /dev/null
    make > /dev/null
    make install > /dev/null
    cp build/bin/fimo ../../scripts/
    make distclean
    rm -rf build
    print_fluorescent_yellow "make distclean finished...\n"


    ################################### 4.2 pmetindex ####################################
    print_fluorescent_yellow "Compiling PMET homotopic (index) binary...\n"
    cd ../indexing
    chmod a+x build.sh
    bash build.sh
    mv bin/pmetindex ../../scripts/


    ################################## 4.3 pmetParallel ##################################
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


    # back to home directory
    cd ../../..

    ################### 4.4 Check if the compilation was successful ########################
    exists=""
    not_exists=""

    for file in PMETdev/scripts/pmetindex PMETdev/scripts/pmetParallel_linux PMETdev/scripts/pmet PMETdev/scripts/fimo; do
        if [ -f "$file" ]; then
            exists="$exists\n    $file"
        else
            not_exists="$not_exists\n    $file"
        fi
    done

    if [ ! -z "$exists" ]; then
        echo -e "\n\n"
        print_green "Compilation Success:$exists"
    fi
    if [ ! -z "$not_exists" ]; then
        echo -e "\n\n"
        print_red "Compilation Failure:$not_exists"
    fi

else
    print_fluorescent_yellow "No tools compiled"
fi

############# 4.5 Give execute permission to all users for the file. ##################
chmod a+x PMETdev/scripts/pmetindex
chmod a+x PMETdev/scripts/pmetParallel_linux
chmod a+x PMETdev/scripts/pmet
chmod a+x PMETdev/scripts/fimo

############################# 5. install R packages ##############################
print_green_no_br "\n5. Would you like to install R packages? [y/N]: "
# read -p "Would you like to install R packages? [y/N]: " answer
read -p " " answer
answer=${answer:-N} # Default to 'N' if no input provided

if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
    chmod a+x R/utils/install_packages.R
    Rscript R/utils/install_packages.R
else
    print_red "No R packages installed"
fi


############################# 6. install python packages ##############################
print_green_no_br "\n6. Would you like to install python packages? [y/N]: "
read -p " " answer
answer=${answer:-N} # Default to 'N' if no input provided

if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
    pip install numpy
    pip install pandas
    pip install scipy
    pip install bio
    pip install biopython
else
    print_fluorescent_yellow "No python packages installed"
fi
