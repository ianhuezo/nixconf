import Quickshell.Hyprland
import QtQuick
import Quickshell
import Qt.labs.platform 1.1
import QtQuick.Effects
import "root:/config"
import "root:/services"

Column {
    id: hyprlandWindowDisplay
    anchors.fill: parent
    spacing: 10

    property int activeWsId: Hyprland.focusedMonitor?.activeWorkspace ? Hyprland.focusedMonitor?.activeWorkspace.id : 1
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
                workspaceRow.triggerWorkspaceSwing(event.data);
            }
        }
    }

    // Workspace row at the top
    Row {
        id: workspaceRow
        width: parent.width
        height: 20
        spacing: 8
        property var swingAnimations: []
        function registerSwingAnimation(index, animation) {
            swingAnimations[index] = animation;
        }

        // Function to trigger specific animation
        function triggerWorkspaceSwing(workspaceIndex) {
            if (swingAnimations[workspaceIndex - 1]) {
                swingAnimations[workspaceIndex - 1].start();
            }
        }
        Repeater {
            model: Math.max(5, Math.min(5, Object.values(hyprlandWindowDisplay.workspaceMap).length))
            delegate: Rectangle {
                id: lampRect
                width: 20
                height: 20
                color: "transparent"
                transformOrigin: Item.Top

                Component.onCompleted: {
                    workspaceRow.registerSwingAnimation(index, swingAnimation);
                }

                Image {
                    id: lampIcon
                    anchors.centerIn: parent
                    sourceSize.width: parent.width * 1.5
                    sourceSize.height: parent.height * 1.5
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    source: "../../../assets/icons/lamp_on.png"
                    visible: true // Always visible - effects will handle inactive state

                    // Swing animation

                }
                SequentialAnimation {
                    id: swingAnimation
                    loops: 1

                    // Swing to the left
                    NumberAnimation {
                        target: lampRect
                        property: "rotation"
                        from: 0
                        to: -15
                        duration: 200
                        easing.type: Easing.OutQuad
                    }

                    // Swing back to center
                    NumberAnimation {
                        target: lampRect
                        property: "rotation"
                        from: -15
                        to: 0
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }

                    // Swing to the right
                    NumberAnimation {
                        target: lampRect
                        property: "rotation"
                        from: 0
                        to: 15
                        duration: 200
                        easing.type: Easing.OutQuad
                    }

                    // Swing back to center and settle
                    NumberAnimation {
                        target: lampRect
                        property: "rotation"
                        from: 15
                        to: 0
                        duration: 250
                        easing.type: Easing.InOutQuad
                    }
                }
                // MultiEffect elements outside the Image to avoid weird interactions
                MultiEffect {
                    source: lampIcon
                    anchors.fill: lampIcon
                    colorization: 1
                    colorizationColor: Color.palette.base08  // Red tint for inactive lamps
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
                    colorizationColor: Color.palette.base08
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
                    shadowColor: Color.palette.base09
                    shadowHorizontalOffset: 0
                    shadowVerticalOffset: 0
                    shadowBlur: 1.0
                    visible: (index + 1) === activeWsId
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        Hyprland.dispatch("workspace " + (index + 1));
                        swingAnimation.start(); // Start the swing animation
                    }
                }
            }
        }
    }
}
