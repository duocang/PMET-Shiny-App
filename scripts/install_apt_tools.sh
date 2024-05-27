#!/bin/bash

set -e

apt update && apt upgrade -y

# update-alternatives --config libblas.so.3-$(arch)-linux-gnu
echo "deb http://security.ubuntu.com/ubuntu focal-security main" | tee /etc/apt/sources.list.d/focal-security.list

apt -y install libcurl4-openssl-dev
apt -y install curl
apt -y install vim
apt -y install wget bzip2
apt -y install openjdk-21-jdk
apt -y install r-cran-rjava
apt -y install build-essential

apt -y install autotools-dev
apt -y install automake
apt -y install nodejs
apt -y install libssl-dev
apt -y install libxml2-dev
apt -y install libxml2
apt -y install cmake
apt -y install libharfbuzz-dev
apt -y install libfribidi-dev
apt -y install libncurses5-dev
apt -y install libncursesw5-dev
apt -y install libbz2-dev
apt -y install parallel
apt -y install ufw

apt -y install libjpeg-dev
apt -y install librsvg2-dev
apt -y install libpoppler-cpp-dev
apt -y install freetype2-demos
apt -y install cargo
apt -y install libxslt-dev
apt -y install zlib1g-dev
apt -y install libgdbm-dev
apt -y install npm
apt -y install libtesseract-dev
apt -y install libleptonica-dev
apt -y install tesseract-ocr-eng
apt -y install libmagick++-dev
apt -y install libavfilter-dev
apt -y install zip
apt -y install libpcre2-dev
apt -y install libreadline-dev
apt -y install glibc-source
apt -y install libstdc++6
apt -y install genometools
# apt -y install libssl1.1
apt -y install libopenblas-dev
apt -y install gfortran

apt -y install rsync

wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb
sudo dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb
rm libssl1.1_1.1.0g-2ubuntu4_amd64.deb

export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
export PATH=$PATH:$JAVA_HOME/bin

apt-get clean &&  rm -rf /var/lib/apt/lists/*
