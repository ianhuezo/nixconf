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
    implicitWidth: 200
    implicitHeight: 150
    Variants {
        model: {
            if (dashboard.active != true) {
                return [];
            }
            Hyprland.focusedWorkspace ? [Hyprland.focusedWorkspace.monitor] : [];
        }
        delegate: PanelWindow {
            color: 'transparent'
            Rectangle {
                implicitHeight: parent.implicitHeight
                implicitWidth: parent.implicitWidth
                anchors.fill: parent
                border.color: 'red'
                border.width: 1
            }
        }
    }
}
