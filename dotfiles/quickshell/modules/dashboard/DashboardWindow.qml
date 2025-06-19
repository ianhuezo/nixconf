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
        anchors.fill: parent
        color: Color.palette.base00
        border.color: 'red'
        border.width: 1
    }
}
