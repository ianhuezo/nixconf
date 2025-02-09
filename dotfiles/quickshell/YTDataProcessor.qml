import Quickshell.Io
import QtQuick

Process {
    id: mediaDownloadProcess
    property string scriptLocation: Qt.resolvedUrl("../scripts/yt_to_mp3/youtube_dl.sh")
    property string bitrate: "192"  // Default value
    property string downloadUrl: ""

    // Core configuration
    command: [scriptLocation, bitrate, downloadUrl]
    running: false

    // Progress parsing
    stdout: SplitParser {
        onRead: data => {
            const regex = /(\d+\.?\d*)%.*?({.*})/;
            const match = data.match(regex);
            if (match) {
                const percentage = match[1];
                const jsonObject = JSON.parse(match[2]);
                mediaDownloadProcess.downloading(percentage, jsonObject);
            }
        }
    }
    stderr: SplitParser {
        onRead: function (data) {
            mediaDownloadProcess.error("Error occurred during download: " + data.trim());
        }
    }

    // Signals
    signal finished
    signal error(string message)
    signal percentage(var percent)
    signal downloading(var percent, var info)

    // Process lifecycle handlers
    onFinished: {
        if (exited() !== 0) {
            // Check if there's an error message from stderr
            const errorMessage = mediaDownloadProcess.readAllStandardError();
            if (errorMessage.length > 0) {
                error(errorMessage.trim());
            } else {
                error("Script execution failed with exit code " + exitCode);
            }
        } else {
            finished();
        }
    }
    onError: error()
    onDownloading: downloading()
}
