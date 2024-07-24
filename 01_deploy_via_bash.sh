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

# sudo -i

# sudo apt -y install zsh
# # 将 Zsh 设置为默认 Shell
# chsh -s /bin/zsh
# wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
# git clone https://github.com/bhilburn/powerlevel9k.git ~/.oh-my-zsh/custom/themes/powerlevel9k
# git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# plugins=(
#     git zsh-autosuggestions zsh-syntax-highlighting
# )

# POWERLEVEL9K_MODE='nerdfont-complete'
# ZSH_THEME="powerlevel9k/powerlevel9k"
# COMPLETION_WAITING_DOTS="true"
# alias s="source ~/.zshrc"
# alias c='clear'

if [ true ]; then
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
fi

############################# 1. Adding some necessary dependencies #####################################
if [ true ]; then
    print_green "\n1.Adding some necessary dependencies, please wait a moment..."
    print_orange_no_br "  Do you want to install Ubuntu dependencies? [y/N]: "
    read dependency
    dependency=${dependency:-N} # Default to 'N' if no input provided

    if [ "$dependency" == "Y" ] || [ "$dependency" == "y" ]; then
        print_orange "Installing dependencies..."

        sudo apt update && sudo apt upgrade -y
        sudo apt -y install openjdk-21-jdk

        # export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
        # export PATH=$PATH:$JAVA_HOME/bin
        # 询问用户是否处于调试模式

        sudo add-apt-repository -y ppa:alex-p/tesseract-ocr-devel  > /dev/null 2>&1 || print_red "    Failed to add ppa:alex-p/tesseract-ocr-devel"
        sudo apt -y install zip                 > /dev/null 2>&1 || print_red "    Failed to install zip"
        sudo apt -y install build-essential     > /dev/null 2>&1 || print_red "    Failed to install build-essential"
        sudo apt -y install zlib1g-dev          > /dev/null 2>&1 || print_red "    Failed to install zlib1g-dev"
        sudo apt -y install libgdbm-dev         > /dev/null 2>&1 || print_red "    Failed to install libgdbm-dev"
        sudo apt -y install autotools-dev       > /dev/null 2>&1 || print_red "    Failed to install autotools-dev"
        sudo apt -y install automake            > /dev/null 2>&1 || print_red "    Failed to install automake"
        sudo apt -y install nodejs              > /dev/null 2>&1 || print_red "    Failed to install nodejs"
        sudo apt -y install npm                 > /dev/null 2>&1 || print_red "    Failed to install npm"
        sudo apt -y install libxml2-dev         > /dev/null 2>&1 || print_red "    Failed to install libxml2-dev"
        sudo apt -y install libxml2             > /dev/null 2>&1 || print_red "    Failed to install libxml2"
        sudo apt -y install libxslt-dev         > /dev/null 2>&1 || print_red "    Failed to install libxslt-dev"
        sudo apt -y install cmake               > /dev/null 2>&1 || print_red "    Failed to install cmake"
        sudo apt -y install libjpeg-dev         > /dev/null 2>&1 || print_red "    Failed to install libjpeg-dev "
        sudo apt -y install librsvg2-dev        > /dev/null 2>&1 || print_red "    Failed to install librsvg2-dev"
        sudo apt -y install libpoppler-cpp-dev  > /dev/null 2>&1 || print_red "    Failed to install libpoppler-cpp-dev"
        sudo apt -y install freetype2-demos     > /dev/null 2>&1 || print_red "    Failed to install freetype2-demos"
        sudo apt -y install cargo               > /dev/null 2>&1 || print_red "    Failed to install cargo"
        sudo apt -y install libharfbuzz-dev     > /dev/null 2>&1 || print_red "    Failed to install libharfbuzz-dev"
        sudo apt -y install libfribidi-dev      > /dev/null 2>&1 || print_red "    Failed to install libfribidi-dev"
        sudo apt -y install libtesseract-dev    > /dev/null 2>&1 || print_red "    Failed to install libtesseract-dev"
        sudo apt -y install libleptonica-dev    > /dev/null 2>&1 || print_red "    Failed to install libleptonica-dev"
        sudo apt -y install tesseract-ocr-eng   > /dev/null 2>&1 || print_red "    Failed to install libfribidi-dev"
        sudo apt -y install libmagick++-dev     > /dev/null 2>&1 || print_red "    Failed to install libmagick++-dev"
        sudo apt -y install libavfilter-dev     > /dev/null 2>&1 || print_red "    Failed to install libavfilter-dev"
        sudo apt -y install libncurses5-dev     > /dev/null 2>&1 || print_red "    Failed to install libncurses5-dev"
        sudo apt -y install libncursesw5-dev    > /dev/null 2>&1 || print_red "    Failed to install libncursesw5-dev"
        sudo apt -y install libbz2-dev          > /dev/null 2>&1 || print_red "    Failed to install libbz2-dev"
        sudo apt -y install libpcre2-dev        > /dev/null 2>&1 || print_red "    Failed to install libpcre2-dev"
        sudo apt -y install libreadline-dev     > /dev/null 2>&1 || print_red "    Failed to install libreadline-dev"
        sudo apt -y install libssl-dev          > /dev/null 2>&1 || print_red "    Failed to install libssl-dev"

        echo "deb http://security.ubuntu.com/ubuntu focal-security main" | sudo tee /etc/apt/sources.list.d/focal-security.list
        sudo apt update
        sudo apt -y install libssl1.1             > /dev/null 2>&1 || print_red "    Failed to install libssl1.1"
        sudo apt -y install libcurl4-openssl-dev  > /dev/null 2>&1 || print_red "    Failed to install libcurl4-openssl-dev"
        sudo apt -y install libopenblas-dev       > /dev/null 2>&1 || print_red "    Failed to install libopenblas-dev"
        sudo apt -y install gfortran              > /dev/null 2>&1 || print_red "    Failed to install gfortran"
        sudo update-alternatives --config libblas.so.3-$(arch)-linux-gnu
        sudo apt -y install ufw > /dev/null 2>&1 || print_red "    Failed to install ufw"
    else
        print_fluorescent_yellow "    No Ubuntu dependencies installed"
    fi

    # 检查 R 是否已安装
    if ! command -v R >/dev/null 2>&1; then
        print_green "  R is not installed. Installing R..."

        tool_dir=R-4.3.2
        tool_link=https://cran.rstudio.com/src/base/R-4/R-4.3.2.tar.gz

        wget $tool_link          > /dev/null 2>&1 || echo "    Failed to download R tar file"
        tar -xzvf R-4.3.2.tar.gz > /dev/null 2>&1 || echo "    Failed to unzip tar file"
        rm R-4.3.2.tar.gz

        cd $tool_dir
        ./configure                    \
            --prefix=/opt/R/$tool_dir  \
            --enable-R-shlib=yes        \
            --enable-memory-profiling  \
            --with-blas                \
            --with-lapack              \
            --with-readline=yes        \
            --with-x=no  > /dev/null 2>&1 || echo "    Failed to install configure"

        make              > /dev/null 2>&1 || echo "    Failed to make"
        sudo make install > /dev/null 2>&1 || echo "    Failed to make install"

        sudo ln -s /opt/R/$tool_dir/bin/R /usr/local/bin/R
        sudo ln -s /opt/R/$tool_dir/bin/Rscript /usr/local/bin/Rscript
        cd ..
        rm -rf $tool_dir

    else
        print_green "    R is already installed."
    fi

    # 检查 rstudio-server 是否已安装
    if ! dpkg -l | grep -qw rstudio-server; then
        print_green "  rstudio-server not installed. Installing..."
        sudo apt-get install gdebi-core  > /dev/null 2>&1 || print_red "    Failed to install gdebi-core"
        wget https://download2.rstudio.org/server/focal/amd64/rstudio-server-2023.12.1-402-amd64.deb > /dev/null 2>&1
        sudo gdebi rstudio-server-2023.12.1-402-amd64.deb
        rm -rf rstudio-server-2023.12.1-402-amd64.deb
        # sudo rstudio-server start
        # sudo rstudio-server stop
        # sudo rstudio-server restart
        # sudo rstudio-server status
        # /etc/rstudio/rserver.conf
        # /etc/rstudio/rsession.conf
    else
        print_green "    rstudio-server is already installed."
    fi

    # 检查 shiny-server 是否已安装
    if ! dpkg -l | grep -qw shiny-server; then
        print_green "  shiny-server not installed. Installing..."
        Rscript -e 'install.packages("shiny", repos="https://cran.rstudio.com/", Ncpus=4)' > /dev/null 2>&1
        wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.21.1012-amd64.deb > /dev/null 2>&1
        sudo gdebi shiny-server-1.5.21.1012-amd64.deb > /dev/null 2>&1
        rm shiny-server-1.5.21.1012-amd64.deb
        # sudo systemctl start shiny-server
        # sudo systemctl enable shiny-server
        # sudo systemctl restart shiny-server.service
        # cat /var/log/shiny-server.log
        # /etc/shiny-server/shiny-server.conf
    else
        print_green "    shiny-server is already installed."
    fi

    # 检测并安装 python3
    if ! dpkg -l | grep -q "^ii\s*python3\s"; then
        print_green "  Installing python3..."
        sudo apt -y install python3 > /dev/null 2>&1 || print_red "    Failed to install python3"
    else
        print_green "    python3 is already installed."
    fi
    # 检测并安装 python3-pip
    if ! dpkg -l | grep -q "^ii\s*python3-pip\s"; then
        print_green "  Installing python3-pip..."
        sudo apt -y install python3-pip > /dev/null 2>&1 || print_red "    Failed to install python3-pip"
    else
        print_green "    python3-pip is already installed."
    fi

    # 检测并安装 nginx
    if ! dpkg -l | grep -q "^ii\s*nginx\s"; then
        print_green "  Installing nginx..."
        sudo apt -y install nginx   > /dev/null 2>&1 || print_red "    Failed to install nginx"
        print_green "Configuring nginx..."
        sudo ufw allow 'Nginx HTTP' > /dev/null 2>&1 || print_red "    Failed to ufw allow 'Nginx HTTP' "
        sudo systemctl enable nginx > /dev/null 2>&1 || print_red "    Failed to systemctl start nginx"
        sudo systemctl start nginx  > /dev/null 2>&1 || print_red "    Failed to systemctl start nginx"
    else
        print_green "    nginx is already installed."
    fi
    # sudo systemctl restart nginx
    # sudo systemctl reload nginx
