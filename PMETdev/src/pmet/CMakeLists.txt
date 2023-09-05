cmake_minimum_required(VERSION 3.12)
project(pmet)

# add_compile_options(-std=c++11)
set(CMAKE_CXX_STANDARD 11)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin)

add_executable(pmet
  main.cpp
  Output.cpp
  motif.cpp
  motifComparison.cpp
  Output.hpp
  motif.hpp
  motifComparison.hpp
)

target_link_libraries(${PROJECT_NAME})