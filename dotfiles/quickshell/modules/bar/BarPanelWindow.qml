import Quickshell
import QtQuick
import QtQuick.Effects
import "root:/config"
import "root:/services"

PanelWindow {
    id: panel
    required property var modelData
    required property var cavaValues
    required property bool useCanvasVisualization
    required property var barOffsetY
    required property var barOffsetX
    required property var verticalPadding
    required property bool isActive
    property real animatedHeight: panel.isActive ? 54 : 0

    screen: modelData
    implicitHeight: animatedHeight
    color: '#00000000' // Transparent main panel

    Behavior on animatedHeight {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

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
                topMargin: panel.verticalPadding
                bottomMargin: panel.verticalPadding
                leftMargin: panel.barOffsetX
                rightMargin: panel.barOffsetX
            }
            color: Color.palette.base01
            radius: 8 // Optional: rounded corners for the bar

            // Animation properties for expand/collapse
            property real scaleX: panel.isActive ? 1.0 : 0.0
            property real scaleY: panel.isActive ? 1.0 : 0.0

            transform: Scale {
                xScale: offsetContainer.scaleX
                yScale: offsetContainer.scaleY
                origin.x: offsetContainer.width / 2
                origin.y: offsetContainer.height / 2
            }

            // Smooth animations for scale changes
            Behavior on scaleX {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on scaleY {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutCubic
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                blur: 10
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -1 // Extends slightly outward for the highlight border
                color: "transparent"
                border.color: Color.palette.base08 // A mid-tone blue from the wallpaper's spectrum
                border.width: 1
                radius: parent.radius + 1
            }

            // Accent Glow Line (the "frieren flowers" glow effect)
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1 // Inset for a fine line
                color: "transparent"
                border.color: Color.palette.base0B // Bright, ethereal blue/cyan for accent (like the flowers)
                border.width: 0 // Slightly thicker for more glow
                radius: parent.radius - 1
            }

            // Content container with padding
            Rectangle {
                id: contentContainer
                anchors {
                    fill: parent
                    topMargin: panel.verticalPadding
                    bottomMargin: panel.verticalPadding
                }
                color: "transparent" // No visible background

                // Left section
                Left {}

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
                        cavaValues: panel.cavaValues
                        useCanvas: panel.useCanvasVisualization
                        waveColor: Color.palette.base09
                        barColor: "transparent" // Use transparent for bar background
                        onToggleVisualization: panel.useCanvasVisualization = !panel.useCanvasVisualization
                    }
                }

                // Right section
                Row {
                    id: rightSection
                    height: parent.height
                    width: parent.width / 4
                    property real ramPercentage: GetRam.ram
                    property int cpuPercentage: GetCPU.cpu
                    property int gpuPercentage: GetGPU.gpu

                    property var circleStatsData: [
                        {
                            percentage: gpuPercentage,
                            statText: gpuPercentage + "%",
                            iconSource: FileConfig.icons.gpu
                        },
                        {
                            percentage: cpuPercentage,
                            statText: cpuPercentage + "%",
                            iconSource: FileConfig.icons.cpu
                        },
                        {
                            percentage: ramPercentage,
                            statText: ramPercentage + "%",
                            iconSource: FileConfig.icons.ram
                        }
                    ]
                    anchors {
                        right: parent.right
                        top: parent.top
                    }
                    layoutDirection: Qt.RightToLeft
                    Repeater {
                        model: rightSection.circleStatsData
                        delegate: CircleProgress {
                            percentage: modelData.percentage
                            statText: modelData.statText
                            iconSource: modelData.iconSource
                            textColor: Color.palette.base09
                            backgroundColor: Color.palette.base01
                            progressColor: Color.palette.base09
                            color: mainContainer.color
                        }
                    }
                }
            }
        }
    }
}