fi

# ########################### 2. set email and CPU ######################################################
if [ true ]; then
    print_green "\n2. Configurations of nginx link, email and CPU\n"
    #################### 2.1 nginx
    print_green "2.1. Configurations of nginx for result folder"
    nginx_link="data/nginx_link.txt"
    # 文件存在且部位空，并打印内容 The file exists and the location is empty, and the content is printed.
    if [ -f "$nginx_link" ] && [ -s "$nginx_link" ]; then
        print_orange "  Check your nginx link in $nginx_link"
        print_fluorescent_yellow_no_br "    Nginx link: "
        cat "$nginx_link"
        echo
        while true; do
            print_orange_no_br "  Do you have a new nginx link for result? [y/N]: "
            read debug_mode
            debug_mode=${debug_mode:-N} # Default to 'N' if no input provided
            # 检查用户输入是否为 Y, y, N, 或 n
            if [[ "$debug_mode" =~ ^[YyNn]$ ]]; then
                # 如果用户输入 N 或 n，则使用默认链接
                if [[ "$debug_mode" =~ ^[Nn]$ ]]; then
                    break  # 退出循环
                else
                    # 用户输入 Y 或 y，请求新的链接并更新
                    rm -f "$nginx_link"  # 删除原有文件
                    print_fluorescent_yellow_no_br "  Please enter a new link of result for nginx:"
                    read user_link
                    echo "$user_link" > "$nginx_link"  # 写入新链接
                    echo "    New nginx link: $user_link"
                    echo "    You can always change nginx link in $nginx_link"
                    break  # 退出循环
                fi
            else
                print_red "    Invalid input. Please enter Y/y for yes or N/n for no."
            fi
        done
    else # data/nginx_link.txt not exist
        print_red "    $nginx_link does not exist or is empty. Creating $nginx_link..."
        print_red "    Example of nginx link: https://www.pmet.online/result/"

        rm -f "$nginx_link"  # 删除原有文件
        print_fluorescent_yellow_no_br "    Please enter a new link of result for nginx:"
        read user_link
        echo "$user_link" > "$nginx_link"  # 写入新链接
        echo "    New nginx link: $user_link"
        echo "    You can always change nginx link in $nginx_link"
    fi


    #################### 2.2 email
    print_green "\n2.2. Configurations of email to send results"
    # print_fluorescent_yellow "\nPlease enter a new email"
    credential_path="data/email_credential.txt"

    # 初始化 file_flag 为 F，表示默认情况下文件状态为不满足条件
    file_flag="F"
    # 检查文件是否存在且行数为 5
    if [[ -f "$credential_path" ]] && [[ $(wc -l < "$credential_path") -eq 5 ]]; then
        print_orange "  Please check your email credential in $credential_path"
        # 读取文件内容到变量
        readarray -t lines < "$credential_path"
        username="${lines[0]}"
        password="${lines[1]}"
        address="${lines[2]}"
        smtp_link="${lines[3]}"
        ssl_port="${lines[4]}"
        # 展示信息
        echo "    User name (email): $username"
        echo "    Password         : $password"
        echo "    Address          : $address"
        echo "    SMTP Link        : $smtp_link"
        echo "    SSL Port         : $ssl_port"

        # 询问信息是否正确
        print_orange_no_br "  Is this information correct? (Y/n): "
        read confirmation
        confirmation=${confirmation:-Y}  # 如果用户没有输入任何内容，则将 confirmation 设置为 'Y'
        if [[ "$confirmation" =~ ^[Yy]$ ]]; then
            file_flag="T"
            # print_green "    Information confirmed."
        else
            file_flag="F"
            # print_red "    Information marked as incorrect."
        fi
    else
        file_flag="F"
        print_red "    Credential file is missing or does not contain exactly 5 lines."
    fi

    # 根据 file_flag 做进一步操作
    if [[ "$file_flag" == "F" ]]; then
        print_orange "  Please provide the required information."
        rm -rf "$credential_path"
        touch "$credential_path"
        # 循环直到输入非空的用户名
        while true; do
            read -p "    User name (email): " username
            # 检查用户名是否非空
            if [[ -z "$username" ]]; then
                print_red "    Email (User name) cannot be empty. Please try again."
            else
                break  # 用户名非空，跳出循环
            fi
        done
        # 循环直到输入非空的密码
        while true; do
            read -p "    Password : " password
            if [[ -z "$password" ]]; then
                print_red "    Password cannot be empty. Please try again."
            else
                break  # 密码非空，跳出循环
            fi
        done
        # 循环直到输入非空的address
        while true; do
            read -p "    Address (email): " address
            # 检查用户名是否非空
            if [[ -z "$address" ]]; then
                print_red "    Address (email) cannot be empty. Please try again."
            else
                break  # 用户名非空，跳出循环
            fi
        done
        # 接收并验证 SMTP 链接
        while true; do
            read -p "    SMTP link: " smtp_link
            if [[ -n "$smtp_link" ]]; then
                break
            else
                print_red "    SMTP link cannot be empty. Please try again."
            fi
        done
        # 接收并验证 SSL 端口号
        while true; do
            read -p "    SSL Port  : " ssl_port
            if [[ -n "$ssl_port" ]] && [[ "$ssl_port" -ne 0 ]]; then
                break
            else
                print_red "    SSL Port cannot be zero or empty. Please try again."
            fi
        done
        echo

        # 存储信息到文件 Store information to file
        echo "$username"  >> "$credential_path"
        echo "$password"  >> "$credential_path"
        echo "$address"   >> "$credential_path"
        echo "$smtp_link" >> "$credential_path"
        echo "$ssl_port"  >> "$credential_path"
        # show message
        {
            read -r username
            read -r password
            read -r address
            read -r smtp_link
            read -r ssl_port
        } < "$credential_path"
        print_green "    User name: $username"
        print_green "    Password : $password"
        print_green "    Address  : $address"
        print_green "    User name: $smtp_link"
        print_green "    Password : $ssl_port"
    fi

    #################### 2.3 CPU
    print_green "\n2.3. Configurations of CPU number"
    # Function to get user input for CPU number
    get_cpu_number() {
        while true; do
            print_fluorescent_yellow_no_br "  Please enter a number for CPU configuration: "
            read -p "" cpu_number
            if [[ "$cpu_number" =~ ^[0-9]+$ ]]; then
                echo "$cpu_number" > "$file_path"
                print_green "    CPU number: $cpu_number"
                break
            else
                print_red "  Invalid input. Please enter a numeric value."
            fi
        done
    }

    file_path="data/cpu_configuration.txt"

    # Check if the file exists; if not, create it and ask for user input
    if [ ! -f "$file_path" ] || [ ! -s "$file_path" ]; then
        rm -rf $file_path
        get_cpu_number
    else
        cpu_number=$(cat "$file_path")
        print_orange "  Check your CPU number in $file_path"
        print_green "    Number of CPUs: $cpu_number"

        # Ask user if they want to modify the CPU number
        while true; do
            print_orange_no_br "  Do you want to modify the CPU number? [y/N]: "
            read modify

            modify=${modify:-N} # Default to 'N' if no input provided
            case "$modify" in
                [Yy]* )
                    get_cpu_number
                    break
                    ;;
                [Nn]* )
                    # echo "Keeping the existing CPU configuration: $cpu_number"
                    break
                    ;;
                * )
                    echo "Please answer yes (y) or no (n)."
                    ;;
            esac
        done
    fi
