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
            duration: 300
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

        // Three-section layout
        Row {
            anchors.fill: parent
            anchors.margins: (isBarBordered && !isSectionedBar) ? 1 : 0
            spacing: 0
            z: 2

            // LEFT SECTION
            Item {
                id: leftSection
                width: parent.width / 8
                height: parent.height

                // Outer rectangle acts as border (only for separate sections)
                Rectangle {
                    anchors.fill: parent
                    color: barBorderColor
                    radius: panelRadius
                    visible: isBarBordered && isSectionedBar
                    z: 0
                }

                // Inner rectangle (actual content)
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

            // CENTER SPACER
            Item {
                width: (parent.width - leftSection.width - centerSection.width - rightSection.width) / 2
                height: parent.height
            }

            // CENTER SECTION
            Item {
                id: centerSection
                width: parent.width / 7
                height: parent.height

                // Outer rectangle acts as border (only for separate sections)
                Rectangle {
                    anchors.fill: parent
                    color: barBorderColor
                    radius: panelRadius
                    visible: isBarBordered && isSectionedBar
                    z: 0
                }

                // Inner rectangle (actual content)
                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: (isBarBordered && isSectionedBar) ? 1 : 0
                    color: Color.palette.base01
                    radius: (isBarBordered && isSectionedBar) ? panelRadius - 1 : panelRadius
                    z: 1

                    VisualizerContainer {
                        anchors.centerIn: parent
                        height: isSectionedBar ? parent.height : parent.height - 4
                        cavaValues: panel.cavaValues
                        useCanvas: panel.useCanvasVisualization
                        waveColor: panel.widgetMainColor
                        barColor: "transparent"
                        onToggleVisualization: panel.useCanvasVisualization = !panel.useCanvasVisualization
                    }
                }
            }

            // RIGHT SPACER
            Item {
                width: (parent.width - leftSection.width - centerSection.width - rightSection.width) / 2
                height: parent.height
            }

            // RIGHT SECTION
            Item {
                id: rightSection
                width: parent.width / 8
                height: parent.height

                // Outer rectangle acts as border (only for separate sections)
                Rectangle {
                    anchors.fill: parent
                    color: barBorderColor
                    radius: panelRadius
                    visible: isBarBordered && isSectionedBar
                    z: 0
                }

                // Inner rectangle (actual content)
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: (isBarBordered && isSectionedBar) ? 1 : 0
                    color: Color.palette.base01
                    radius: (isBarBordered && isSectionedBar) ? panelRadius - 1 : panelRadius
                    z: 1

                    Row {
                        id: statsRow
                        anchors {
                            verticalCenter: parent.verticalCenter
                            horizontalCenter: parent.horizontalCenter
                        }
                        height: parent.height
                        layoutDirection: Qt.RightToLeft
                        spacing: 4  // Reduced for sectioned mode

                        property var statsData: [
                            {
                                percentage: GetGPU.gpu,
                                statText: GetGPU.gpu + "%",
                                iconSource: FileConfig.icons.gpu
                            },
                            {
                                percentage: GetCPU.cpu,
                                statText: GetCPU.cpu + "%",
                                iconSource: FileConfig.icons.cpu
                            },
                            {
                                percentage: GetRam.ram,
                                statText: GetRam.ram + "%",
                                iconSource: FileConfig.icons.ram
                            }
                        ]
                        Repeater {
                            model: statsRow.statsData
                            delegate: CircleProgress {
                                percentage: modelData.percentage
                                statText: modelData.statText
                                iconSource: modelData.iconSource
                                textColor: panel.widgetMainColor
                                backgroundColor: Color.palette.base01
                                progressColor: panel.widgetMainColor
                                color: panel.color
                            }
                        }
                    }
                }
            }
        }
    }
}
