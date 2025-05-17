import Quickshell.Hyprland
import QtQuick
import Quickshell
import Qt.labs.platform 1.1
import QtQuick.Effects

Column {
    id: hyprlandWindowDisplay
    anchors.fill: parent
    spacing: 10

    property int activeWsId: Hyprland.focusedMonitor.activeWorkspace.id
    property var workspaceMap: {
        let map = {};
        Hyprland.workspaces.values.forEach(w => map[w.id] = w);
        return map;
    }

    // Track current windows

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "workspace") {
                Hyprland.refreshWorkspaces();
                activeWsId = event.data;
            }
        }
    }

    // Workspace row at the top
    Row {
        id: workspaceRow
        width: parent.width
        height: 20
        spacing: 8

        Repeater {
            model: Math.max(5, Math.min(5, Object.values(hyprlandWindowDisplay.workspaceMap).length))
            delegate: Rectangle {
                width: 20
                height: 20
                radius: 10
                color: "transparent"

                // Lamp icon - shown for all workspaces
                Image {
                    id: lampIcon
                    anchors.centerIn: parent
                    sourceSize.width: parent.width * 1.5
                    sourceSize.height: parent.height * 1.5
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    source: "../../assets/icons/lamp_on.png"
                    visible: true // Always visible - effects will handle inactive state
                }

                MultiEffect {
                    source: lampIcon
                    anchors.fill: lampIcon
                    colorization: 1
                    colorizationColor: "#AA3333"  // Red tint for inactive lamps
                    blur: 0.1
                    blurMax: 4
                    shadowEnabled: true
                    shadowColor: "#AAAAAA"  // Dark red glow
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                    shadowBlur: 0.6
                    visible: (index + 1) !== activeWsId
                }
                // Inactive lamp effect
                MultiEffect {
                    source: lampIcon
                    anchors.fill: lampIcon
                    colorization: 1
                    colorizationColor: "#CC3333"
                    visible: (index + 1) !== activeWsId
                }

                // Glow effect for active lamp
                MultiEffect {
                    source: lampIcon
                    anchors.fill: lampIcon
                    blur: 0.2
                    blurMax: 8
                    brightness: 0.1
                    shadowEnabled: true
                    shadowColor: "#ffdd55"
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                    shadowBlur: 1.0
                    visible: (index + 1) === activeWsId
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Hyprland.dispatch("workspace " + (index + 1));
                    }
                }
            }
        }
    }
}
