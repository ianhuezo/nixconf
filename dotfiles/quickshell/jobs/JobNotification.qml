pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: jobNotification

    // Configuration
    property string appName: "Quickshell Jobs"
    property int defaultExpireTime: 5000 // milliseconds

    // Send notification when job starts
    function sendJobStarted(jobName, jobId, icon) {
        const iconArg = icon || "emblem-system";
        const title = "Job Started";
        const body = jobName || "Background job started";

        _sendNotification(title, body, iconArg, "", "low", 3000);
    }

    // Send notification for job progress (optional, for very long jobs)
    function sendJobProgress(jobName, percent, message, icon) {
        const iconArg = icon || "emblem-synchronizing";
        const title = jobName || "Job Progress";
        const body = message ? `${Math.round(percent)}% - ${message}` : `${Math.round(percent)}% complete`;

        _sendNotification(title, body, iconArg, "", "low", 2000);
    }

    // Send notification when job completes successfully
    function sendJobCompleted(jobName, result, imagePath, icon) {
        const iconArg = icon || "emblem-default";
        const title = "Job Complete";
        const body = jobName || "Background job completed successfully";

        _sendNotification(title, body, iconArg, imagePath || "", "normal", defaultExpireTime);
    }

    // Send notification when job fails
    function sendJobFailed(jobName, error, urgency) {
        const iconArg = "dialog-error";
        const title = "Job Failed";
        const body = `${jobName || "Background job"}\n${error}`;
        const urgencyLevel = urgency || "critical";

        _sendNotification(title, body, iconArg, "", urgencyLevel, 0); // 0 = no auto-expire
    }

    // Send custom notification
    function sendCustomNotification(title, body, icon, imagePath, urgency, expireTime) {
        _sendNotification(title || "Notification", body || "", icon || "dialog-information", imagePath || "", urgency || "normal", expireTime !== undefined ? expireTime : defaultExpireTime);
    }

    // Private method to send notification via notify-send
    function _sendNotification(title, body, icon, imagePath, urgency, expireTime) {
        // Build notify-send command
        let args = ["--app-name=" + appName, "--icon=" + icon, "--urgency=" + urgency];

        // Add expire time if specified
        if (expireTime > 0) {
            args.push("--expire-time=" + expireTime);
        }

        // Add image if provided
        if (imagePath && imagePath.length > 0) {
            args.push("--image=" + imagePath);
        }

        // Add title and body
        args.push(title);
        args.push(body);

        // Create and run process
        const process = Qt.createQmlObject(`
            import QtQuick
            import Quickshell.Io

            Process {
                id: notifyProcess
                property var commandArgs: []
                command: ["notify-send"].concat(commandArgs)
                running: false
            }
        `, jobNotification);

        if (!process) {
            console.error("Failed to create notification process");
            return;
        }

        process.commandArgs = args;

        // Handle errors
        if (process.stderr) {
            process.stderr.read.connect(data => {
                if (data && data.length > 0) {
                    console.warn("Notification error:", data);
                }
            });
        }

        // Cleanup on completion
        process.finished.connect(exitCode => {
            if (exitCode !== 0) {
                console.warn("notify-send exited with code:", exitCode);
            }
            process.destroy();
        });

        // Start the process
        process.running = true;
    }

    // Utility: Test if notify-send is available
    function testNotifySupport() {
        const testProcess = Qt.createQmlObject(`
            import QtQuick
            import Quickshell.Io

            Process {
                command: ["which", "notify-send"]
                running: false
            }
        `, jobNotification);

        if (!testProcess) {
            console.error("Failed to create test process");
            return false;
        }

        let available = false;

        testProcess.finished.connect(exitCode => {
            available = (exitCode === 0);
            if (!available) {
                console.warn("notify-send not found. Install libnotify for notifications.");
            }
            testProcess.destroy();
        });

        testProcess.running = true;
        return available;
    }
}
