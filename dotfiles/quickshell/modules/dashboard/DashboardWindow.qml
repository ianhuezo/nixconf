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
        border.color: 'red'
        border.width: 1

        Rectangle {
            id: rightSplashPanel
            color: 'blue'
            anchors.right: parent.right
            width: parent.width * 0.1
            height: parent.height
        }
        Rectangle {
            id: topWallpaperChooser
            color: 'green'
            anchors.top: parent.top
            height: parent.height * 0.2
            width: parent.width * 0.9

            Rectangle {
                id: previewChooser
                color: 'gray'
                anchors.left: parent.left
                height: parent.height
                width: parent.width * 0.05
            }
        }
    }
}