fi

############################# 3. assign execute permissions to bash #####################################
if [ true ]; then
    echo ""
    print_green_no_br "3. Would you like to assign execute permissions? [Y/n]: "
    read -p "" answer
    answer=${answer:-Y} # Default to 'Y' if no input provided

    if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
        print_orange "    Assigning execute permissions..."
        # 遍历 PMETdev/scripts 目录及其所有子目录中的 .sh 和 .pl 文件
        find . -type f \( -name "*.sh" -o -name "*.pl" \) -exec chmod a+x {} \;
    else
        print_orange "  No assignment"
    fi
fi

############################# 4. compile binary (pmet) ##################################################
if [ true ]; then
    print_green "\n4. Compile binaries of PMET and PMETindex..."

    if [ -f "PMETdev/scripts/pmetindex" ]; then
        chmod a+x PMETdev/scripts/pmetindex
        chmod a+x PMETdev/scripts/pmetParallel_linux
        chmod a+x PMETdev/scripts/pmet
        chmod a+x PMETdev/scripts/fimo
        while true; do
            print_orange_no_br "  Do you want to recompile PMET and PMETindex? [y/N]: "
            read -p " " recompile
            recompile=${recompile:-N} # Default to 'N' if no input provided
            # 检查用户输入是否为 Y, y, N, 或 n
            if [[ "$recompile" =~ ^[YyNn]$ ]]; then
                break  # 如果输入有效，跳出循环
            else
                print_red "    Invalid input. Please enter Y/y for yes or N/n for no."
            fi
        done
    else
        print_red "  PMETindex and PMET not found. Compiling PMETindex..."
        recompile=y
    fi

    # print_orange_no_br "  Do you want to stop PMET and PMETindex compile? [y/N]: "
    # read -p "" recompile_stop
    # recompile_stop=${recompile_stop:-Y}

    # if [[ "$recompile" =~ ^[Yy]$ && ! "$recompile_stop" =~ ^[Nn]$ ]]; then
    if [[ "$recompile" =~ ^[Yy]$ ]]; then
        print_fluorescent_yellow "  Compiling... It takes minutes."

        cd PMETdev
        rm -f scripts/pmetindex
        rm -f scripts/pmetParallel_linux
        rm -f scripts/pmet
        rm -f scripts/fimo

        ############################# 4.1 fimo with pmet index ##############################
        # print_orange "    Compiling FIMO with PMET homotopic (index) binary..."
        cd src/meme-5.5.3

        make distclean > /dev/null 2>&1 #|| print_red "    Failed to make distclean"
        aclocal        > /dev/null 2>&1 || print_red "    Failed to aclocal "
        automake       > /dev/null 2>&1 || print_red "    Failed to automake"

        currentDir=$(pwd)
        if [ -d "$currentDir/build" ]; then
            rm -rf "$currentDir/build"
        fi
        mkdir -p $currentDir/build

        chmod a+x ./configure
        # 抑制输出，但仍想在出现错误时得到反馈 Suppress output, but still want feedback when errors occur.
        ./configure \
            --prefix=$currentDir/build \
            --enable-build-libxml2 \
            --enable-build-libxslt > /dev/null 2>&1 || print_red "    Failed to configure"
        make           > /dev/null 2>&1 || print_red "    Failed to make"
        make install   > /dev/null 2>&1 || print_red "    Failed to make install"
        cp build/bin/fimo ../../scripts/
        make distclean > /dev/null 2>&1 || print_red "    Failed to make distclean"
        rm -rf build

        ################################### 4.2 pmetindex ####################################
        # print_orange "    Compiling PMET homotopic (index) binary..."
        cd ../indexing
        chmod a+x build.sh
        bash build.sh > /dev/null 2>&1
        mv bin/pmetindex ../../scripts/

        ################################## 4.3 pmetParallel ##################################
        # print_orange "Compiling PMET heterotypic (pair) binary..."
        cd ../pmetParallel
        chmod a+x build.sh
        bash build.sh > /dev/null 2>&1
        mv bin/pmetParallel_linux ../../scripts/

        # pmet
        # print_orange "Compiling PMET heterotypic (pair) binary..."
        cd ../pmet
        chmod a+x build.sh
        bash build.sh  > /dev/null 2>&1
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
            print_green "    Compilation Success:$exists"
        fi
        if [ ! -z "$not_exists" ]; then
            print_red "     Compilation Failure:$not_exists"
        fi
    else
        echo "  No tools compiled"
    fi
    ############# 4.5 Give execute permission to all users for the file. ##################
    chmod a+x PMETdev/scripts/pmetindex
    chmod a+x PMETdev/scripts/pmetParallel_linux
    chmod a+x PMETdev/scripts/pmet
    chmod a+x PMETdev/scripts/fimo
