import Quickshell
import QtQuick
import Quickshell.Io
import QtQuick.Effects
import "root:/config"
import "root:/services"

Item {
    id: bar
    property var active: true
    property var cavaValues: []
    property bool useCanvasVisualization: true
    property var barOffsetY: 8  // Renamed from barOffset
    property var barOffsetX: 10 // New horizontal offset property
    property var verticalPadding: 8 // Padding for top and bottom of the inner bar
    property real originalHeight: bar.implicitHeight
    property var mainMonitor: Quickshell.screens.filter(screen => screen.name == "DP-1")

    IpcHandler {
        target: "bar"

        function toggleBar() {
            bar.active = !bar.active;
        }
    }

    CavaDataProcessor {
        id: cavaProcessor
        onNewData: processedValues => bar.cavaValues = processedValues
    }
    Variants {
        model: {
            return bar.active ? bar.mainMonitor : [];
        }

        delegate: PanelWindow {
            id: panel
            required property var modelData
            screen: modelData
            implicitHeight: 54
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
                        topMargin: bar.verticalPadding
                        bottomMargin: bar.verticalPadding
                        leftMargin: bar.barOffsetX
                        rightMargin: bar.barOffsetX
                    }
                    color: Color.palette.base01
                    radius: 8 // Optional: rounded corners for the bar

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blur: 10
                    }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1 // Extends slightly outward for the highlight border
                        color: "transparent"
                        border.color: "#2A3E5C" // A mid-tone blue from the wallpaper's spectrum
                        border.width: 1
                        radius: parent.radius + 1
                    }

                    // Accent Glow Line (the "frieren flowers" glow effect)
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1 // Inset for a fine line
                        color: "transparent"
                        border.color: "#A0E6FF" // Bright, ethereal blue/cyan for accent (like the flowers)
                        border.width: 0 // Slightly thicker for more glow
                        radius: parent.radius - 1
                    }

                    // Content container with padding
                    Rectangle {
                        id: contentContainer
                        anchors {
                            fill: parent
                            topMargin: bar.verticalPadding
                            bottomMargin: bar.verticalPadding
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
                                cavaValues: bar.cavaValues
                                useCanvas: bar.useCanvasVisualization
                                waveColor: '#FF9E64'
                                barColor: "transparent" // Use transparent for bar background
                                onToggleVisualization: bar.useCanvasVisualization = !rootContainer.useCanvasVisualization
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
    }
}
