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

    // Separate property to determine the art URL
    property string artUrl: {
        const players = Array.from(Mpris.players.values);
        let activePlayer = null;
        extractMP3Image.localFilePath = '';

        // 1. Find playing Spotify
        activePlayer = players.find(p => p.identity === "Spotify" && p.playbackState === MprisPlaybackState.Playing);

        // 2. If not playing Spotify, find first playing player
        if (!activePlayer) {
            activePlayer = players.find(p => p.playbackState === MprisPlaybackState.Playing);
        }

        if (activePlayer) {
            let url = activePlayer.trackArtUrl || '';

            if (url == '') {
                let trackTitle = activePlayer.trackTitle || '';
                if (trackTitle != '') {
                    extractMP3Image.mp3FileName = trackTitle + '.mp3';
                    extractMP3Image.running = true;
                }
            }
            return url;
        }

        // 3. Fallback to original behavior: Spotify or first player
        if (!activePlayer) {
            activePlayer = players.find(p => p.identity === "Spotify") || players[0];
        }

        return activePlayer?.trackArtUrl || '';
    }

    // Bind source to either local file or artUrl
    source: extractMP3Image.localFilePath != '' ? extractMP3Image.localFilePath : artUrl

    ExtractMP3Image {
        id: extractMP3Image
        mediaFolder: '/home/ianh/Music'
        mp3FileName: ''
        property string localFilePath: ''

        onFileCreated: fileName => {
            localFilePath = fileName;
            art.sourceChanged(); // Still needed for same filename, different content
            extractMP3Image.running = false;
        }

        onError: error => {}

        // Clear local file when track changes
        onMp3FileNameChanged: {
            localFilePath = '';
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
