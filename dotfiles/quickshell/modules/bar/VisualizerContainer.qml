import QtQuick
import QtQuick.Window
import qs.components

Rectangle {
    id: container
    property var cavaValues: []
    property bool useCanvas: true
    property color waveColor: 'white'
    property color barColor: 'black'
    signal toggleVisualization
    signal toggleMusicDownloader
    anchors.fill: parent
    color: barColor
    width: 166
    height: parent.height

    Row {
        height: parent.height
        spacing: 5
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter

        Item {
            id: imageButton
            width: parent.height
            height: parent.height

            NowPlayingArt {
                id: playingArt
                height: parent.height
                width: parent.height
            }
            MouseArea {
                anchors.fill: playingArt
                onClicked: event => {}
            }
        }
        Item {
            id: vizContainer
            height: parent.height
            width: 166

            AudioVisualizer {
                id: visualizer
                anchors.fill: parent
                cavaValues: container.cavaValues
                visualizerColor: container.waveColor
                mode: container.useCanvas ? "wave" : "bars"
                mirrored: true
                sensitivity: container.useCanvas ? 1.0 : 0.5
            }

            MouseArea {
                anchors.fill: parent
                onClicked: container.toggleVisualization()
            }
        }
    }
}
