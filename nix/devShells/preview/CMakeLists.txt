cmake_minimum_required(VERSION 3.20)
project(hyprland-workspace-preview)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable debug symbols for development
set(CMAKE_BUILD_TYPE Debug)

# Create the executable
add_executable(hyprland-workspace-preview main.cpp)

# Print some useful information during build
message(STATUS "Building ${PROJECT_NAME}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
