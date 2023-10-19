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

echo -e "\n\n"
print_middle "The purpose of this script is to                                      \n"
print_middle "  1. set nginx link, email and CPU                                      "
print_middle "  2. assign execute permissions to all users for bash and perl files    "
print_middle "  3. download data of homotypic motif hits of 21 speices                "
print_middle "  4. compile binaries needed by Shiny app                               "
print_middle "  5. install R package                                                  "
print_middle "  6. install python package                                             "
print_middle "  7. install needed tools                                             \n"
print_middle "Make sure you have correctly set up Shiny Server and Nginx              "
print_middle "                                                                    \n\n"


if [ -d .git ]; then
    git config core.fileMode false
fi



# ############################ 1. set email and CPU #############################
print_green "1. Configurations of nginx link, email and CPU\n"

#################### 1.1 nginx
nginx_link="data/nginx_link.txt"

# 检查文件是否存在，并打印内容
if [ -f "$nginx_link" ]; then
    print_green_no_br "Nginx link: "
    cat "$nginx_link"
else
    print_red "$nginx_link does not exist."
fi

# 询问用户是否处于调试模式
print_fluorescent_yellow_no_br "Are you debugging? [y/N]: "
read debug_mode
debug_mode=${debug_mode:-N} # Default to 'N' if no input provided

if [[ "$debug_mode" =~ ^[Yy]$ ]]; then
    echo "http://pmet.online:84/result/" > "$nginx_link"
    echo "Updated $nginx_link with: http://pmet.online:84/result/"
else
    echo "https://bar.utoronto.ca/pmet_result/" > "$nginx_link"
    echo "New nginx lilnk: https://bar.utoronto.ca/pmet_result/"
fi


#################### 1.2 email
credential_path="data/email_credential.txt"

# 检查文件是否存在 Check if the file exists
if [[ ! -f "$credential_path" ]]; then
    touch "$credential_path"
    print_green "\nCreating 'data/email_credential.txt' for email dispatch."
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
    print_fluorescent_yellow "\nPlease enter new email information: "

    while true; do
        read -p  "    User name: " username
        # 如果用户名不为空，则跳出循环 If username is not empty, break the loop
        [[ -n "$username" ]] && break
        print_red "    User name cannot be empty. Please try again."
    done
    while true; do
        read -p "    Password : " password
        echo  # 添加一个新行，因为我们使用了-s参数 Add a newline because we used -s parameter
        # 如果密码不为空，则跳出循环 If password is not empty, break the loop
        [[ -n "$password" ]] && break
        print_red "    Password cannot be empty. Please try again."
    done
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

    print_green "\nPlease check the credential for email:"

    echo "    User name: $username"
    echo "    Password : $password"

    print_fluorescent_yellow_no_br "Is the above information correct? [Y/n]: "
    read is_correct
    is_correct=${is_correct:-Y} # Default to 'Y' if no input provided

    # wrong email
    if [[ "$is_correct" != "y" && "$is_correct" != "Y" ]]; then
        > "$credential_path"

        # 要求用户输入信息并将其存储到文件中 Ask the user to enter information and store it in a file
        echo "Please enter the correct email information: "
        while true; do
            read -p  "    User name: " username
            # 如果用户名不为空，则跳出循环 If username is not empty, break the loop
            [[ -n "$username" ]] && break
            print_red "    User name cannot be empty. Please try again."
        done
        while true; do
            read -p "    Password : " password
            echo  # 添加一个新行，因为我们使用了-s参数 Add a newline because we used -s parameter
            # 如果密码不为空，则跳出循环 If password is not empty, break the loop
            [[ -n "$password" ]] && break
            print_red "    Password cannot be empty. Please try again."
        done
        echo

        # 存储信息到文件
        echo "$username" > "$credential_path"
        echo "$password" >> "$credential_path"
        echo "Information stored successfully!"
    fi
fi

#################### 1.3 CPU

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
echo ""
print_green_no_br "2. Would you like to assign execute permissions to all users for bash and perl files? [Y/n]: "
read -p "" answer
answer=${answer:-Y} # Default to 'Y' if no input provided

if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
    print_orange "Assigning execute permissions..."
    # 遍历 PMETdev/scripts 目录及其所有子目录中的 .sh 和 .pl 文件
    find . -type f \( -name "*.sh" -o -name "*.pl" \) -exec chmod a+x {} \;
else
    print_orange "No assignment"
fi


############################# 3. download homotypic data ##############################
current_dir=$(pwd)

