#!/bin/bash

# 检查是否提供了两个参数
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <SHINY_CONF> <NGINX_CONF>"
    exit 1
fi

SHINY_CONF=$1
NGINX_CONF=$2

# 生成 docker-compose.yml 文件
cat <<EOF > docker-compose.yml
x-yml-version: '3.8'

services:
  shiny-app:
    build:
      context: .
      dockerfile: dockerfiles/Dockerfile.shiny
    container_name: shiny
    user: "$(id -u):$(id -g)"
    volumes:
      # - ./data/indexing:/home/shiny/PMET_docker/data/indexing
      # - ./result:/home/shiny/PMET_docker/result
      # - ./logs:/var/log/shiny-server
      - ./result:/srv/shiny-server/pmet/result
    ports:
      - "$SHINY_CONF:$SHINY_CONF"
    networks:
      - app-network

  nginx-server:
    build:
      context: .
      dockerfile: dockerfiles/Dockerfile.nginx
    container_name: nginx
    volumes:
      - ./result:/etc/nginx/html
    ports:
      - "$NGINX_CONF:$NGINX_CONF"
    restart: always
    networks:
      - app-network

volumes:
  logs:
  result:

networks:
  app-network:
EOF
