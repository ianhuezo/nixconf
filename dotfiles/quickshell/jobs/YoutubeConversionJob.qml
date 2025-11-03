import QtQuick
import Quickshell.Io
import qs.config
import "." as Jobs

Jobs.BaseJob {
    id: job

    // Expected args: [downloadUrl, bitrate, destinationPath]
    property string downloadUrl: args.length > 0 ? args[0] : ""
    property string bitrate: args.length > 1 ? args[1] : "192"
    property string destinationPath: args.length > 2 ? args[2] : ""

    // Job metadata
    jobName: "YouTube Download"
    notificationIcon: "emblem-downloads"
    enableProgressNotifications: false // Don't spam with progress notifications

    // Internal state
    property var _processor: null
    property var _resultData: null

    function execute() {
        if (!downloadUrl || downloadUrl.length === 0) {
            _setFailed("No download URL provided");
            return;
        }

        // Create YTDataProcessor
        _processor = Qt.createQmlObject(`
            import QtQuick
            import Quickshell.Io
            import qs.config

            Process {
                id: proc
                property string scriptLocation: FileConfig.scripts.downloadYoutube
                property string bitrate: "${bitrate}"
                property string downloadUrl: "${downloadUrl}"

                command: [scriptLocation, bitrate, downloadUrl]
                running: false

                signal downloading(real percent, var info)
                signal error(string message)

                stdout: SplitParser {
                    onRead: data => {
                        const regex = /(\\d+\\.?\\d*)%.*?({.*})/;
                        const match = data.match(regex);
                        if (match) {
                            const percentage = match[1];
                            try {
                                const jsonObject = JSON.parse(match[2]);
                                proc.downloading(percentage, jsonObject);
                            } catch (e) {
                                console.error("Failed to parse JSON:", e);
                            }
                        } else {
                            try {
                                const jsonObject = JSON.parse(data);
                                proc.downloading(100, jsonObject);
                            } catch (e) {}
                        }
                    }
                }

                stderr: SplitParser {
                    onRead: data => {
                        proc.error("Error occurred during download: " + data.trim());
                    }
                }
            }
        `, job);

        if (!_processor) {
            _setFailed("Failed to create processor");
            return;
        }

        // Connect to processor signals
        _processor.downloading.connect((percent, info) => {
            // Store result data
            _resultData = info;

            // Update progress
            const title = info.title || "Downloading...";
            _updateProgress(parseFloat(percent), title);

            // Check if complete
            if (parseFloat(percent) >= 100 && info.audio_path && info.audio_path.length > 0) {
                _onDownloadComplete(info);
            }
        });

        _processor.error.connect((error) => {
            // Ignore SABR protocol errors (error code 12482)
            if (error.includes('12482')) {
                return;
            }
            console.error("YouTube download error:", error);
        });

        _processor.finished.connect((exitCode) => {
            _processor.running = false;

            if (exitCode !== 0 && status === "running") {
                _setFailed("Download process failed with exit code " + exitCode);
            }
        });

        // Start the download
        _processor.running = true;
    }

    function _onDownloadComplete(info) {
        const result = {
            success: true,
            audioPath: info.audio_path || "",
            thumbnailPath: info.thumbnail_path || "",
            title: info.title || "",
            uploader: info.uploader || "",
            downloadUrl: downloadUrl
        };

        // Set notification image to thumbnail
        notificationImage = info.thumbnail_path || "";

        // Complete the job
        _setCompleted(result);

        // Cleanup processor
        if (_processor) {
            _processor.destroy();
            _processor = null;
        }
    }

    // Override cancel to stop the processor
    function cancel() {
        if (_processor && _processor.running) {
            _processor.running = false;
        }

        if (_processor) {
            _processor.destroy();
            _processor = null;
        }

        // Call parent cancel
        status = "failed";
        endTime = new Date();
        errorMessage = "Job cancelled by user";
        failed(errorMessage);
    }
}