fi

############################# 5. install R packages #####################################################
if [ true ]; then
    echo ""
    print_green_no_br "5. Would you like to install R packages? [y/N]: "
    # read -p "Would you like to install R packages? [y/N]: " answer
    read -p "" answer
    answer=${answer:-N} # Default to 'N' if no input provided

    if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
        # 使用 R 脚本检查 rJava 是否已安装
        if ! Rscript -e "if (!requireNamespace('rJava', quietly = TRUE)) {quit(status = 1)}"; then
            # echo "rJava is not installed. Installing..."
            # 重新配置 Java 环境
            sudo R CMD javareconf                                         > /dev/null 2>&1
            curl -LO https://rforge.net/rJava/snapshot/rJava_1.0-6.tar.gz > /dev/null 2>&1
            tar fxz rJava_1.0-6.tar.gz                                    > /dev/null 2>&1
            R CMD INSTALL rJava                                           > /dev/null 2>&1 || print_red "    Failed to install rJava"
            rm rJava_1.0-6.tar.gz
            rm -rf rJava
        fi

        print_orange "Installing R packages... It takes minutes..."
        chmod a+x R/utils/install_packages.R
        # Rscript R/utils/install_packages.R
        Rscript R/utils/install_packages.R 2>&1 | tee ./R/R_packages_installation.log | grep -E "\* DONE \("
        awk '/The installed packages are as follows:/{flag=1} flag' ./R/R_packages_installation.log
    else
        echo "  No R packages installed"
    fi
