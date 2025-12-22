import Quickshell
import QtQuick
import QtQuick.Effects
import qs.config
import qs.services
import Quickshell.Widgets

PanelWindow {
    id: panel

    // Required properties
    required property var modelData
    required property var cavaValues
    required property bool useCanvasVisualization
    required property var barOffsetY
    required property var barOffsetX
    required property var verticalPadding
    required property bool isActive

    // Panel configuration
    property real panelHeight: 36
    property real panelRadius: 8
    property bool isSectionedBar: false
    property bool isBarBordered: false
    property color barBorderColor: Color.palette.base09
    property color widgetMainColor: Color.palette.base0C

    // Computed properties
    property real animatedHeight: isActive ? 54 : 0
    property real duration: isActive ? 300 : 1

    screen: modelData
    implicitHeight: animatedHeight
    color: '#00000000'

    anchors {
        top: true
        left: true
        right: true
    }

    Behavior on animatedHeight {
        NumberAnimation {
            duration: panel.duration
            easing.type: Easing.OutCubic
        }
    }

    // Main container with offset margins
    Item {
        id: container
        anchors {
            fill: parent
            topMargin: verticalPadding
            bottomMargin: verticalPadding
            leftMargin: barOffsetX
            rightMargin: barOffsetX
        }

        // Animated scale transform
        property real targetScale: panel.isActive ? 1.0 : 0.0

        // Use opacity to prevent artifacts while preserving the animation
        opacity: panel.isActive ? 1.0 : 0.0

        transform: Scale {
            xScale: container.targetScale
            yScale: container.targetScale
            origin.x: container.width / 2
            origin.y: container.height / 2
        }

        Behavior on targetScale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        // Main bar with blur effect
        Item {
            id: bar
            anchors.fill: parent

            // Outer rectangle acts as border for unified bar
            Rectangle {
                anchors.fill: parent
                color: barBorderColor
                radius: panelRadius
                visible: isBarBordered && !isSectionedBar
                z: 0
            }

            // Inner background rectangle
            Rectangle {
                anchors.fill: parent
                anchors.margins: (isBarBordered && !isSectionedBar) ? 1 : 0
                color: isSectionedBar ? "transparent" : Color.palette.base01
                radius: (isBarBordered && !isSectionedBar) ? panelRadius - 1 : panelRadius
                z: 1

                layer.enabled: true
            }
        }

        // Three-section layout using anchors for better positioning
        Item {
            anchors.fill: parent
            anchors.margins: (isBarBordered && !isSectionedBar) ? 1 : 0
            z: 2

            // LEFT SECTION
            Item {
                id: leftSection
                anchors {
                    left: parent.left
                    leftMargin: 8
                    top: parent.top
                    bottom: parent.bottom
                }
                width: 200

                Rectangle {
                    anchors.fill: parent
                    color: barBorderColor
                    radius: panelRadius
                    visible: isBarBordered && isSectionedBar
                    z: 0
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: (isBarBordered && isSectionedBar) ? 1 : 0
                    color: Color.palette.base01
                    radius: (isBarBordered && isSectionedBar) ? panelRadius - 1 : panelRadius
                    z: 1

                    Left {
                        anchors.fill: parent
                    }
                }
            }

            // CENTER SECTION
            Item {
                id: centerSection
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    bottom: parent.bottom
                }
                width: parent.width / 7

                Rectangle {
                    anchors.fill: parent
                    color: barBorderColor
                    radius: panelRadius
                    visible: isBarBordered && isSectionedBar
                    z: 0
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: (isBarBordered && isSectionedBar) ? 1 : 0
                    color: Color.palette.base01
                    radius: (isBarBordered && isSectionedBar) ? panelRadius - 1 : panelRadius
                    z: 1

                    Center {
                        anchors.fill: parent
                        cavaValues: panel.cavaValues
                        useCanvas: panel.useCanvasVisualization
                        waveColor: panel.widgetMainColor
                        isSectionedBar: panel.isSectionedBar
                        onToggleVisualization: panel.useCanvasVisualization = !panel.useCanvasVisualization
                    }
                }
            }

            // RIGHT SECTION
            Item {
                id: rightSection
                anchors {
                    right: parent.right
                    rightMargin: 8
                    top: parent.top
                    bottom: parent.bottom
                }
                width: 320

                Rectangle {
                    anchors.fill: parent
                    color: barBorderColor
                    radius: panelRadius
                    visible: isBarBordered && isSectionedBar
                    z: 0
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: (isBarBordered && isSectionedBar) ? 1 : 0
                    color: Color.palette.base01
                    radius: (isBarBordered && isSectionedBar) ? panelRadius - 1 : panelRadius
                    z: 1
                    clip: false

                    Right {
                        anchors.fill: parent
                        widgetColor: panel.widgetMainColor
                        clockColor: Color.palette.base0F
                    }
                }
            }
        }
    }
}
