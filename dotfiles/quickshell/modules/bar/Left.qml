import QtQuick
import "../../config" as Config

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
                source: Config.FileConfig.nixIcon
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
