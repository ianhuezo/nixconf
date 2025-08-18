import QtQuick
import qs.services
import qs.config
import Quickshell.Widgets

Item {
    id: root

    // Public properties
    property bool isVisible: false
    property real progress: 0  // 0-100
    property string title: "Processing..."
    property bool showPercentage: true
    property bool enablePulseAnimation: true
    property real containerWidth: parent.width
    property real containerHeight: 250

    // Configurable colors
    property string progressColor: Color.palette.base09
    property string progressGlowColor: Qt.lighter(progressColor, 1.2)
    property string backgroundColor: "transparent"
    property string progressBarBackgroundColor: Qt.darker(backgroundColor, 1.5)
    property string progressBarBorderColor: Qt.lighter(backgroundColor, 1.2)
    property string titleTextColor: Color.palette.base07
    property string percentageTextColor: Color.palette.base07
    property string containerColor: 'transparent'
    property string progressSectionBackgroundColor: Color.palette.base03
    property string progressSectionBorderColor: Color.palette.base03
    property string inactiveProgressColor: Color.palette.base03
    property string inactiveProgressBorderColor: Color.palette.base04

    // Progress section properties
    property bool showProgressSection: true
    property real progressSectionRadius: 8

    // Signals
    signal clicked
    signal progressComplete

    // Auto-emit completion signal when progress reaches 100
    onProgressChanged: {
        if (progress >= 100) {
            progressComplete();
        }
    }

    visible: root.isVisible
    anchors.fill: parent

    // Progress container
    Rectangle {
        id: progressContainer
        width: root.containerWidth * 0.5
        height: root.containerHeight
        anchors.centerIn: parent
        color: root.containerColor
        radius: 12

        Column {
            anchors.centerIn: parent
            spacing: 15
            width: parent.width

            // Title text
            Text {
                id: titleText
                text: root.title
                color: root.titleTextColor
                font.pixelSize: 16
                font.weight: Font.Medium
                width: parent.width
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            ClippingRectangle {
                width: 200
                height: 200
                anchors.horizontalCenter: parent.horizontalCenter           // Animated GIF
                radius: 10
                AnimatedImage {
                    id: animation
                    anchors.fill: parent
                    source: FileConfig.downloadingVideoMP3
                    fillMode: Image.PreserveAspectFit
                }
            }

            // Progress section container
            Rectangle {
                id: progressSection
                width: parent.width * 0.8
                height: 60
                anchors.horizontalCenter: parent.horizontalCenter
                color: 'transparent'
                visible: root.showProgressSection

                Column {
                    anchors.centerIn: parent
                    spacing: 10
                    width: parent.width * 0.9

                    Rectangle {
                        id: progressBarBg
                        width: parent.width
                        height: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: root.progressBarBackgroundColor
                        radius: 4
                        border.color: root.progressBarBorderColor
                        border.width: 1

                        // Progress bar fill

                        Rectangle {
                            id: progressBarOutlineContainer
                            width: parent.width
                            height: parent.height
                            color: root.inactiveProgressColor
                            border.width: 1
                            border.color: root.inactiveProgressBorderColor
                            radius: parent.radius
                        }
                        Rectangle {
                            id: progressBarFill
                            width: parent.width * Math.max(0, Math.min(100, root.progress)) / 100
                            height: parent.height
                            color: root.progressColor
                            radius: parent.radius
                            clip: true

                            Behavior on width {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutQuad
                                }
                            }

                            // Subtle glow effect
                            Rectangle {
                                anchors.fill: parent
                                color: root.progressGlowColor
                                radius: parent.radius
                                opacity: 0.5
                            }
                        }
                    }

                    // Percentage text
                    Text {
                        text: Math.round(Math.max(0, Math.min(100, root.progress))) + "%"
                        color: root.percentageTextColor
                        font.pixelSize: 16
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: root.showPercentage
                    }
                }
            }
        }

        // Pulsing animation
        SequentialAnimation {
            running: root.visible && root.enablePulseAnimation
            loops: Animation.Infinite

            PropertyAnimation {
                target: progressContainer
                property: "opacity"
                from: 0.9
                to: 1.0
                duration: 1000
                easing.type: Easing.InOutQuad
            }
            PropertyAnimation {
                target: progressContainer
                property: "opacity"
                from: 1.0
                to: 0.9
                duration: 1000
                easing.type: Easing.InOutQuad
            }
        }
    }

    // Convenience functions
    function show(initialTitle) {
        if (initialTitle !== undefined) {
            root.title = initialTitle;
        }
        root.isVisible = true;
        root.progress = 0;
    }

    function hide() {
        root.isVisible = false;
    }

    function updateProgress(newProgress, newTitle) {
        root.progress = newProgress;
        if (newTitle !== undefined) {
            root.title = newTitle;
        }
    }

    function reset() {
        root.progress = 0;
        root.title = "Processing...";
        root.isVisible = false;
    }
}