fi

############################# 6. install python packages ################################################
if [ true ]; then
    print_green_no_br "\n6. Would you like to install python packages? [y/N]: "
    read -p " " answer
    answer=${answer:-N} # Default to 'N' if no input provided

    if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
        print_orange "    Installing python packages... It takes minutes."
        pip install leidenalg     > /dev/null 2>&1 || print_red "    Failed to install leidenalg"
        pip install python-igraph > /dev/null 2>&1 || print_red "    Failed to install numpy"
        pip install numpy         > /dev/null 2>&1 || print_red "    Failed to install python-igraph"
        pip install pandas        > /dev/null 2>&1 || print_red "    Failed to install pandas"
        pip install scipy         > /dev/null 2>&1 || print_red "    Failed to install scipy"
        pip install bio           > /dev/null 2>&1 || print_red "    Failed to install bio"
        pip install biopython     > /dev/null 2>&1 || print_red "    Failed to install biopython"
    else
        echo "  No python packages installed"
    fi
fi

############################# 7. copy pmet folder to /home/shiny ########################################
if [ true ]; then
    source_dir="$(dirname "$(realpath "$0")")"
    target_dir="/home/shiny/pmet"

    print_green_no_br "\n7. Moving "
    print_fluorescent_yellow_no_br "$source_dir"
    print_green_no_br " to "
    print_fluorescent_yellow_no_br "$target_dir"
    print_green " for User shiny access..."

    # print_green "\n7. Moving directory from $source_dir to $target_dir for User shiny access..."
    print_orange_no_br "  Do you want to proceed with this operation? [y/N]: "
    read -p "" answer
    answer=${answer:-N}
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        sudo cp -R "$source_dir" "$target_dir"
    fi
