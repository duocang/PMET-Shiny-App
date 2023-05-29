cmake_minimum_required(VERSION 3.12)
project(pmet)

# 设置编译参数
# add_compile_options(-std=c++11)
set(CMAKE_CXX_STANDARD 11)
# set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -pthread")

# 设置输出目录
# set_target_properties(pmet PROPERTIES
#   RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin
# )
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin)

# 添加可执行文件
add_executable(pmet
  main.cpp
  Output.cpp
  motif.cpp
  motifComparison.cpp
  Output.hpp
  motif.hpp
  motifComparison.hpp
)
# file(GLOB_RECURSE HEADERS "*.hpp")
# file(GLOB_RECURSE SOURCES "*.cpp")
# add_executable(${PROJECT_NAME} ${HEADERS} ${SOURCES})

# # 添加性能测试工具
# target_link_libraries(${PROJECT_NAME} profiler unwind)