# 拼接路径
data_path="${current_dir}/data/indexing"

# 询问用户是否开始下载
echo ""
print_green_no_br "3. Would you like to download data of homotypic motif hits? [y/N]: "

read -p "" answer
answer=${answer:-N} # Default to 'N' if no input provided

print_orange "Data path: $data_path"

urls=(
    "http://pmet.online:84/result/Arabidopsis_thaliana.tar.gz"
    "http://pmet.online:84/result/Brachypodium_distachyon.tar.gz"
    "http://pmet.online:84/result/Brassica_napus.tar.gz"
    "http://pmet.online:84/result/Glycine_max.tar.gz"
    "http://pmet.online:84/result/Hordeum_vulgare_goldenpromise.tar.gz"
    "http://pmet.online:84/result/Hordeum_vulgare_Morex_V3.tar.gz"
    "http://pmet.online:84/result/Hordeum_vulgare_R1.tar.gz"
    "http://pmet.online:84/result/Hordeum_vulgare_v082214v1.tar.gz"
    "http://pmet.online:84/result/Medicago_truncatula.tar.gz"
    "http://pmet.online:84/result/Oryza_sativa_indica_9311.tar.gz"
    "http://pmet.online:84/result/Oryza_sativa_indica_IR8.tar.gz"
    "http://pmet.online:84/result/Oryza_sativa_indica_MH63.tar.gz"
    "http://pmet.online:84/result/Oryza_sativa_indica_ZS97.tar.gz"
    "http://pmet.online:84/result/Oryza_sativa_japonica_Ensembl.tar.gz"
    "http://pmet.online:84/result/Oryza_sativa_japonica_Kitaake.tar.gz"
    "http://pmet.online:84/result/Oryza_sativa_japonica_Nipponbare.tar.gz"
    "http://pmet.online:84/result/Oryza_sativa_japonica_V7.1.tar.gz"
    "http://pmet.online:84/result/Solanum_lycopersicum.tar.gz"
    "http://pmet.online:84/result/Solanum_tuberosum.tar.gz"
    "http://pmet.online:84/result/Triticum_aestivum.tar.gz"
    "http://pmet.online:84/result/Zea_mays.tar.gz")


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
        print_orange "Downloading homotypic motifs hits of ${filename//_/ }"

        wget $url
        tar -xzvf  "$filename.tar.gz" -C data/indexing
        rm "$filename.tar.gz"
    done
else
    print_orange "No data downloaded"
fi


################################## 4. compile binary #################################
echo ""
print_green_no_br "4. Would you like to compile binaries? [y/N]:"
read -p " " answer
answer=${answer:-N} # Default to 'N' if no input provided

