#!/bin/bash

mkdir -p bin
cd bin

cmake -DCMAKE_BUILD_TYPE=Release ..
make

sleep 1
rm Makefile
rm -rf CMake*
rm -rf cmake_install.cmake
