import Quickshell.Io
import QtQuick
import "root:/config"

Process {
    id: metadataMP3Attachment
    property string scriptLocation: FileConfig.scripts.saveMP3
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
