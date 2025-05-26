import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Io

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

    source: ''
    Binding {
        id: urlTrackBinding
        target: Mpris.players
        art.source: {
            const players = Array.from(Mpris.players.values);
            let activePlayer = null;

            // 1. Find playing Spotify
            activePlayer = players.find(p => p.identity === "Spotify" && p.playbackStatus === "Playing");

            // 2. If no playing Spotify, find first playing player
            if (!activePlayer) {
                activePlayer = players.find(p => p.playbackStatus === "Playing");
            }

            // 3. Fallback to original behavior: Spotify or first player
            if (!activePlayer) {
                activePlayer = players.find(p => p.identity === "Spotify") || players[0];
            }

            if (activePlayer?.trackArtUrl) {
                return activePlayer.trackArtUrl;
            }
            return '';
        }
    }

    Process {
        id: runImageExtract
        property string mp3File: ""
        property string finalPath: ""
        property int counter: 0
        command: ["rm", "/tmp/FRONT_COVER.jpg", "&&", "eyeD3", "--write-images=/tmp/", "/home/ianh/Music/" + mp3File + ".mp3"]
        running: false
        onRunningChanged: {
            if (running == false) {
                art.source = '/tmp/FRONT_COVER.jpg';
            }
        }
    }

    Rectangle {
        id: placeholder
        anchors.fill: parent
        color: "#303030"  // Darker gray for better contrast
        visible: art.status !== Image.Ready

        // Music note icon as placeholder
        Text {
            anchors.centerIn: parent
            text: "♪"  // Music note symbol
            color: "#808080"
            font.pixelSize: parent.height * 0.6
        }

        // Rounded corners for placeholder too
        radius: 4
    }
}
