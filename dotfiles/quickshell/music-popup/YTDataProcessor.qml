import Quickshell.Io
import QtQuick

Process {
    id: mediaDownloadProcess
    property string scriptLocation: Qt.resolvedUrl("../scripts/yt_to_mp3/youtube_dl.sh")
    property string bitrate: "192"  // Default value
    property string downloadUrl: ""

    // Signals
    signal finished(int exitCode)
    signal error(string message)
    signal downloading(real percent, var info)

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
            } else {
                try {
                    const jsonObject = JSON.parse(data);
                    mediaDownloadProcess.downloading(100, jsonObject);
                } catch (e) {}
            }
        }
    }
    stderr: SplitParser {
        onRead: function (data) {
            mediaDownloadProcess.error("Error occurred during download: " + data.trim());
        }
    }

    onFinished: {
        running = false;
    }
}
