#!/bin/bash

# 创建目标目录
mkdir -p bin

cd bin
# 执行CMake命令生成Makefile
cmake -DCMAKE_BUILD_TYPE=Debug ..

# 执行Make命令进行编译
make

sleep 1
rm Makefile
rm -rf CMake*
rm -rf cmake_install.cmake