fi

############################# 8. put shiny user into suder list #########################################
if [ true ]; then
    # # 提高新用户权限
    # # echo 'wang ALL=(ALL:ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/wang_nopasswd > /dev/null
    # # # echo 'wang ALL=(ALL:ALL) NOPASSWD: ALL' 生成了一行 sudo 配置规则。
    # # # sudo tee /etc/sudoers.d/wang_nopasswd 以超级用户权限执行 tee 命令，将上述规则写入 /etc/sudoers.d/wang_nopasswd 文件。使用 /etc/sudoers.d/ 目录是一种更好的做法，因为这允许您管理单独的 sudo 规则文件，而不是修改主 /etc/sudoers 文件。
    # # # > /dev/null 部分将 tee 命令的标准输出重定向到 /dev/null，这样就不会在终端中显示被添加的规则。

    print_green "\n8. Adding user 'shiny' to the sudo group."
    print_orange_no_br "  Do you want to proceed with this operation? [Y/n]: "
    read -p " " user_confirm
    user_confirm=${user_confirm:-Y}  # 默认值为 'Y'

    if [[ "$user_confirm" =~ ^[Yy]$ ]]; then
        sudo usermod -aG sudo shiny
        print_fluorescent_yellow "  User 'shiny' has been added to the sudo group."
    fi
fi

############################# 9. set password for shiny user ############################################
if [ true ]; then
    print_green "\n9. Checking if the 'shiny' user has a password set."

    # 检查 shiny 用户是否有密码设置
    if ! sudo passwd -S shiny | grep -q ' P '; then
        print_orange "  Would you like to set a password for the 'shiny' user now? [Y/n]":
        read -p " " user_confirm
        user_confirm=${user_confirm:-Y}  # 默认值为 'Y'

        if [[ "$user_confirm" =~ ^[Yy]$ ]]; then
            # print_orange "  Setting password for the 'shiny' user. Please follow the prompts..."
            sudo chsh -s /bin/bash shiny  # 更改默认 shell 为 bash
            sudo passwd shiny  # 设置密码
            print_fluorescent_yellow "  A password has been set for the user 'shiny'."
        fi
    else
        echo "  User 'shiny' has a password set. No action required."
    fi
fi

############################ 10. creating group shiny-apps ##############################################
if [ true ]; then
    print_green "\n10. Checking for the existence of the 'shiny-apps' group..."

    # 检查组是否存在
    if getent group shiny-apps >/dev/null; then
        echo "  Group 'shiny-apps' exists. No action required."
    else
        print_orange "  Would you like to create the 'shiny-apps' group? [Y/n]: "
        read -p " " user_confirm
        user_confirm=${user_confirm:-Y}  # 默认值为 'Y'

        if [[ "$user_confirm" =~ ^[Yy]$ ]]; then
            sudo groupadd shiny-apps
            print_fluorescent_yellow "    The 'shiny-apps' group has been successfully created."
        fi
    fi
fi

############################ 11. adding shiny to group shiny-apps #######################################
if [ true ]; then
    print_green "\n11. Checking if the 'shiny' user is already a member of the 'shiny-apps' group."

    # 检查用户是否已经是该组的成员
    if groups shiny | grep -qw shiny-apps; then
        echo "  User 'shiny' has been a member of 'shiny-apps'. No action required."
    else
        print_orange "  Would you like to add 'shiny' to the 'shiny-apps' group? [Y/n]: "
        read -p " " user_confirm
        user_confirm=${user_confirm:-Y}  # 默认值为 'Y'

        if [[ "$user_confirm" =~ ^[Yy]$ ]]; then
            sudo usermod -aG shiny-apps shiny
            print_fluorescent_yellow "  User 'shiny' has been successfully added to the 'shiny-apps' group."
        fi
    fi
fi


############################ 12. shiny's ownership of /homne/shiny/pmet and /srv/shiny-server ###########
if [ true ]; then
    print_green_no_br "\n12. Adjust ownership and permissions of "
    print_fluorescent_yellow_no_br "'/home/shiny/pmet'"
    print_green_no_br " and "
    print_fluorescent_yellow "'/srv/shiny-server'"

    echo "    to ensure proper access for the 'shiny' user and the 'shiny-apps' group."


    print_orange_no_br "  Do you want to proceed with this operation? [Y/n]: "
    read -p " " user_confirm
    user_confirm=${user_confirm:-Y}  # 默认值为 'Y'

    if [[ "$user_confirm" =~ ^[Yy]$ ]]; then
        sudo chown -R shiny:shiny-apps /srv/shiny-server
        sudo chmod g+w /srv/shiny-server
        sudo chmod g+s /srv/shiny-server

        print_orange "  Updating ownership for '$target_dir' and its contents..."
        sudo chown -R shiny:shiny-apps "$target_dir"

        print_fluorescent_yellow "    Ownership and permissions have been successfully updated."
    fi
fi

