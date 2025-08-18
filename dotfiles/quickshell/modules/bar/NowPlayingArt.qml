import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Io
import "root:/services"
import qs.modules.music_popup

Image {
    id: root
    fillMode: Image.PreserveAspectFit
    sourceSize.width: height
    sourceSize.height: height
    mipmap: true
    smooth: true                        // Enable smooth scaling
    antialiasing: true                  // Improved rendering quality
    asynchronous: true                  // Load image asynchronously
    cache: true
    layer.enabled: true
    layer.smooth: true
    layer.samples: 4  // Antialiasing samples
    // Separate property to determine the art URL
    property var currentPlayer: null
    property string defaultFilePath: root.getPreferredPlayer()?.trackArtUrl || ""
    property string filePath: ""
    property string localTrackFile: ""
    property string currentSource: "" // Add this property to break the binding loop

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
        if (activePlayer?.identity == "Spotify") {
            const trackTitle = activePlayer.trackTitle;
            root.localTrackFile = trackTitle;
        }
        return activePlayer;
    }

    function updateSource() {
        let baseSource = root.defaultFilePath || root.getPreferredPlayer()?.trackArtUrl || extractMP3Image.localFilePath || "";
        // Add cache busting for local files based on current timestamp
        if (baseSource && baseSource.startsWith("file://")) {
            baseSource += "?t=" + Date.now();
        }
        root.currentSource = baseSource;
    }

    Component.onCompleted: updateSource()
    onDefaultFilePathChanged: updateSource()

    Connections {
        target: root.getPreferredPlayer() || null
        ignoreUnknownSignals: true
        function onPostTrackChanged() {
            root.defaultFilePath = null; //no longer need a default
            root.filePath = target?.trackArtUrl || "";
            if (root.filePath === "" && target?.identity === "Spotify") {
                const trackTitle = target?.trackTitle;
                root.localTrackFile = trackTitle;
            }
            root.updateSource(); // Update source after track change
        }
    }
    onLocalTrackFileChanged: {
        if (root.localTrackFile.length <= 0) {
            return;
        }
        extractMP3Image.mp3FileName = root.localTrackFile + '.mp3';
        extractMP3Image.running = true;
    }
    // Use the stable property instead of the complex binding
    source: currentSource
    ExtractMP3Image {
        id: extractMP3Image
        mediaFolder: '/home/ianh/Music'
        mp3FileName: ''
        property string localFilePath: ''
        onFileCreated: fileName => {
            localFilePath = fileName;
            extractMP3Image.running = false;
            root.sourceChanged(localFilePath);
            root.updateSource(); // Update source when local file is ready
        }
        onError: error => {}
        // Clear local file when track changes
        onMp3FileNameChanged: {
            localFilePath = '';
            root.updateSource(); // Update source when local file is cleared
        }
    }
    Rectangle {
        id: placeholder
        anchors.fill: parent
        color: Color.palette.base03// Darker gray for better contrast
        visible: root.status !== Image.Ready
        // Music note icon as placeholder
        Text {
            anchors.centerIn: parent
            text: "♪"  // Music note symbol
            color: Color.palette.base09
            font.pixelSize: 16
        }
        // Rounded corners for placeholder too
        radius: 4
    }
}
