import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: container
    property var cavaValues: []
    property bool useCanvas: true
    property color waveColor: 'white'
    property color barColor: 'black'
    signal toggleVisualization
    signal toggleMusicDownloader

    color: barColor
    width: 166
    height: 32

    Row {
        anchors.centerIn: parent
        height: parent.height
        width: Math.min(parent.width, implicitWidth)

        Item {
            id: imageButton
            width: parent.height
            height: parent.height
            NowPlayingArt {
                id: playingArt
                height: parent.height
                width: parent.width
            }
            MouseArea {
                anchors.fill: playingArt
                onClicked: event => {
                    if (popupWindow.active) {
                        popupWindow.hide();
                        return;
                    }
                    if (!popupWindow.active) {
                        popupWindow.show();
                    }
                }
            }
        }

        Item {
            id: vizContainer
            height: parent.height
            width: loader.width

            Loader {
                id: loader
                sourceComponent: container.useCanvas ? waveComponent : barComponent
                height: parent.height
                width: 166
            }

            MouseArea {
                anchors.fill: parent
                onClicked: container.toggleVisualization()
            }
        }
    }
    Loader {
        id: popupLoader
        Window {
            id: popupWindow
            width: 400
            height: 300
            flags: Qt.FramelessWindowHint | Qt.Popup

            readonly property int targetY: container.y + container.height

            x: container.x + (container.width - width) / 2
            y: targetY
            color: 'transparent'

            Rectangle {
                anchors.fill: parent
                color: '#171D23'
                border.color: '#FF9E64'
                border.width: 4
                radius: 10

                Rectangle {
                    id: imageUploadedArea
                    width: parent.width
                    height: parent.height * 0.5
                    radius: parent.radius
                    color: 'transparent'

                    Image {
                        id: youtubeMediaSvg
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        fillMode: Image.PreserveAspectFit
                        source: '../assets/icons/media.svg'
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            brightness: 1.0
                            colorization: 1.0
                            colorizationColor: '#E8E8E8'
                        }
                    }
                }
                Rectangle {
                    id: imageTextInputs
                    width: parent.width
                    color: 'transparent'
                    y: imageUploadedArea.y + imageUploadedArea.height
                    height: parent.height * 0.5
                    radius: parent.radius

                    Rectangle {
                        id: textInputBottom
                        width: parent.width * 0.8
                        height: 2
                        radius: 1
                        x: parent.x + (parent.width - textInputBottom.width) / 2
                        y: parent.height * 0.2 + 8
                        color: '#E8E8E8'
                    }
                    Rectangle {
                        id: textInputBox
                        height: parent.height * 0.2 + 4
                        width: textInputBottom.width
                        x: textInputBottom.x
                        color: 'transparent'
                        TextField {
                            id: textInput
                            placeholderText: qsTr("Add Link...")
                            placeholderTextColor: '#828282'
                            anchors.fill: parent
                            width: parent.width
                            height: parent.height
                            readOnly: false
                            color: 'white'
                            background: Rectangle {
                                color: '#1e262e'
                                radius: 5
                            }
                        }
                    }
                }
            }
        }
    }
    Component {
        id: waveComponent
        WaveVisualizer {
            cavaValues: container.cavaValues
            waveColor: container.waveColor
            height: parent.height
        }
    }

    Component {
        id: barComponent
        BarsVisualizer {
            cavaValues: container.cavaValues
            barColor: container.waveColor
            height: parent.height
        }
    }
}
