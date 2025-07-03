#include <iostream>
#include <string>
#include <wayland-client.h>
#include <nlohmann/json.hpp>

int main() {
    std::cout << "=== Hyprland Workspace Preview Test ===" << std::endl;
    
    // Test basic C++ functionality
    std::string project_name = "hyprland-workspace-preview";
    std::cout << "Project: " << project_name << std::endl;
    
    // Test JSON library
    nlohmann::json test_json = {{"test", "value"}, {"number", 42}};
    std::cout << "JSON test: " << test_json.dump() << std::endl;
    
    // Test Wayland connection
    std::cout << "\n=== Testing Wayland Connection ===" << std::endl;
    
    struct wl_display* display = wl_display_connect(nullptr);
    if (display) {
        std::cout << "✅ Successfully connected to Wayland display" << std::endl;
        wl_display_disconnect(display);
    } else {
        std::cout << "❌ Failed to connect to Wayland display" << std::endl;
        std::cout << "   Make sure you're running this in a Wayland session" << std::endl;
    }
    
    std::cout << "\n=== Environment Check ===" << std::endl;
    const char* wayland_display = getenv("WAYLAND_DISPLAY");
    const char* hyprland_instance = getenv("HYPRLAND_INSTANCE_SIGNATURE");
    
    std::cout << "WAYLAND_DISPLAY: " << (wayland_display ? wayland_display : "not set") << std::endl;
    std::cout << "HYPRLAND_INSTANCE_SIGNATURE: " << (hyprland_instance ? hyprland_instance : "not set") << std::endl;
    
    return 0;
}
