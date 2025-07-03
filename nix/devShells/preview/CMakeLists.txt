cmake_minimum_required(VERSION 3.20)
project(hyprland-workspace-preview)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable debug symbols for development
set(CMAKE_BUILD_TYPE Debug)

# Find required packages
find_package(PkgConfig REQUIRED)

# Find Qt6
find_package(Qt6 REQUIRED COMPONENTS Core Widgets Gui)

# Find Wayland client library
pkg_check_modules(WAYLAND_CLIENT REQUIRED wayland-client)

# Find nlohmann_json
find_package(nlohmann_json REQUIRED)

# Enable Qt MOC (Meta-Object Compiler) if needed
set(CMAKE_AUTOMOC ON)

# Create the executable
add_executable(hyprland-workspace-preview 
    main.cpp
    hyprland_ipc.cpp
)

# Link libraries
target_link_libraries(hyprland-workspace-preview 
    Qt6::Core
    Qt6::Widgets
    Qt6::Gui
    ${WAYLAND_CLIENT_LIBRARIES}
    nlohmann_json::nlohmann_json
)

# Add include directories
target_include_directories(hyprland-workspace-preview PRIVATE
    ${WAYLAND_CLIENT_INCLUDE_DIRS}
)

# Add compiler flags
target_compile_options(hyprland-workspace-preview PRIVATE
    ${WAYLAND_CLIENT_CFLAGS_OTHER}
)

# Print some useful information during build
message(STATUS "Building ${PROJECT_NAME}")
message(STATUS "C++ Standard: ${CMAKE_CXX_STANDARD}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Qt6 Version: ${Qt6_VERSION}")
message(STATUS "Wayland Client: ${WAYLAND_CLIENT_VERSION}")
