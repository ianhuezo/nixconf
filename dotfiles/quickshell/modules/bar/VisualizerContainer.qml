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
                onClicked: event => {}
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
