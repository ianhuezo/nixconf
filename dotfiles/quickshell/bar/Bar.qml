import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

Scope {
    id: root
    property var cavaValues: []
    property bool useCanvasVisualization: true
    property var barOffsetY: 8  // Renamed from barOffset
    property var barOffsetX: 10 // New horizontal offset property
    property var verticalPadding: 8 // Padding for top and bottom of the inner bar

    readonly property color base00: "#0D121B" // Deepest background
    readonly property color base01: "#111A2C" // Slightly lighter background
    readonly property color base02: "#1A263B" // Mid-dark background
    readonly property color base03: "#2A3E5C" // Foreground Dim / Subtle border
    readonly property color base04: "#6C8CB7" // Foreground Mid
    readonly property color base05: "#E0F2F7" // Foreground Light / Primary text
    readonly property color base06: "#F0F8FA" // Foreground Lighter
    readonly property color base07: "#FDFEFF" // Foreground Lightest
    readonly property color base0B: "#A0E6FF" // Glowing Cyan-Blue (excellent for accents)
    readonly property color base0C: "#89DDFF" // Cyan (another great accent)
    readonly property color base0D: "#7AA2F7" // Blue (deeper accent)

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
                        topMargin: root.verticalPadding
                        bottomMargin: root.verticalPadding
                        leftMargin: root.barOffsetX
                        rightMargin: root.barOffsetX
                    }
                    color: root.base01
                    radius: 8 // Optional: rounded corners for the bar

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blur: 10 // Still apply blur to the background
                        // --- NEW: Glow Effect ---
                        // You can combine blur and glow directly here!
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

                        // Optional: Add a subtle glow effect (requires ShaderEffect or custom rendering)
                        // For a simple demo, we'll keep it as a border.
                    }

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
                                spacing: 30

                                Rectangle {
                                    id: nixosRect
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
                                Rectangle {
                                    id: hyprlandRect
                                    width: parent.width / 1.1
                                    height: 20
                                    radius: 10
                                    color: 'transparent'
                                    HyprlandWorkspaces {}
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
