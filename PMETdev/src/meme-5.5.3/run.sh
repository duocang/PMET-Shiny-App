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

mkdir -p fimo_out
start=$(date +%s)

build/bin/fimo                      \
    --topn 5                        \
    --topn 5000                     \
    --text                          \
    --no-qvalue                     \
    --thresh 0.05                   \
    --verbosity 1                   \
    --oc fimo_out/                  \
    --bgfile fimo_test/promoters.bg \
    fimo_test/memefiles/a.txt       \
    fimo_test/promoters.fa          \
    fimo_test/promoter_lengths.txt

end=$(date +%s)
time_taken=$((end - start))
print_red "Time taken: $time_taken seconds"

print_green "done"
