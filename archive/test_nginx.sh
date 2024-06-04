#!/bin/bash
source scripts/colored_print.sh

rm -rf conf/nginx_singularity.conf

print_green "生成nginx_singularity.conf..."
bash scripts/create_nginx_conf_singularity.sh start

# 定义文件和镜像名称
DEF_FILE="Singularities/Singularity_nginx.def"
SIMG_FILE="Singularities/nginx.simg"

rm -f "$SIMG_FILE"
print_orange "已删除 $SIMG_FILE 文件，并重现构建镜像。"
singularity build --fakeroot $SIMG_FILE $DEF_FILE

#################################### 运行镜像 ####################################
singularity run                           \
    --bind ./result:/etc/nginx/html \
    $SIMG_FILE