import QtQuick
import Quickshell.Services.Mpris

Image {
    id: art
    fillMode: Image.PreserveAspectFit
    sourceSize.width: height
    sourceSize.height: height
    mipmap: true
    cache: false

    source: {
        const players = Mpris.players.values;
        const spotify = players.find(p => p.identity === "Spotify");
        return spotify?.trackArtUrl ?? players[0]?.trackArtUrl ?? "";
    }

    Rectangle {
        anchors.fill: parent
        color: "gray"
        visible: parent.status !== Image.Ready
    }
}
