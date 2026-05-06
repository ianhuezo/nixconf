import QtQuick
import QtQuick.Window
import Quickshell.Services.Mpris
import qs.components

Rectangle {
    id: container
    property var cavaValues: []
    property string mode: "wave"
    property color waveColor: 'white'
    property color barColor: 'black'
    property string trackTitle: ""
    signal toggleVisualization
    signal toggleMusicDownloader
    anchors.fill: parent
    color: barColor
    width: 166
    height: parent.height

    function preferredPlayer() {
        const players = Array.from(Mpris.players.values);
        const playing = players.find(p => p.playbackState === MprisPlaybackState.Playing);
        return playing || players.find(p => p.identity === "Spotify") || players[0] || null;
    }

    function refreshTrackTitle() {
        container.trackTitle = preferredPlayer()?.trackTitle || "";
    }

    Component.onCompleted: refreshTrackTitle()

    Connections {
        target: Mpris
        function onPlayersChanged() {
            container.refreshTrackTitle();
        }
    }

    Connections {
        target: container.preferredPlayer()
        ignoreUnknownSignals: true
        function onPostTrackChanged() {
            container.refreshTrackTitle();
        }
        function onPlaybackStateChanged() {
            container.refreshTrackTitle();
        }
    }

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
                cavaValues: container.cavaValues
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
                mode: container.mode
                title: container.trackTitle
                mirrored: true
                sensitivity: container.mode === "wave" ? 1.0 : 0.9
            }

            MouseArea {
                anchors.fill: parent
                onClicked: container.toggleVisualization()
            }
        }
    }
}
