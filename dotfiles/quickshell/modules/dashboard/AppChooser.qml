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

    readonly property var topLevelModel: [
        {
            appName: 'Applications',
            iconLocation: FileConfig.dashboardAppLauncher,
            selected: true
        }
        // {
        //     appName: 'Music',
        //     iconLocation: FileConfig.musicAppLauncher,
        //     selected: true
        // }
        // {
        //     appName: 'Music',
        //     iconLocation: FileConfig.musicAppLauncher,
        //     selected: false
        // }
    ]

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

        Row {
            anchors.fill: parent
            // anchors.margins: 2
            // spacing: 2

            Repeater {
                model: appChooserContainer.topLevelModel
                Rectangle {
                    id: app
                    width: (parent.width - (appChooserContainer.topLevelModel.length - 1) * parent.spacing) / appChooserContainer.topLevelModel.length
                    height: parent.height
                    color: 'transparent'
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
                            source: modelData.iconLocation
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectFit
                            // mipmap: true
                            smooth: true                        // Enable smooth scaling
                            antialiasing: true                  // Improved rendering quality
                            sourceSize.width: width     // Use 2x resolution for crisp rendering
                            sourceSize.height: height
                            // layer.enabled: true
                            // layer.smooth: true
                            // layer.samples: 8  // Antialiasing samples

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
                            text: modelData.appName
                            font.family: 'JetBrains Mono Nerd Font'
                            font.weight: 500
                            font.pixelSize: 18
                            color: Color.palette.base07
                        }
                        Rectangle {
                            id: appUnderliner
                            width: appText.width * 0.75
                            x: appText.x + 0.15 * width
                            height: 5
                            y: appText.y + appText.height + appTextContainer.underlineMargin
                            radius: 3
                            color: modelData.selected ? Color.palette.base08 : 'transparent'
                        }
                    }
                }
            }
        }
    }
}
