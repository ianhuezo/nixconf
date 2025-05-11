import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property var cavaValues: []
    property bool useCanvasVisualization: true
    property var barOffsetY: 8  // Renamed from barOffset
    property var barOffsetX: 10 // New horizontal offset property
    property var verticalPadding: 0 // Padding for top and bottom of the inner bar

    CavaDataProcessor {
        id: cavaProcessor
        onNewData: processedValues => root.cavaValues = processedValues
    }

    Variants {
        model: {
            return Quickshell.screens.filter(screen => screen.name == "DP-1");
        }
        delegate: PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            height: 38 + (root.barOffsetY * 2) // Account for both top and bottom offsets
            color: '#00000000' // Transparent main panel
            anchors {
                top: true
                left: true
                right: true
            }

            Rectangle {
                id: mainContainer
                anchors.fill: parent
                color: panel.color

                Rectangle {
                    id: offsetContainer
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        bottom: parent.bottom
                        topMargin: root.barOffsetY
                        bottomMargin: root.barOffsetY
                        leftMargin: root.barOffsetX
                        rightMargin: root.barOffsetX
                    }
                    color: '#171D23'
                    radius: 8 // Optional: rounded corners for the bar

                    // Content container with padding
                    Rectangle {
                        id: contentContainer
                        anchors {
                            fill: parent
                            topMargin: root.verticalPadding
                            bottomMargin: root.verticalPadding
                        }
                        color: "transparent" // No visible background

                        // Left section
                        Rectangle {
                            id: leftSection
                            height: parent.height
                            width: parent.width / 4
                            anchors {
                                left: parent.left
                                top: parent.top
                            }
                            color: "transparent"

                            Row {
                                id: leftContent
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 15
                                spacing: 5

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: 'transparent'
                                    Image {
                                        id: nixosIcon
                                        sourceSize.width: parent.width
                                        sourceSize.height: parent.height
                                        fillMode: Image.PreserveAspectFit
                                        source: "../../assets/icons/nixos.png"
                                    }
                                }
                            }
                        }

                        // Center section
                        Rectangle {
                            id: centerSection
                            height: parent.height
                            width: parent.width / 2
                            anchors {
                                centerIn: parent
                            }
                            color: "transparent"

                            VisualizerContainer {
                                anchors.centerIn: parent
                                cavaValues: root.cavaValues
                                useCanvas: root.useCanvasVisualization
                                waveColor: '#FF9E64'
                                barColor: "transparent" // Use transparent for bar background
                                onToggleVisualization: root.useCanvasVisualization = !root.useCanvasVisualization
                            }
                        }

                        // Right section
                        Rectangle {
                            id: rightSection
                            height: parent.height
                            width: parent.width / 4
                            anchors {
                                right: parent.right
                                top: parent.top
                            }
                            color: "transparent"

                            Row {
                                id: rightContent
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: 15
                                spacing: 5

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: 'transparent'
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
