import Quickshell
import QtQuick
import Quickshell.Io
import "root:/config"
import "root:/services"

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
        radius: 25

        Rectangle {
            id: rightSplashPanel
            color: 'transparent'
            anchors.right: parent.right
            width: parent.width * 0.2
            height: parent.height

            Image {
                id: splashArt
                source: FileConfig.splashArtPath
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

            Rectangle {
                id: previewChooser
                color: 'gray'
                anchors.left: parent.left
                height: parent.height
                width: parent.width * 0.05
                topLeftRadius: mainDrawArea.radius
                bottomLeftRadius: mainDrawArea.radius
            }
            Rectangle {
                id: carousel
                anchors.left: parent.left
                x: parent.x + previewChooser.width
                width: (1 - previewChooser.width) * parent.width
                height: parent.height
            }
        }
    }
}
