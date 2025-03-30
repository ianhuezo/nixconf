import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Io

Image {
    id: art
    fillMode: Image.PreserveAspectFit
    sourceSize.width: height
    sourceSize.height: height
    mipmap: true
    cache: false

    source: ''
    Binding {
        id: urlTrackBinding
        target: Mpris.players
        art.source: {
            const players = Mpris.players.values;
            const spotify = players.find(p => p.identity === "Spotify");
            const trackArtUrl = spotify?.trackArtUrl ?? players[0]?.trackArtUrl ?? "";
            console.log("CHANGED");
            if (trackArtUrl != "") {
                return trackArtUrl;
            }
            runImageExtract.mp3File = spotify?.trackTitle;
            runImageExtract.running = true;
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
        anchors.fill: parent
        color: "gray"
        visible: parent.status !== Image.Ready
    }
}
