import QtQuick
import QtQuick.Window

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
            width: 166  // Move the explicit width here instead of in the Loader
            Loader {
                id: loader
                sourceComponent: container.useCanvas ? waveComponent : barComponent
                height: parent.height
                anchors.fill: parent  // Fill the vizContainer
            }
            MouseArea {
                anchors.fill: parent
                onClicked: container.toggleVisualization()
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
