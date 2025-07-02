import Quickshell
import QtQuick
import Quickshell.Io
import "root:/config"
import "root:/services"
import QtQuick.Effects

PanelWindow {
    property var modelData
    required property var parentId
    color: 'transparent'
    implicitWidth: parentId.implicitWidth
    implicitHeight: parentId.implicitHeight
    Rectangle {
        id: mainDrawArea
        anchors.fill: parent
        color: Color.palette.base00
        radius: 20

        Rectangle {
            id: rightSplashPanel
            anchors.right: parent.right
            width: parent.width * 0.2
            height: parent.height
            bottomRightRadius: mainDrawArea.radius
            topRightRadius: mainDrawArea.radius
            smooth: true
            antialiasing: true

            Rectangle {
                id: splashPanel
                width: parent.width
                height: parent.height
                bottomRightRadius: parent.bottomRightRadius
                topRightRadius: parent.topRightRadius
                smooth: true
                antialiasing: true
                color: 'transparent'

                MultiEffect {
                    source: splashPanel
                    anchors.fill: splashPanel
                    shadowEnabled: true
                    shadowOpacity: 0.3
                    shadowBlur: 0.8
                    shadowHorizontalOffset: 2
                    shadowVerticalOffset: 2
                    shadowColor: "#000000"
                }

                Image {
                    id: splashArt
                    source: FileConfig.splashArtPath
                    fillMode: Image.PreserveAspectCrop
                    anchors.leftMargin: -10
                    visible: false
                    anchors.fill: parent
                    antialiasing: true
                }

                MultiEffect {
                    source: splashArt
                    anchors.fill: parent
                    maskEnabled: true
                    maskSource: mask
                    antialiasing: true
                }

                Item {
                    id: mask
                    anchors.fill: parent
                    layer.enabled: true
                    visible: false
                    layer.samples: 4  // Add multisampling
                    layer.smooth: true
                    antialiasing: true

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1  // Slight expansion to avoid edge artifacts
                        topRightRadius: splashPanel.topRightRadius
                        bottomRightRadius: splashPanel.bottomRightRadius
                        topLeftRadius: 0
                        bottomLeftRadius: 0
                        color: "white"
                        smooth: true
                        antialiasing: true
                    }
                }
            }
        }
        Rectangle {
            id: topWallpaperChooser
            color: 'transparent'
            anchors.top: parent.top
            height: parent.height * 0.2
            width: parent.width * 0.8
            topLeftRadius: mainDrawArea.radius
            bottomLeftRadius: mainDrawArea.radius

        }
    }
}