############################ 13. assign access of pmet/result to nginx  #################################
if [ true ]; then
    # # 出于安全考虑，依赖于 777 权限并不是一个好的做法
    # sudo chmod -R 777 $current_dir/result

    nginx_user=$(ps -o user= -C nginx | grep -v root | sort -u)

    # 确保获取到的 nginx 用户不为空
    if [[ -n "$nginx_user" ]]; then
        print_green_no_br "\n13. Granting Nginx user '$nginx_user' access to the 'shiny-apps' group for accessing "
        print_fluorescent_yellow "/home/shiny/pmet/result"
        # 向用户询问是否执行
        print_orange_no_br "  Do you want to proceed with this operation? [y/N]: "
        read -p " " user_confirmation

        if [[ "$user_confirmation" =~ ^[Yy]$ ]]; then
            # 用户确认，执行操作
            echo "Adding Nginx user '$nginx_user' to the 'shiny-apps' group..."
            sudo usermod -aG shiny-apps "$nginx_user"
            echo "Nginx user '$nginx_user' has been successfully added to the 'shiny-apps' group."
        fi
    else
        print_red "\n13. No non-root Nginx user found. No action required."
        print_orange "    Check /home/shiny/pmet/result folder permissions and ownership manually."
    fi

    if [ true ]; then
        # print_orange "  Assigning writing permissions to result/ and result/indexing directory..."
        print_green_no_br "\n  Assigning writing permissions to "
        print_fluorescent_yellow_no_br "/home/shiny/pmet/result"
        print_green_no_br " and "
        print_fluorescent_yellow "/home/shiny/pmet/result/indexing"

        sudo chmod 777 /home/shiny/pmet/result
        sudo chmod 777 /home/shiny/pmet/result/indexing
    fi
fi


############################ 14. create folder link ######################################################
print_green "\n14. Creating a symlink for /home/shiny/pmet in /srv/shiny-server"
print_orange_no_br "  Do you want to proceed with this operation? [y/N]: "
read -p " " user_confirmation
user_confirmation=${user_confirmation:-N} # 默认为 'N' 如果没有提供输入

if [[ "$user_confirmation" =~ ^[Yy]$ ]]; then
    sudo ln -sf "$target_dir" /srv/shiny-server/pmet
    sudo chown -R shiny:shiny-apps /srv/shiny-server/pmet
    print_green "    Link created and ownership changed successfully."
fi


