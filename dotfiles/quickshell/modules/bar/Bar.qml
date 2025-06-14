import Quickshell
import QtQuick
import QtQuick.Effects

Item {
    id: bar
    property var active: true
    property var cavaValues: []
    property bool useCanvasVisualization: true
    property var barOffsetY: 8  // Renamed from barOffset
    property var barOffsetX: 10 // New horizontal offset property
    property var verticalPadding: 8 // Padding for top and bottom of the inner bar
    property var mainMonitor: Quickshell.screens.filter(screen => screen.name == "DP-1")

    readonly property color base00: "#0D121B" // Deepest background
    readonly property color base01: "#111A2C" // Slightly lighter background
    readonly property color base02: "#1A263B" // Mid-dark background
    readonly property color base03: "#2A3E5C" // Foreground Dim / Subtle border
    readonly property color base04: "#6C8CB7" // Foreground Mid
    readonly property color base05: "#E0F2F7" // Foreground Light / Primary text
    readonly property color base06: "#F0F8FA" // Foreground Lighter
    readonly property color base07: "#FDFEFF" // Foreground Lightest
    readonly property color base09: "#FF9E64" // Foreground Lightest
    readonly property color base0B: "#A0E6FF" // Glowing Cyan-Blue (excellent for accents)
    readonly property color base0C: "#89DDFF" // Cyan (another great accent)
    readonly property color base0D: "#7AA2F7" // Blue (deeper accent)
    Loader {
        active: bar.active
        Variants {
            model: {
                return bar.mainMonitor;
            }
            CavaDataProcessor {
                id: cavaProcessor
                onNewData: processedValues => bar.cavaValues = processedValues
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
                        color: bar.base01
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
                                        iconSource: '../../../assets/icons/gpu.svg'
                                    },
                                    {
                                        percentage: cpuPercentage,
                                        statText: cpuPercentage + "%",
                                        iconSource: '../../../assets/icons/cpu.svg'
                                    },
                                    {
                                        percentage: ramPercentage,
                                        statText: ramPercentage + "%",
                                        iconSource: '../../../assets/icons/ram.svg'
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
                                        textColor: bar.base09
                                        backgroundColor: bar.base01
                                        progressColor: bar.base09
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
}
