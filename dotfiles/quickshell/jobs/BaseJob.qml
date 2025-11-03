import QtQuick

QtObject {
    id: baseJob

    // Public properties
    property string jobId: ""
    property list<var> args: []
    property string jobType: ""
    property string jobName: ""
    property string contextId: ""

    // Job status: "pending", "running", "completed", "failed"
    property string status: "pending"

    // Progress tracking (0-100)
    property real progress: 0

    // Result object (set when completed)
    property var result: null

    // Error message (set when failed)
    property string errorMessage: ""

    // Timestamps
    property var startTime: null
    property var endTime: null

    // Notification settings
    property string notificationIcon: "emblem-system"
    property string notificationImage: ""
    property bool enableProgressNotifications: false

    // Signals
    signal started()
    signal progressUpdated(real percent, string message)
    signal completed(var result)
    signal failed(string error)

    // Abstract method - must be implemented by subclasses
    function execute() {
        console.error("BaseJob.execute() must be implemented by subclass");
        failed("Execute method not implemented");
    }

    // Public methods
    function start() {
        if (status === "running") {
            console.warn("Job already running:", jobId);
            return;
        }

        status = "running";
        startTime = new Date();
        progress = 0;
        started();

        // Call the subclass implementation
        execute();
    }

    function cancel() {
        if (status !== "running") {
            return;
        }

        status = "failed";
        endTime = new Date();
        errorMessage = "Job cancelled by user";
        failed(errorMessage);
    }

    function getElapsedTime() {
        if (!startTime) {
            return 0;
        }

        const end = endTime || new Date();
        return Math.floor((end - startTime) / 1000); // seconds
    }

    function getElapsedTimeFormatted() {
        const seconds = getElapsedTime();

        if (seconds < 60) {
            return seconds + "s";
        } else if (seconds < 3600) {
            const mins = Math.floor(seconds / 60);
            const secs = seconds % 60;
            return mins + "m " + secs + "s";
        } else {
            const hours = Math.floor(seconds / 3600);
            const mins = Math.floor((seconds % 3600) / 60);
            return hours + "h " + mins + "m";
        }
    }

    // Protected methods for subclasses to call
    function _updateProgress(percent, message) {
        progress = Math.max(0, Math.min(100, percent));
        progressUpdated(progress, message || "");
    }

    function _setCompleted(resultData) {
        if (status !== "running") {
            return;
        }

        status = "completed";
        endTime = new Date();
        progress = 100;
        result = resultData;
        completed(resultData);
    }

    function _setFailed(error) {
        if (status !== "running") {
            return;
        }

        status = "failed";
        endTime = new Date();
        errorMessage = error;
        failed(error);
    }

    // Utility: Create a process safely
    function _createProcess(command, onStdout, onStderr, onFinished) {
        try {
            const processComponent = Qt.createQmlObject(`
                import QtQuick
                import Quickshell.Io

                Process {
                    id: proc
                    property var commandArray: []
                    command: commandArray
                    running: false
                }
            `, baseJob);

            processComponent.commandArray = command;

            if (onStdout && processComponent.stdout) {
                processComponent.stdout.read.connect(onStdout);
            }

            if (onStderr && processComponent.stderr) {
                processComponent.stderr.read.connect(onStderr);
            }

            if (onFinished) {
                processComponent.finished.connect(onFinished);
            }

            return processComponent;
        } catch (e) {
            console.error("Failed to create process:", e);
            return null;
        }
    }
}
