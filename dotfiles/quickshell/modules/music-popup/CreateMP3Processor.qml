import Quickshell.Io
import QtQuick

Process {
    id: metadataMP3Attachment
    property string scriptLocation: Qt.resolvedUrl("../scripts/yt_to_mp3/create_mp3_metadata.sh")
    property string albumArtPath: ""
    property string mp3Path: ""
    property string outputPath: "/home/ianh/Music"
    property string albumName: ""
    property string albumArtist: ""

    // Signals
    signal finished(int exitCode)
    signal error(string message)

    // Core configuration
    command: [scriptLocation, albumName, albumArtist, albumArtPath, mp3Path, outputPath]
    running: false
    // Progress parsing
    stderr: SplitParser {
        onRead: function (data) {
            metadataMP3Attachment.error("Error occurred during mp3 metadata tagging: " + data.trim());
        }
    }

    onFinished: {
        running = false;
    }
}
