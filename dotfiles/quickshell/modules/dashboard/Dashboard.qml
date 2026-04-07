import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Item {
    id: dashboard
    property bool active: false
    property bool closing: false
    // Eagerly cache DesktopEntries on startup to avoid lag when dashboard opens
    property var _desktopEntriesCache: DesktopEntries.applications
    IpcHandler {
        target: "dashboard"

        function toggleDashboard() {
            if (dashboard.active) {
                dashboard.closing = true;
            } else {
                dashboard.active = true;
            }
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
                dashboard.closing = false;
                dashboard.active = false;
            }
        }
    }
}
