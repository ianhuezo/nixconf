import QtQuick
import Quickshell.Widgets
import qs.services
import qs.config

Item {
    id: root
    anchors.fill: parent
    readonly property list<var> rightWidgets: [
        {
            dog: "cat"
        }
    ]
    signal folderOpen(bool isOpen)
    property string imagePath: ""

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

                    FolderButton {
                        id: folderButton
                        y: {
                            //centers the widget in the border
                            return widgetArea.y + (widgetArea.y + widgetArea.height - folderButton.height) / 2;
                        }
                        onOpened: flag => {
                            root.folderOpen(flag);
                        }
                        onPathAdded: path => {
                            root.imagePath = path;
                        }
                    }

                    Grid {
                        columns: 8
                        rows: 2
                        spacing: 10

                        Repeater {
                            id: coloredCircles
                            model: Color.paletteData

                            Rectangle {
                                id: colorRect
                                width: 20
                                height: 20
                                color: modelData.color
                                radius: AppearanceConfig.calculateRadius(width, height, 'round')
                                border.width: 1
                                border.color: Color.getBorderColor(modelData.color)

                                property bool hovered: false

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onEntered: colorRect.hovered = true
                                    onExited: colorRect.hovered = false
                                }

                                // Tooltip
                                Rectangle {
                                    id: tooltip
                                    width: tooltipText.width + 16
                                    height: tooltipText.height + 12
                                    color: Color.palette.base0E
                                    radius: 6

                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.top
                                    anchors.bottomMargin: 8

                                    visible: colorRect.hovered
                                    opacity: colorRect.hovered ? 1.0 : 0.0

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.InOutQuad
                                        }
                                    }

                                    Text {
                                        id: tooltipText
                                        anchors.centerIn: parent
                                        text: modelData.name + "\n" + colorRect.color.toString().toUpperCase()
                                        color: "white"
                                        font.pixelSize: 11
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    // Tooltip arrow
                                    Rectangle {
                                        width: 8
                                        height: 8
                                        color: tooltip.color
                                        rotation: 45
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.bottom
                                        anchors.topMargin: -4
                                    }
                                }
                            }
                        }
                    }
                }
            }
            ClippingRectangle {
                width: parent.width * 0.5
                height: parent.height * 0.5
                anchors.horizontalCenter: marginedArea.horizontalCenter
                y: widgetArea.y + widgetArea.height + 24
                visible: root.imagePath.toString().length > 0
                clip: true
                radius: 10
                color: 'transparent'
                Image {
                    id: backgroundImageFile
                    anchors.fill: parent
                    mipmap: true
                    fillMode: Image.PreserveAspectFit
                    source: root.imagePath
                    visible: source.toString().length > 0
                    onVisibleChanged: {}
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
