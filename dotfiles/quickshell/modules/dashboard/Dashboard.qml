import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Item {
    id: dashboard
    property bool active: false
    // Eagerly cache DesktopEntries on startup to avoid lag when dashboard opens
    property var _desktopEntriesCache: DesktopEntries.applications
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

            onCloseRequested: {
                dashboard.active = false;
            }
        }
    }
}
