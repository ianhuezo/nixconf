import QtQuick
import qs.config

Rectangle {
    id: leftSection
    color: "transparent"

    Row {
        id: leftContent
        anchors.verticalCenter: parent.verticalCenter
        anchors.centerIn: parent
        spacing: 24

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
                source: FileConfig.icons.nix
            }
        }
        Rectangle {
            id: hyprlandRect
            width: 28 * 5 - 8
            height: parent.height
            radius: 10
            color: 'transparent'
            HyprlandWorkspaces {}
        }
    }
}
