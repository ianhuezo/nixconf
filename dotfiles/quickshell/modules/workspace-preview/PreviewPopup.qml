import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Item {
    id: preview
    property bool active: true
    IpcHandler {
        target: "previewWindow"

        function toggleDashboard() {
            previewWindow.active = !previewWindow.active;
        }
    }
    implicitWidth: 160
    implicitHeight: 90
    Variants {
        model: {
            if (!previewWindow.active) {
                return [];
            }
            Hyprland.focusedWorkspace ? [Hyprland.focusedWorkspace.monitor] : [];
        }
        delegate: Rectangle {
            anchors.fill: parent
        }
    }
}
