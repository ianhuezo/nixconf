import QtQuick
import Quickshell.Io
import ".." as Jobs

Jobs.BaseJob {
    id: job

    // Expected args: [colorData, filePath]
    property var colorData: args.length > 0 ? args[0] : null
    property string filePath: args.length > 1 ? args[1] : ""

    // Job metadata
    jobName: "Save AI Colors"
    notificationIcon: "document-save"

    function execute() {
        if (!colorData) {
            _setFailed("No color data provided");
            return;
        }

        if (!filePath || filePath.length === 0) {
            _setFailed("No file path provided");
            return;
        }

        _updateProgress(10, "Preparing to save colors...");

        // Convert color data to JSON string
        let jsonContent = "";
        try {
            jsonContent = JSON.stringify(colorData, null, 2);
        } catch (e) {
            _setFailed("Failed to serialize color data: " + e.toString());
            return;
        }

        _updateProgress(30, "Writing to file...");

        // Write to file using a process (echo to file)
        // Note: In a real implementation, you might want to use a proper file writing mechanism
        const writeProcess = Qt.createQmlObject(`
            import QtQuick
            import Quickshell.Io

            Process {
                id: proc
                property string content: ""
                property string targetPath: ""

                command: ["sh", "-c", "echo '" + content.replace(/'/g, "'\\\\''") + "' > '" + targetPath + "'"]
                running: false
            }
        `, job);

        if (!writeProcess) {
            _setFailed("Failed to create write process");
            return;
        }

        writeProcess.content = jsonContent;
        writeProcess.targetPath = filePath;

        writeProcess.finished.connect((exitCode) => {
            if (exitCode === 0) {
                _updateProgress(100, "Colors saved successfully");

                const result = {
                    success: true,
                    filePath: filePath,
                    colorCount: colorData ? (Array.isArray(colorData) ? colorData.length : Object.keys(colorData).length) : 0
                };

                _setCompleted(result);
            } else {
                _setFailed("Failed to write file (exit code: " + exitCode + ")");
            }

            writeProcess.destroy();
        });

        writeProcess.stderr.read.connect((data) => {
            if (data && data.length > 0) {
                console.error("Write error:", data);
            }
        });

        writeProcess.running = true;
    }
}