if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then

    print_fluorescent_yellow "Compiling... It takes minutes."

    cd PMETdev

    rm -f scripts/pmetindex
    rm -f scripts/pmetParallel_linux
    rm -f scripts/pmet
    rm -f scripts/fimo

    ############################# 4.1 fimo with pmet index ##############################
    print_orange "Compiling FIMO with PMET homotopic (index) binary..."
    cd src/meme-5.5.3

    make distclean > /dev/null 2>&1

    # update congifure files according to different system
    aclocal  > /dev/null 2>&1
    automake > /dev/null 2>&1

    currentDir=$(pwd)
    echo $currentDir/build

    if [ -d "$currentDir/build" ]; then
        rm -rf "$currentDir/build"
    fi
    mkdir -p $currentDir/build

    # compile
    chmod a+x ./configure
    # 抑制输出，但仍想在出现错误时得到反馈 Suppress output, but still want feedback when errors occur.
    ./configure --prefix=$currentDir/build  --enable-build-libxml2 --enable-build-libxslt > /dev/null 2>&1
    make         > /dev/null 2>&1
    make install > /dev/null 2>&1
    cp build/bin/fimo ../../scripts/
    make distclean > /dev/null 2>&1
    rm -rf build
    # print_orange "make distclean finished...\n"


    ################################### 4.2 pmetindex ####################################
    print_orange "Compiling PMET homotopic (index) binary..."
    cd ../indexing
    chmod a+x build.sh
    bash build.sh > /dev/null 2>&1
    mv bin/pmetindex ../../scripts/
    rm -rf bin/*

    ################################## 4.3 pmetParallel ##################################
    print_orange "Compiling PMET heterotypic (pair) binary..."
    cd ../pmetParallel
    chmod a+x build.sh
    bash build.sh > /dev/null 2>&1
    mv bin/pmetParallel_linux ../../scripts/
    rm -rf bin/*

    # pmet
    print_orange "Compiling PMET heterotypic (pair) binary..."
    cd ../pmet
    chmod a+x build.sh
    bash build.sh  > /dev/null 2>&1
    mv bin/pmet ../../scripts/
    rm -rf bin/*

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
        echo -e "\n"
        print_green "Compilation Success:$exists"
    fi
    if [ ! -z "$not_exists" ]; then
        echo -e "\n"
        print_red "Compilation Failure:$not_exists"
    fi

else
    print_orange "No tools compiled"
fi

############# 4.5 Give execute permission to all users for the file. ##################
chmod a+x PMETdev/scripts/pmetindex
chmod a+x PMETdev/scripts/pmetParallel_linux
chmod a+x PMETdev/scripts/pmet
chmod a+x PMETdev/scripts/fimo

############################# 5. install R packages ##############################
echo ""
print_green_no_br "5. Would you like to install R packages? [y/N]: "
# read -p "Would you like to install R packages? [y/N]: " answer
read -p " " answer
answer=${answer:-N} # Default to 'N' if no input provided

if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
    print_orange "Installing R packages... It takes minutes."
    chmod a+x R/utils/install_packages.R
    Rscript R/utils/install_packages.R
else
    print_orange "No R packages installed"
fi


############################# 6. install python packages ##############################
echo ""
print_green_no_br "6. Would you like to install python packages? [y/N]: "
read -p " " answer
answer=${answer:-N} # Default to 'N' if no input provided

if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
    print_orange "Installing python packages... It takes minutes."
    pip install numpy     > /dev/null 2>&1 || echo "Failed to install numpy"
    pip install pandas    > /dev/null 2>&1 || echo "Failed to install pandas"
    pip install scipy     > /dev/null 2>&1 || echo "Failed to install scipy"
    pip install bio       > /dev/null 2>&1 || echo "Failed to install bio"
    pip install biopython > /dev/null 2>&1 || echo "Failed to install biopython"
else
    print_orange "No python packages installed"
fi


################################ 7. check needed tools #################################
echo ""
print_green "7. Checking the existence of GNU Parallel, bedtools, samtools and MEME Suite "
# List of tools to check
tools=("parallel" "bedtools" "samtools" "fimo")
missing_tools=()  # Initialize an empty array to store missing tools

# Assume all tools are installed until one is not found
all_tools_found=true

# Iterate over each tool and check if it is installed
for tool in "${tools[@]}"; do
    if ! command -v $tool &> /dev/null
    then
        print_red "$tool could not be found"
        all_tools_found=false

        missing_tools+=($tool)  # Add the missing tool to the array
        # Optionally exit or continue to check other tools
        # exit 1
    fi
done

# If all tools were found, print a positive message
if $all_tools_found; then
    print_green "All tools were found!"
else
    echo ""
    print_red "Please install them and rerun the script"

    echo ""
    print_fluorescent_yellow_no_br "Would you like to install missing tools? [Y/n]: "
    read -p " " answer
    answer=${answer:-Y} # Default to 'N' if no input provided

    if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
        # # Install the missing tools
        # print_red "The following tools are missing:"
        for tool in "${missing_tools[@]}"; do
            if [ "$tool" == "parallel" ]; then
                sudo apt-get install parallel
                parallel --citation
            fi
            if [ "$tool" == "bedtools" ]; then
                if [[ "$(uname)" == "Darwin" ]]; then
                    brew install bedtools
                elif [[ -f /etc/os-release ]]; then
                    . /etc/os-release
                    case $ID in
                        centos|fedora|rhel)
                            yum install BEDTools
                            ;;
                        debian|ubuntu)
                            apt-get update && apt-get install bedtools
                            ;;
                        *)
                            echo "Unsupported Linux distribution"
                            ;;
                    esac
                else
                    echo "Unsupported OS"
                fi
            fi

            if [ "$tool" == "samtools" ]; then
                mkdir -p ./tools

                cd ./tools
                wget https://github.com/samtools/samtools/releases/download/1.17/samtools-1.17.tar.bz2
                tar -xjf samtools-1.17.tar.bz2

                cd samtools-1.17
                ./configure --prefix=$(pwd)
                make
                make install

                echo "export PATH=$(pwd)/bin:\$PATH" >> ~/.bashrc
                source ~/.bashrc

                cd ..
                rm samtools-1.17.tar.bz2
            fi


            if [ "$tool" == "fimo" ]; then
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
            fi
        done
    fi
fi

print_green "\nDONE"
