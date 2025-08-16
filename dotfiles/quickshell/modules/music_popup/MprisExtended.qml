pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Scope {
    id: root
    property string currentTrackTitle: ""
    property var currentPlayer: null
    property string defaultFilePath: root.getPreferredPlayer()?.trackArtUrl || ""
    property string filePath: ""
    function getPreferredPlayer() {
        let activePlayer = null;
        let players = Array.from(Mpris.players.values);
        activePlayer = players.find(p => p.identity === "Spotify" && p.playbackState === MprisPlaybackState.Playing);
        if (!activePlayer) {
            activePlayer = players.find(p => p.playbackState === MprisPlaybackState.Playing);
        }
        if (!activePlayer) {
            activePlayer = players.find(p => p.identity === "Spotify") || players[0];
        }
        return activePlayer;
    }
    Connections {
        target: root.getPreferredPlayer()
        ignoreUnknownSignals: true
        function onPostTrackChanged() {
            root.defaultFilePath = ""; //no longer need a default
            root.filePath = target.trackArtUrl || "";
            if (root.filePath === "" && target.identity === "Spotify") {
                const trackTitle = target.trackTitle;
            }
        }
    }
}
