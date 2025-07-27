import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Io
import "root:/services"
import qs.modules.music_popup

Image {
    id: art
    fillMode: Image.PreserveAspectFit
    sourceSize.width: height
    sourceSize.height: height
    mipmap: true
    smooth: true                        // Enable smooth scaling
    antialiasing: true                  // Improved rendering quality
    asynchronous: true                  // Load image asynchronously
    cache: false

    layer.enabled: true
    layer.smooth: true
    layer.samples: 4  // Antialiasing samples

    source: {
        const players = Array.from(Mpris.players.values);
        let activePlayer = null;

        // 1. Find playing Spotify
        activePlayer = players.find(p => p.identity === "Spotify" && p.playbackState === MprisPlaybackState.Playing);

        // 2. If not playing Spotify, find first playing player
        if (!activePlayer) {
            activePlayer = players.find(p => p.playbackState === MprisPlaybackState.Playing);
        }

        if (activePlayer) {
            let artUrl = activePlayer.trackArtUrl || '';
            if (artUrl == '') {
                let trackTitle = activePlayer.trackTitle || '';
                if (trackTitle != '') {
                    extractMP3Image.mp3FileName = trackTitle + '.mp3';
                    extractMP3Image.running = true;
                    extractMP3Image.mp3FileName = '';
                }
            }
            return activePlayer.trackArtUrl || '';
        }

        // 3. Fallback to original behavior: Spotify or first player
        if (!activePlayer) {
            activePlayer = players.find(p => p.identity === "Spotify") || players[0];
        }

        return activePlayer?.trackArtUrl || '';
    }

    ExtractMP3Image {
        id: extractMP3Image
        mediaFolder: '~/Music'
        mp3FileName: ''
        property string localFileName: ''

        onFileCreated: fileName => {
            art.source = '';
            art.source = fileName;
        }
    }

    Rectangle {
        id: placeholder
        anchors.fill: parent
        color: Color.palette.base03// Darker gray for better contrast
        visible: art.status !== Image.Ready

        // Music note icon as placeholder
        Text {
            anchors.centerIn: parent
            text: "♪"  // Music note symbol
            color: Color.palette.base09
            font.pixelSize: parent.height * 0.6
        }

        // Rounded corners for placeholder too
        radius: 4
    }
}
