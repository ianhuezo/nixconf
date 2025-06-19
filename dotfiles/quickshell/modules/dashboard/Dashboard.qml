import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Hyprland



Item {
    id: dashboard
    property bool active: false
    IpcHandler {
        target: "dashboard"

        function toggleDashboard() {
            dashboard.active = !dashboard.active;
        }
    }
    implicitWidth: 800
    implicitHeight: 600
    Variants {
        model: {
            if (!dashboard.active) {
                return [];
            }
            Hyprland.focusedWorkspace ? [Hyprland.focusedWorkspace.monitor] : [];
        }
        delegate: DashboardWindow {
            parentId: dashboard
        }
    }
}
