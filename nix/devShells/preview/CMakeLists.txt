cmake_minimum_required(VERSION 3.20)
project(hyprland-workspace-preview)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable debug symbols for development
set(CMAKE_BUILD_TYPE Debug)

# Find required packages
find_package(PkgConfig REQUIRED)

# Find Wayland client library
pkg_check_modules(WAYLAND_CLIENT REQUIRED wayland-client)

# Find Cairo for rendering
pkg_check_modules(CAIRO REQUIRED cairo)

# Find nlohmann_json
find_package(nlohmann_json REQUIRED)

# Create the executable
add_executable(hyprland-workspace-preview main.cpp)

# Link libraries
target_link_libraries(hyprland-workspace-preview 
    ${WAYLAND_CLIENT_LIBRARIES}
    ${CAIRO_LIBRARIES}
    nlohmann_json::nlohmann_json
)

# Add include directories
target_include_directories(hyprland-workspace-preview PRIVATE
    ${WAYLAND_CLIENT_INCLUDE_DIRS}
    ${CAIRO_INCLUDE_DIRS}
)

# Add compiler flags
target_compile_options(hyprland-workspace-preview PRIVATE
    ${WAYLAND_CLIENT_CFLAGS_OTHER}
    ${CAIRO_CFLAGS_OTHER}
)

# Print some useful information during build
message(STATUS "Building ${PROJECT_NAME}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Wayland Client: ${WAYLAND_CLIENT_VERSION}")
message(STATUS "Cairo: ${CAIRO_VERSION}")
