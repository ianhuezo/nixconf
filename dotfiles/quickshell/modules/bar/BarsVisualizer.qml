import QtQuick

Item {
    id: bars
    property var cavaValues: []
    property color barColor: 'white'
    property bool mirrored: true
    property real sensitivity: 0.5  // Adjust this to control intensity (0.1 = less sensitive, 2.0 = more sensitive)

    Row {
        id: topRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: mirrored ? parent.verticalCenter : parent.bottom
        spacing: 2
        Repeater {
            model: bars.cavaValues
            delegate: Rectangle {
                width: 6
                height: Math.min(mirrored ? bars.height / 2 : bars.height, Math.max(2, modelData * bars.sensitivity))
                color: bars.barColor
                radius: 2
                topLeftRadius: 2
                topRightRadius: 2
                bottomLeftRadius: mirrored ? 0 : 2
                bottomRightRadius: mirrored ? 0 : 2
                anchors.bottom: parent.bottom
                Behavior on height {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }
    Row {
        id: bottomRow
        visible: mirrored
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.verticalCenter
        spacing: 2
        Repeater {
            model: bars.cavaValues
            delegate: Rectangle {
                width: 6
                height: Math.min(bars.height / 2, Math.max(2, modelData * bars.sensitivity))
                color: bars.barColor
                radius: 2
                topLeftRadius: mirrored ? 0 : 2
                topRightRadius: mirrored ? 0 : 2
                bottomLeftRadius: 2
                bottomRightRadius: 2
                anchors.top: parent.top
                Behavior on height {
                    NumberAnimation {
                        duration: 100
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }
    }
}
