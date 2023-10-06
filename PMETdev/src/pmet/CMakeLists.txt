# cmake_minimum_required(VERSION 3.12)
project(pmet)

# Set compilation parameters
set(CMAKE_CXX_STANDARD 11)

# set out dir
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/bin)

add_executable(pmet
  main.cpp
  Output.cpp
  motif.cpp
  motifComparison.cpp
  utils.cpp
)

# Add performance testing tools
# target_link_libraries(${PROJECT_NAME} profiler unwind)
target_link_libraries(${PROJECT_NAME} )
