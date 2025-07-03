#include "hyprland_ipc.h"
#include <iostream>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>
#include <cstring>
#include <stdexcept>

HyprlandIPC::HyprlandIPC() {
    const char* signature = getenv("HYPRLAND_INSTANCE_SIGNATURE");
    if (!signature) {
        throw std::runtime_error("HYPRLAND_INSTANCE_SIGNATURE not found. Are you running under Hyprland?");
    }
    m_instanceSignature = signature;
}

HyprlandIPC::~HyprlandIPC() {
    disconnect();
}

bool HyprlandIPC::connect() {
    return initializeSocket();
}

void HyprlandIPC::disconnect() {
    // Socket is created and closed per command for simplicity
    // In a production version, you might want to keep a persistent connection
}

bool HyprlandIPC::initializeSocket() {
    // Construct the socket path
    m_socketPath = "/tmp/hypr/" + m_instanceSignature + "/.socket.sock";
    return true;
}

std::string HyprlandIPC::executeCommand(const std::string& command) {
    int sockfd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (sockfd == -1) {
        throw std::runtime_error("Failed to create socket");
    }
    
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, m_socketPath.c_str(), sizeof(addr.sun_path) - 1);
    
    if (::connect(sockfd, (struct sockaddr*)&addr, sizeof(addr)) == -1) {
        close(sockfd);
        throw std::runtime_error("Failed to connect to Hyprland socket: " + m_socketPath);
    }
    
    // Send the command
    if (send(sockfd, command.c_str(), command.length(), 0) == -1) {
        close(sockfd);
        throw std::runtime_error("Failed to send command");
    }
    
    // Read the response
    std::string response;
    char buffer[4096];
    ssize_t bytesRead;
    
    while ((bytesRead = recv(sockfd, buffer, sizeof(buffer) - 1, 0)) > 0) {
        buffer[bytesRead] = '\0';
        response += buffer;
    }
    
    close(sockfd);
    
    if (bytesRead == -1) {
        throw std::runtime_error("Failed to read response");
    }
    
    return response;
}

std::string HyprlandIPC::sendCommand(const std::string& command) {
    return executeCommand(command);
}

std::vector<WorkspaceInfo> HyprlandIPC::getWorkspaces() {
    std::string response = executeCommand("j/workspaces");
    
    std::vector<WorkspaceInfo> workspaces;
    
    try {
        nlohmann::json json = nlohmann::json::parse(response);
        
        for (const auto& item : json) {
            workspaces.push_back(parseWorkspaceFromJson(item));
        }
    } catch (const std::exception& e) {
        std::cerr << "Error parsing workspaces JSON: " << e.what() << std::endl;
        std::cerr << "Response was: " << response << std::endl;
    }
    
    return workspaces;
}

WorkspaceInfo HyprlandIPC::getActiveWorkspace() {
    std::string response = executeCommand("j/activeworkspace");
    
    try {
        nlohmann::json json = nlohmann::json::parse(response);
        return parseWorkspaceFromJson(json);
    } catch (const std::exception& e) {
        std::cerr << "Error parsing active workspace JSON: " << e.what() << std::endl;
        std::cerr << "Response was: " << response << std::endl;
        throw;
    }
}

std::vector<WindowInfo> HyprlandIPC::getClients() {
    std::string response = executeCommand("j/clients");
    
    std::vector<WindowInfo> clients;
    
    try {
        nlohmann::json json = nlohmann::json::parse(response);
        
        for (const auto& item : json) {
            clients.push_back(parseWindowFromJson(item));
        }
    } catch (const std::exception& e) {
        std::cerr << "Error parsing clients JSON: " << e.what() << std::endl;
        std::cerr << "Response was: " << response << std::endl;
    }
    
    return clients;
}

std::vector<WindowInfo> HyprlandIPC::getClientsInWorkspace(int workspaceId) {
    std::vector<WindowInfo> allClients = getClients();
    std::vector<WindowInfo> workspaceClients;
    
    for (const auto& client : allClients) {
        if (client.workspace_id == workspaceId) {
            workspaceClients.push_back(client);
        }
    }
    
    return workspaceClients;
}

nlohmann::json HyprlandIPC::getMonitors() {
    std::string response = executeCommand("j/monitors");
    
    try {
        return nlohmann::json::parse(response);
    } catch (const std::exception& e) {
        std::cerr << "Error parsing monitors JSON: " << e.what() << std::endl;
        std::cerr << "Response was: " << response << std::endl;
        throw;
    }
}

WorkspaceInfo HyprlandIPC::parseWorkspaceFromJson(const nlohmann::json& json) {
    WorkspaceInfo workspace;
    
    workspace.id = json.value("id", 0);
    workspace.name = json.value("name", "");
    workspace.monitor = json.value("monitor", 0);
    workspace.windows = json.value("windows", 0);
    workspace.hasfullscreen = json.value("hasfullscreen", false);
    workspace.lastwindow = json.value("lastwindow", "");
    workspace.lastwindowtitle = json.value("lastwindowtitle", "");
    
    return workspace;
}

WindowInfo HyprlandIPC::parseWindowFromJson(const nlohmann::json& json) {
    WindowInfo window;
    
    window.address = json.value("address", "");
    window.mapped = json.value("mapped", 0);
    window.hidden = json.value("hidden", false);
    
    // Parse position
    if (json.contains("at") && json["at"].is_array() && json["at"].size() >= 2) {
        window.at = {json["at"][0], json["at"][1]};
    }
    
    // Parse size
    if (json.contains("size") && json["size"].is_array() && json["size"].size() >= 2) {
        window.size = {json["size"][0], json["size"][1]};
    }
    
    // Parse workspace
    if (json.contains("workspace") && json["workspace"].contains("id")) {
        window.workspace_id = json["workspace"]["id"];
    }
    
    window.floating = json.value("floating", false);
    window.monitor = json.value("monitor", 0);
    window.class_name = json.value("class", "");
    window.title = json.value("title", "");
    window.initialclass = json.value("initialClass", "");
    window.initialtitle = json.value("initialTitle", "");
    window.pid = json.value("pid", 0);
    window.xwayland = json.value("xwayland", false);
    window.pinned = json.value("pinned", false);
    window.fullscreen = json.value("fullscreen", false);
    window.fullscreenmode = json.value("fullscreenMode", 0);
    window.fakeFullscreen = json.value("fakeFullscreen", false);
    window.grouped = json.value("grouped", false);
    window.focusHistoryID = json.value("focusHistoryID", 0);
    
    return window;
}
