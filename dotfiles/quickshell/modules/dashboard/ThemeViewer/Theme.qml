import QtQuick

Item {
    id: root
    anchors.fill: parent
    readonly property list<var> rightWidgets: [
        {
            dog: "cat"
        }
    ]

    Rectangle {
        id: rootArea
        color: 'transparent'
        anchors.fill: parent

        Rectangle {
            id: marginedArea
            color: 'transparent'
            width: parent.width * 0.8
            height: parent.height
            anchors.centerIn: parent
            border.color: 'green'
            border.width: 1

            Rectangle {
                id: widgetArea
                color: 'transparent'
                width: parent.width
                height: parent.height * 0.1
                border.color: 'pink'
                border.width: 1

                Row {
                    spacing: 4

                    Item {
                        FolderButton {
                            id: button
                        }
                    }
                }
            }
            Rectangle {
                id: imageArea
            }
            Rectangle {
                id: colorWidgetArea
                color: 'transparent'
                width: parent.width
                height: parent.height * 0.3
                y: rootArea.y + rootArea.height - height
                border.color: 'red'
                border.width: 1
            }
        }
    }
}
