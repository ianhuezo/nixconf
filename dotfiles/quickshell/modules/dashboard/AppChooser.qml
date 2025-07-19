import QtQuick
import "root:/config"
import "root:/services"

Rectangle {
    id: appChooserContainer
    color: 'transparent'
    anchors.top: parent.top
    height: parent.height * 0.2
    width: parent.width * 0.8
    topLeftRadius: mainDrawArea.radius

    Rectangle {
        id: narrowedAppChooser
        implicitWidth: appChooserContainer.width * 0.86
        implicitHeight: appChooserContainer.height * 0.9
        x: parent.x + appChooserContainer.width * 0.075
        y: parent.y + appChooserContainer.height * 0.15
        // implicitHeight:

        color: 'transparent'
        // border.color: 'purple'
        // border.width: 1

        Rectangle {
            id: app
            width: (parent.width * 0.20)
            height: parent.height
            color: 'transparent'
            anchors.centerIn: parent
            Rectangle {
                id: appIcon
                width: parent.width
                height: parent.height * 0.75
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                color: 'transparent'
                Image {
                    anchors.centerIn: parent
                    source: FileConfig.dashboardAppLauncher
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectFit
                }
            }
            Rectangle {
                id: appTextContainer
                property var underlineMargin: 2
                width: parent.width
                height: parent.height * 0.25
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                color: 'transparent'
                Text {
                    id: appText
                    anchors.centerIn: parent
                    text: 'Applications'
                    font.family: 'JetBrains Mono Nerd Font'
                    font.weight: 500
                    font.pixelSize: 18
                    color: Color.palette.base07
                }
                Rectangle {
                    id: appUnderliner
                    width: parent.width
                    height: 5
                    y: appText.y + appText.height + appTextContainer.underlineMargin
                    radius: 3
                    color: Color.palette.base08
                }
            }
        }
    }
}
