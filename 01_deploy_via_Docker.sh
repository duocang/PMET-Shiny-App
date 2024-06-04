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
chmod -R 766 data result

#################### 1 email
print_green "1. Configurations of email to send results"
check_and_set_email_credentials

#################### 2. CPU
print_green "2. Configuration of CPU number"
check_cpu_number


#################### 3. Update shiny and nginx configuration files
print_green "3. Update shiny and nginx configuration files"

SHINY_CONF="conf/shiny-server.conf"
NGINX_CONF="conf/nginx.conf"

rm -rf $SHINY_CONF
rm -rf $NGINX_CONF

print_green "Generating shiny-server.conf..."
bash scripts/create_shiny_server_conf.sh start
print_green "\nGenerating nginx.conf..."
bash scripts/create_nginx_conf.sh start

# remove line with run_as
sed -i '/^run_as/d' $SHINY_CONF

# Extract port numbers
NGINX_PORT=$(extract_port "$NGINX_CONF")
SHINY_PORT=$(extract_port "$SHINY_CONF")

# update nginx link
echo "http://localhost:$NGINX_PORT/result/" > data/nginx_link.txt

#################### 4. Update dockerfiles and docker-compose.yml
print_green "4. Update dockerfiles and docker-compose.yml"

# update dockerfiles
sed -i "s|EXPOSE [0-9]*|EXPOSE $NGINX_PORT|" dockerfiles/Dockerfile.nginx
sed -i "s|EXPOSE [0-9]*|EXPOSE $SHINY_PORT|" dockerfiles/Dockerfile.shiny

# update docker-compose.yml
bash scripts/create_docker_compose.sh $SHINY_PORT $NGINX_PORT

#################### 5. Docker build
print_green "5. Docker building"

start_time=$(date +%s)

docker-compose up -d > logs/docker_img_build.log 2>&1 &

build_pid=$!
# While the build process is running, display the elapsed time
while kill -0 $build_pid 2> /dev/null; do
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    show_time $elapsed_time
    sleep 1
done

print_green "\n\nYou are safe to colse this console."
wait
