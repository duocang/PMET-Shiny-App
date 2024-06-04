#!/bin/bash
source scripts/colored_print.sh
source scripts/check_and_set_email_credentials.sh
source scripts/check_CPU_number.sh

# Function to extract port number from configuration file
extract_port() {
    local file=$1
    grep -Eo "listen\s+[0-9]+" "$file" | grep -Eo "[0-9]+"
}

# Function to format and display elapsed time
show_time() {
    local elapsed_time=$1
    local hours=$((elapsed_time / 3600))
    local minutes=$(( (elapsed_time % 3600) / 60))
    local seconds=$((elapsed_time % 60))
    printf "\rElapsed time: %02d:%02d:%02d" $hours $minutes $seconds
}

set -e
chmod -R 755 scripts/
chmod -R 755 PMETdev/
chmod -R 766 result/


##################################### email ###################################################
print_green "Configurations of email to send results"
check_and_set_email_credentials

##################################  CPU #####################################################
print_green "Configuration of CPU number"
check_cpu_number


# Definition files and image names
DEF_FILE_SHINY="Singularities/Singularity_shiny.def"
SIMG_FILE_SHINY="Singularities/shiny_server.simg"

DEF_FILE_NGINX="Singularities/Singularity_nginx.def"
SIMG_FILE_NGINX="Singularities/nginx.simg"

NGINX_CONF="conf/nginx.conf"
SHINY_CONF="conf/shiny-server.conf"

echo ""

#################################### Check definition files ####################################
# Check if Singularity definition files exist
if [ ! -f "$DEF_FILE_SHINY" ] && [ ! -f "$DEF_FILE_NGINX" ]; then
    echo "Singularity definition files $DEF_FILE_SHINY and $DEF_FILE_NGINX do not exist."
    exit 1
elif [ ! -f "$DEF_FILE_SHINY" ]; then
    echo "Singularity definition file $DEF_FILE_SHINY does not exist."
    exit 1
elif [ ! -f "$DEF_FILE_NGINX" ]; then
    echo "Singularity definition file $DEF_FILE_NGINX does not exist."
    exit 1
fi
echo ""

#################################### Check if simg files need to be rebuilt ####################################
FLAG_IMG_REBUILD=false

# Check if simg files exist
if [ -f "$SIMG_FILE_SHINY" ] || [ -f "$SIMG_FILE_NGINX" ]; then
    # simg files exist, ask user if they want to delete and rebuild
    print_green "Existing $SIMG_FILE_SHINY and $SIMG_FILE_NGINX found."
    print_orange_no_br "Do you want to delete and rebuild? (y/N): "
    read -p "" -n 1 -r REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Set flag to rebuild images
        FLAG_IMG_REBUILD=true
    fi
else
    # simg files do not exist, set flag to rebuild
    print_orange "simg files do not exist, rebuild images."
    FLAG_IMG_REBUILD=true
fi


#################################### Build images ####################################
if [ "$FLAG_IMG_REBUILD" = true ]; then
    ####################################
    # shiny and nginx configuration files
    ####################################
    rm -rf conf/shiny-server.conf
    rm -rf conf/nginx.conf

    print_green "\nGenerating shiny-server.conf..."
    bash scripts/create_shiny_server_conf.sh start
    print_green "\nGenerating nginx.conf..."
    bash scripts/create_nginx_conf.sh start

    # Extract port numbers
    NGINX_PORT=$(extract_port "$NGINX_CONF")
    SHINY_PORT=$(extract_port "$SHINY_CONF")

    # update nginx link
    echo "http://localhost:$NGINX_PORT/result/" > data/nginx_link.txt

    ####################################
    # build images
    ####################################

    rm -rf $SIMG_FILE_SHINY $SIMG_FILE_NGINX

    print_green "\nBuilding shiny-server image (50 min)"
    # Run the singularity build command in the background
    start_time=$(date +%s)
    singularity build --fakeroot $SIMG_FILE_SHINY $DEF_FILE_SHINY > logs/singularity_img_build_shiny.log 2>&1 &
    build_pid=$!
    # While the build process is running, display the elapsed time
    while kill -0 $build_pid 2> /dev/null; do
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        show_time $elapsed_time
        sleep 1
    done
    echo ""

    print_green "Building nginx images..."
    start_time=$(date +%s)
    singularity build --fakeroot $SIMG_FILE_NGINX $DEF_FILE_NGINX > logs/singularity_img_build_nginx.log 2>&1 &
    build_pid=$!

    while kill -0 $build_pid 2> /dev/null; do
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        show_time $elapsed_time
        sleep 1
    done
    echo ""
