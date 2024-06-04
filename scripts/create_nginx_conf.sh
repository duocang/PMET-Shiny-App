#!/bin/bash

usage() {
    echo "Usage:
          --------------------------------------------------------------------------
          1. Use this script to generate your nginx.conf configuration

             /bin/bash create_nginx_conf.sh

          --------------------------------------------------------------------------
          2. If needed, you can provide the following arguments

          Commands:
            help: show help and exit

          Options:
           --port: the port for the application (default is 84)
           --base: base folder with applications (default is /etc/nginx/html)
           --server-name: server name for Nginx configuration (default is localhost_pmet)

          --------------------------------------------------------------------------
          3. The generated nginx.conf will be saved to the current directory.
         "
}

# Default values
NGINX_PORT=84
NGINX_BASE=/etc/nginx/html
NGINX_SERVER_NAME=localhost_pmet

while true; do
    NGINX_PORT=$(( ( RANDOM % 60000 )  + 1025 ))  # 选择一个 1025 到 65535 之间的随机端口
    (echo > /dev/tcp/localhost/$NGINX_PORT) >/dev/null 2>&1
    result=$?
    if [ $result -ne 0 ]; then  # 如果返回非0值，表示端口未被占用
        echo "Selected free port: $NGINX_PORT"
        break
    fi
done

if [ $# -eq 0 ]; then
    usage
    exit
fi

while true; do
    case ${1:-} in
        -h|--help|help)
            usage
            exit
        ;;
        -p|--port|port)
            shift
            NGINX_PORT="${1:-}"
            shift
        ;;
        -b|--base|base)
            shift
            NGINX_BASE="${1:-}"
            shift
        ;;
        -sn|--server-name|server-name)
            shift
            NGINX_SERVER_NAME="${1:-}"
            shift
        ;;
        -*)
            echo "Unknown option: ${1:-}"
            exit 1
        ;;
        *)
            break
        ;;
    esac
done

# Generate nginx.conf
cat <<EOF > conf/nginx.conf
server {
    listen       ${NGINX_PORT};
    listen  [::]:${NGINX_PORT};
    server_name  ${NGINX_SERVER_NAME};

    # access_log  /var/log/nginx/${NGINX_SERVER_NAME}.access.log;

    location /result {
        # autoindex on;
        alias ${NGINX_BASE};
    }
}
EOF

echo "conf/nginx.conf has been generated with the following settings:"
echo "Port: ${NGINX_PORT}"
echo "Base directory: ${NGINX_BASE}"
echo "Server name: ${NGINX_SERVER_NAME}"