#!/bin/bash

# 停止所有运行中的容器
echo "Stopping all running containers..."
docker stop $(docker ps -q)

# 删除所有容器
echo "Removing all containers..."
docker rm $(docker ps -aq)

# 删除所有镜像
echo "Removing all images..."
docker rmi $(docker images -q)

# 可选：删除所有悬空镜像（dangling images）
echo "Removing all dangling images..."
docker image prune -af

# 可选：删除所有未使用的容器、镜像、卷和网络
echo "Pruning all unused containers, images, volumes, and networks..."
docker system prune --volumes

# 可选：清理构建缓存
echo "Pruning build cache..."
docker builder prune --all

echo "Cleanup is complete."
