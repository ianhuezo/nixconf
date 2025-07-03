#pragma once

#include <string>
#include <vector>
#include <nlohmann/json.hpp>

struct WorkspaceInfo {
    int id;
    std::string name;
    int monitor;
    int windows;
    bool hasfullscreen;
    std::string lastwindow;
    std::string lastwindowtitle;
};

struct WindowInfo {
    std::string address;
    int mapped;
    bool hidden;
    std::pair<int, int> at;      // x, y position
    std::pair<int, int> size;    // width, height
    int workspace_id;
    bool floating;
    int monitor;
    std::string class_name;
    std::string title;
    std::string initialclass;
    std::string initialtitle;
    int pid;
    bool xwayland;
    bool pinned;
    bool fullscreen;
    int fullscreenmode;
    bool fakeFullscreen;
    bool grouped;
    std::vector<std::string> swallowing;
    int focusHistoryID;
};

class HyprlandIPC {
public:
    HyprlandIPC();
    ~HyprlandIPC();
    
    bool connect();
    void disconnect();
    
    // Get workspace information
    std::vector<WorkspaceInfo> getWorkspaces();
    WorkspaceInfo getActiveWorkspace();
    
    // Get window information
    std::vector<WindowInfo> getClients();
    std::vector<WindowInfo> getClientsInWorkspace(int workspaceId);
    
    // Get monitor information
    nlohmann::json getMonitors();
    
    // Raw IPC communication
    std::string sendCommand(const std::string& command);
    
private:
    std::string m_socketPath;
    std::string m_instanceSignature;
    
    bool initializeSocket();
    std::string executeCommand(const std::string& command);
    
    // JSON parsing helpers
    WorkspaceInfo parseWorkspaceFromJson(const nlohmann::json& json);
    WindowInfo parseWindowFromJson(const nlohmann::json& json);
};
