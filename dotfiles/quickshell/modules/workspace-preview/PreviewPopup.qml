import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Item {
    id: previewWindow
    property bool active: true
    IpcHandler {
        target: "previewWindow"

        function toggleDashboard() {
            previewWindow.active = !previewWindow.active;
        }
    }
    implicitWidth: 320
    implicitHeight: 180
    //     Variants {
    //         model: {
    //             if (!previewWindow.active) {
    //                 return [];
    //             }
    //             Hyprland.focusedWorkspace ? [Hyprland.focusedWorkspace.monitor] : [];
    //         }
    //         delegate: PanelWindow {
    //             property var modelData
    //
    //             implicitWidth: previewWindow.implicitWidth
    //             implicitHeight: previewWindow.implicitHeight
    //             color: 'transparent'
    //             ScreencopyView {
    //                 captureSource: {
    //                     var workspaces = Hyprland.workspaces.values[1].monitor.screens;
    //                     // Quickshell.screens[1]
    //                     console.log(workspaces);
    //                     // return Quickshell.screens[1];
    //                 }
    //                 anchors.fill: parent
    //                 live: true
    //                 paintCursor: false
    //             }
    //         }
    //     }
}