############################ 15. check needed tools #####################################################
if [ true ]; then
    print_green "\n15. Checking the execution of GNU Parallel, bedtools, samtools and MEME Suite under 'shiny' user"
    tools=("parallel --version" "bedtools --version" "samtools --version" "fimo -h") # List of tools and their version check commands
    missing_tools=()  # Initialize an empty array to store tools that cannot be executed
    all_tools_found=true

    # Iterate over each tool and check if it can be executed under 'shiny' user
    for tool_cmd in "${tools[@]}"; do
        tool=${tool_cmd%% *}  # Extract the tool name from the command
        # Use 'sudo -u shiny' to execute the tool command as 'shiny' user
        if ! sudo -u shiny bash -c "$tool_cmd" &> /dev/null
        then
            print_red "    $tool could not be executed under 'shiny' user"
            all_tools_found=false
            missing_tools+=($tool)  # Add the tool to the array
        fi
    done

    # If all tools were found, print a positive message
    if $all_tools_found; then
        print_orange "    All tools were found!"
    else
        print_orange_no_br "  Would you like to install missing tools? [Y/n]: "
        read -p " " answer
        answer=${answer:-Y} # Default to 'N' if no input provided

        if [ "$answer" == "Y" ] || [ "$answer" == "y" ]; then
            # Install the missing tools
            for tool in "${missing_tools[@]}"; do
                if [ "$tool" == "parallel" ]; then
                    sudo apt-get -y install parallel > /dev/null 2>&1 || print_red "    Failed to install parallel"
                    parallel --citation              > /dev/null 2>&1 || print_red "    Failed to run parallel --citation"
                fi
                if [ "$tool" == "bedtools" ]; then
                    if [[ "$(uname)" == "Darwin" ]]; then
                        brew install bedtools > /dev/null 2>&1 || print_red "    Failed to install bedtools"
                    elif [[ -f /etc/os-release ]]; then
                        . /etc/os-release
                        case $ID in
                            centos|fedora|rhel)
                                yum install BEDTools  > /dev/null 2>&1 || print_red "    Failed to install bedtools"
                                ;;
                            debian|ubuntu)
                                sudo apt update               > /dev/null 2>&1 || print_red "    Failed to apt update"
                                sudo apt -y install bedtools  > /dev/null 2>&1 || print_red "    Failed to install bedtools"
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
                    # 创建 /home/shiny/tools 目录，如果运行脚本的用户不是 shiny，则需要修改路径
                    mkdir -p /home/shiny/tools

                    tool_dir=samtools-1.17
                    tool_link=https://github.com/samtools/samtools/releases/download/1.17/samtools-1.17.tar.bz2

                    # 下载并解压 samtools
                    wget $tool_link -O $tool_dir.tar.bz2 > /dev/null 2>&1 || echo "    Failed to download samtools tar file"
                    tar -xjf $tool_dir.tar.bz2           > /dev/null 2>&1 || echo "    Failed to unzip tar file"
                    rm $tool_dir.tar.bz2

                    # 进入 samtools 目录并编译
                    cd $tool_dir && mkdir -p build
                    ./configure --prefix=$(pwd)/build    > /dev/null 2>&1 || echo "    Failed to configure"
                    make                                 > /dev/null 2>&1 || echo "    Failed to make"
                    sudo make install                    > /dev/null 2>&1 || echo "    Failed to make install"

                    # 返回到原始目录并将 samtools 目录移动到 /home/shiny/tools 下
                    cd ..
                    mv $tool_dir /home/shiny/tools/

                    # 更新 /home/shiny/.bashrc 和 /home/shiny/.zshrc，添加 samtools 到 PATH
                    echo "export PATH=/home/shiny/tools/$tool_dir/build/bin:\$PATH" >> /home/shiny/.bashrc
                    echo "export PATH=/home/shiny/tools/$tool_dir/build/bin:\$PATH" >> /home/shiny/.zshrc
                    echo "export PATH=/home/shiny/tools/$tool_dir/build/bin:\$PATH" >> /home/shiny/.bash_profile
                    sudo chown -R shiny:shiny-apps /home/shiny/tools/$tool_dir/build/
                    print_green "    samtools successfully installed"
                fi

                if [ "$tool" == "fimo" ]; then
                    mkdir -p /home/shiny/tools

                    tool_dir=meme-5.5.2
                    tool_link=https://meme-suite.org/meme/meme-software/5.5.2/meme-5.5.2.tar.gz

                    wget $tool_link           > /dev/null 2>&1 || print_red "    Failed to download fimo tar file"
                    tar zxf meme-5.5.2.tar.gz > /dev/null 2>&1 || print_red "    Failed to unzip tar file"
                    rm meme-5.5.2.tar.gz

                    # 进入 samtools 目录并编译
                    cd $tool_dir && mkdir -p build
                    ./configure                \
                        --prefix=$(pwd)/build  \
                        --enable-build-libxml2 \
                        --enable-build-libxslt > /dev/null 2>&1 || echo "    Failed to install configure"
                    make                       > /dev/null 2>&1 || print_red "    Failed to make"
                    make install               > /dev/null 2>&1 || print_red "    Failed to make install"

                    cd ..
                    mv $tool_dir /home/shiny/tools/

                    echo "export PATH=/home/shiny/tools/$tool_dir/build/bin:\$PATH"                >> /home/shiny/.bashrc
                    echo "export PATH=/home/shiny/tools/$tool_dir/build/bin:\$PATH"                >> /home/shiny/.zshrc
                    echo "export PATH=/home/shiny/tools/$tool_dir/build/bin:\$PATH"                >> /home/shiny/.bash_profile
                    echo "export PATH=/home/shiny/tools/$tool_dir/build/libexec/meme-5.5.2:\$PATH" >> /home/shiny/.bashrc
                    echo "export PATH=/home/shiny/tools/$tool_dir/build/libexec/meme-5.5.2:\$PATH" >> /home/shiny/.zshrc
                    echo "export PATH=/home/shiny/tools/$tool_dir/build/libexec/meme-5.5.2:\$PATH" >> /home/shiny/.bash_profile
                    sudo chown -R shiny:shiny-apps /home/shiny/tools/$tool_dir/build/
                    print_green "    MEME Suite successfully installed"
                fi
            done
        fi
    fi
fi

############################ 16. static folder for nginx ################################################
if [ true ]; then
    print_green "\n 16. Exposing static folder /home/shiny/pmet/result via nginx..."

    if [ -f /etc/nginx/sites-available/pmet_result ]; then
        cat /etc/nginx/sites-available/pmet_result
    else
        print_orange "    /etc/nginx/sites-available/pmet_result does not exist, creating..."
        print_orange "    Writing configure inot  /etc/nginx/sites-available/pmet_result"
        echo -e "server {\n\
            listen 127.0.0.1:84;\n\
            server_name 127.0.0.1;\n\
            access_log  /var/log/nginx/localhost.access.log;\n\
            location /result {\n\
                alias /home/shiny/pmet/result;\n\
            }\n\
        }"
        cp data/configure/nginx_pmet /etc/nginx/sites-available/pmet_result
        # sudo ln -s /etc/nginx/sites-available/pmet_result /etc/nginx/sites-enabled/pmet_result
    fi
fi

# ############################# 17. download homotypic data ##############################
if [ true ]; then
    data_path="${target_dir}/data/indexing"

    print_green_no_br "\n17. Would you like to download data of homotypic motif hits? [y/N]: "
    read -p "" answer
    answer=${answer:-N} # Default to 'N' if no input provided

    print_orange "    Data path: $data_path"
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
        mkdir -p $data_path

        # 检查目录是否为空 Check if the directory is empty
        if [ "$(find "$data_path" -mindepth 1 -maxdepth 1 -type d)" ]; then
            print_red "    Directory $data_path contains subdirectories.\n"
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
            wget $url                                      > /dev/null 2>&1
            tar -xzvf  "$filename.tar.gz" -C data/indexing > /dev/null 2>&1
            rm "$filename.tar.gz"
        done
    else
        print_orange "    No data downloaded"
    fi
fi

print_green "\nDONE"
