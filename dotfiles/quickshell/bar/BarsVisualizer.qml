import QtQuick

Row {
    id: bars
    property var cavaValues: []
    property color barColor: 'white'
    spacing: 2

    Repeater {
        model: bars.cavaValues
        delegate: Rectangle {
            width: 6
            height: Math.min(parent.height, Math.max(2, modelData * 1))
            color: bars.barColor
            radius: 2
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
