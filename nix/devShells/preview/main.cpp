#include <iostream>
#include <string>
#include <wayland-client.h>
#include <nlohmann/json.hpp>
#include <QApplication>
#include <QWidget>
#include <QLabel>
#include <QVBoxLayout>
#include <QScrollArea>
#include <QDebug>
#include "hyprland_ipc.h"

int main(int argc, char *argv[]) {
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
    
    // Test Hyprland IPC
    std::cout << "\n=== Testing Hyprland IPC ===" << std::endl;
    
    try {
        HyprlandIPC ipc;
        ipc.connect();
        
        // Get workspaces
        auto workspaces = ipc.getWorkspaces();
        std::cout << "✅ Found " << workspaces.size() << " workspaces:" << std::endl;
        
        for (const auto& ws : workspaces) {
            std::cout << "  - Workspace " << ws.id << " (\"" << ws.name << "\") "
                      << "- " << ws.windows << " windows on monitor " << ws.monitor << std::endl;
        }
        
        // Get active workspace
        auto activeWs = ipc.getActiveWorkspace();
        std::cout << "\n✅ Active workspace: " << activeWs.id << " (\"" << activeWs.name << "\")" << std::endl;
        
        // Get clients
        auto clients = ipc.getClients();
        std::cout << "\n✅ Found " << clients.size() << " total windows" << std::endl;
        
        // Get clients in active workspace
        auto activeClients = ipc.getClientsInWorkspace(activeWs.id);
        std::cout << "✅ Found " << activeClients.size() << " windows in active workspace:" << std::endl;
        
        for (const auto& client : activeClients) {
            std::cout << "  - \"" << client.title << "\" (" << client.class_name << ") "
                      << "at (" << client.at.first << "," << client.at.second << ") "
                      << "size " << client.size.first << "x" << client.size.second << std::endl;
        }
        
    } catch (const std::exception& e) {
        std::cout << "❌ Hyprland IPC Error: " << e.what() << std::endl;
        return 1;
    }
    
    // Test Qt application with workspace data
    std::cout << "\n=== Testing Qt Application with Workspace Data ===" << std::endl;
    
    QApplication app(argc, argv);
    
    // Create a window to display workspace information
    QWidget window;
    window.setWindowTitle("Hyprland Workspace Preview - IPC Test");
    window.resize(600, 400);
    
    QVBoxLayout* layout = new QVBoxLayout(&window);
    
    // Create a scroll area for the content
    QScrollArea* scrollArea = new QScrollArea();
    QWidget* contentWidget = new QWidget();
    QVBoxLayout* contentLayout = new QVBoxLayout(contentWidget);
    
    // Add workspace information to the GUI
    try {
        HyprlandIPC ipc;
        ipc.connect();
        
        auto workspaces = ipc.getWorkspaces();
        auto activeWs = ipc.getActiveWorkspace();
        
        contentLayout->addWidget(new QLabel("🚀 Hyprland Workspace Information"));
        contentLayout->addWidget(new QLabel(QString("Active: Workspace %1 (\"%2\")").arg(activeWs.id).arg(QString::fromStdString(activeWs.name))));
        contentLayout->addWidget(new QLabel(""));
        
        for (const auto& ws : workspaces) {
            QString wsText = QString("Workspace %1: \"%2\" (%3 windows)")
                .arg(ws.id)
                .arg(QString::fromStdString(ws.name))
                .arg(ws.windows);
            
            if (ws.id == activeWs.id) {
                wsText += " [ACTIVE]";
            }
            
            contentLayout->addWidget(new QLabel(wsText));
            
            // Show windows in this workspace
            auto clients = ipc.getClientsInWorkspace(ws.id);
            for (const auto& client : clients) {
                QString clientText = QString("  • \"%1\" (%2) - %3x%4")
                    .arg(QString::fromStdString(client.title))
                    .arg(QString::fromStdString(client.class_name))
                    .arg(client.size.first)
                    .arg(client.size.second);
                
                contentLayout->addWidget(new QLabel(clientText));
            }
        }
        
    } catch (const std::exception& e) {
        contentLayout->addWidget(new QLabel(QString("Error: %1").arg(e.what())));
    }
    
    scrollArea->setWidget(contentWidget);
    layout->addWidget(scrollArea);
    
    window.show();
    
    std::cout << "✅ Qt6 application with workspace data created successfully" << std::endl;
    std::cout << "✅ Window showing all workspace information" << std::endl;
    std::cout << "Close the window to continue..." << std::endl;
    
    // Run the Qt event loop
    int result = app.exec();
    
    std::cout << "\n=== Test Complete ===" << std::endl;
    std::cout << "Hyprland IPC communication working!" << std::endl;
    
    return result;
}
