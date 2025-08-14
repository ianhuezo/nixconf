import Quickshell.Io
import QtQuick
import qs.config

Process {
    id: mediaImageExtractMP3
    property string scriptLocation: FileConfig.scripts.extractMP3AlbumImage
    property string mediaFolder  // Default value
    property string mp3FileName

    // Signals
    signal finished(int exitCode)
    signal error(string message)
    signal fileCreated(string fileLocation)

    command: [scriptLocation, mediaFolder, mp3FileName]
    running: false
    // Triggers when FRONT_COVER is created
    stdout: SplitParser {
        onRead: data => {
            mediaImageExtractMP3.fileCreated(data);
        }
    }
    stderr: SplitParser {
        onRead: function (data) {
            mediaImageExtractMP3.error("Error occurred during download: " + data.trim());
        }
    }

    onFinished: {
        running = false;
    }
}