fi


#################################### Check images ####################################
if [ $? -ne 0 ]; then
    print_red "Singularity image build failed."
    exit 1
fi

#################################### Check required software ####################################
REQUIRED_SOFTWARE=("fimo" "pmet" "pmetindex" "pmetParallel_linux")
MISSING_SOFTWARE=()

for software in "${REQUIRED_SOFTWARE[@]}"; do
    if [ ! -f "PMETdev/scripts/$software" ]; then
        MISSING_SOFTWARE+=("$software")
    fi
done

if [ ${#MISSING_SOFTWARE[@]} -ne 0 ]; then
    print_red "The following required software is missing in PMETdev/scripts:"
    for software in "${MISSING_SOFTWARE[@]}"; do
        echo "    $software"
    done

    print_orange "  Compiling PMET tools..."
    bash scripts/pmet_binary_compile.sh > /dev/null 2>&1 || print_red "Failed to run  scripts/pmet_binary_compile.sh"
    exit 1
fi


#################################### Download PMET indexing data ####################################
INDEXING_DIR="data/indexing"

# Check if there are subdirectories in the data/indexing directory
if [ -d "$INDEXING_DIR" ] && [ "$(ls -l "$INDEXING_DIR" 2>/dev/null | grep '^d' | wc -l)" -gt 0 ]; then
    # print_orange "There are subdirectories in $INDEXING_DIR."
    # # Directory is not empty (has subdirectories), skip download script
    # echo "Skipping download script."
    echo ""
else
    print_red "No subdirectories in $INDEXING_DIR."
    # Directory is empty (no subdirectories), run download script
    print_green "Running download script..."
    print_green "Downloading PMET indexing data."
    bash scripts/download_pmet_indexing.sh
    if [ $? -eq 0 ]; then
        echo "Download script ran successfully."
    else
        echo "Download script failed."
        exit 1
    fi
fi


#################################### Run images ####################################
print_green "Running shiny-server and Nginx..."
# Extract port numbers
NGINX_PORT=$(extract_port "$NGINX_CONF")
SHINY_PORT=$(extract_port "$SHINY_CONF")

# Print the extracted port numbers
print_fluorescent_yellow "PMET link  : localhost:$SHINY_PORT/pmet"
print_fluorescent_yellow "Result link: localhost:$NGINX_PORT/result"

singularity run                                                         \
    --bind ./:/srv/shiny-server/pmet                                    \
    --bind ./data:/srv/shiny-server/pmet/data                           \
    --bind ./logs:/var/log/shiny-server                                 \
    --bind ./Singularities/lib:/var/lib/shiny-server                    \
    --bind ./conf/shiny-server.conf:/etc/shiny-server/shiny-server.conf \
    --bind ./test.R:/srv/shiny-server/test/app.R                        \
    $SIMG_FILE_SHINY > logs/singularity_running_shiny_server.log 2>&1 &

singularity run                     \
    --bind ./result:/etc/nginx/html \
    $SIMG_FILE_NGINX > logs/singularity_running_nginx.log 2>&1 &

# Wait for all background processes to complete

print_green "\n\nYou are safe to colse this console."
wait
