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

            readonly property int targetY: container.y + container.height + 8

            x: container.x + container.width * 2
            y: targetY
            color: 'transparent'
            //onYChanged: {
            //    const progress = 1 - ((y - targetY) / (startY - targetY));
            //    visible = progress >= triggerThreshold;
            //    opacity: Math.min(1, progress * 1.5); // Smooth fade-in
            //}

            //NumberAnimation {
            //    id: slideIn
            //    target: popupWindow
            //    property: "y"
            //    from: popupWindow.targetY - 300
            //    to: popupWindow.targetY
            //    duration: 1000
            //    easing.type: Easing.InOutQuad
            //    onStarted: {
            //        popupWindow.show();
            //    }
            //    onFinished: popupLoader.active = false
            //}
            YoutubeConversionContainer {}
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
