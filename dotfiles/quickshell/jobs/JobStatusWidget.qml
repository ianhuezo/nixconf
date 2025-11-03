import QtQuick
import QtQuick.Layouts
import qs.services
import qs.config
import qs.components
import "." as Jobs

Rectangle {
    id: root

    color: Color.palette.base00
    radius: AppearanceConfig.radius.lg

    // Refresh timer
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            _refreshJobs();
        }
    }

    // Internal state
    property var _allJobs: ({
        queued: [],
        running: [],
        completed: []
    })
    property var _stats: ({})

    function _refreshJobs() {
        _allJobs = Jobs.JobManager.getAllJobs();
        _stats = Jobs.JobManager.getStatistics();
    }

    Component.onCompleted: {
        _refreshJobs();
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "Background Jobs"
                color: Color.palette.base05
                font.pixelSize: AppearanceConfig.font.size.lg
                font.weight: AppearanceConfig.font.weight.bold
                font.family: AppearanceConfig.font.ui
                Layout.fillWidth: true
            }

            // Statistics
            Text {
                text: `${_stats.running || 0} running  •  ${_stats.queued || 0} queued`
                color: Color.palette.base04
                font.pixelSize: AppearanceConfig.font.size.sm
                font.family: AppearanceConfig.font.ui
            }

            // Clear completed button
            IconButton {
                iconName: "edit-clear-all"
                tooltip: "Clear Completed"
                onClicked: {
                    Jobs.JobManager.clearCompleted();
                    _refreshJobs();
                }
            }

            // Pause/Resume button
            IconButton {
                iconName: Jobs.JobQueue.paused ? "media-playback-start" : "media-playback-pause"
                tooltip: Jobs.JobQueue.paused ? "Resume Jobs" : "Pause Jobs"
                onClicked: {
                    if (Jobs.JobQueue.paused) {
                        Jobs.JobManager.resumeAll();
                    } else {
                        Jobs.JobManager.pauseAll();
                    }
                    _refreshJobs();
                }
            }
        }

        // Content area
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 16

                // Running Jobs Section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: _allJobs.running.length > 0

                    Text {
                        text: "Running"
                        color: Color.palette.base0D
                        font.pixelSize: AppearanceConfig.font.size.md
                        font.weight: AppearanceConfig.font.weight.semibold
                        font.family: AppearanceConfig.font.ui
                    }

                    Repeater {
                        model: _allJobs.running
                        delegate: JobItem {
                            Layout.fillWidth: true
                            job: modelData
                            showCancel: true
                            onCancelClicked: {
                                Jobs.JobManager.cancelJob(modelData.jobId);
                                _refreshJobs();
                            }
                        }
                    }
                }

                // Queued Jobs Section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: _allJobs.queued.length > 0

                    Text {
                        text: "Queued"
                        color: Color.palette.base0A
                        font.pixelSize: AppearanceConfig.font.size.md
                        font.weight: AppearanceConfig.font.weight.semibold
                        font.family: AppearanceConfig.font.ui
                    }

                    Repeater {
                        model: _allJobs.queued
                        delegate: JobItem {
                            Layout.fillWidth: true
                            job: modelData
                            showCancel: true
                            onCancelClicked: {
                                Jobs.JobManager.cancelJob(modelData.jobId);
                                _refreshJobs();
                            }
                        }
                    }
                }

                // Completed Jobs Section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: _allJobs.completed.length > 0

                    Text {
                        text: "Completed"
                        color: Color.palette.base0B
                        font.pixelSize: AppearanceConfig.font.size.md
                        font.weight: AppearanceConfig.font.weight.semibold
                        font.family: AppearanceConfig.font.ui
                    }

                    Repeater {
                        model: _allJobs.completed.slice(-10) // Show last 10
                        delegate: JobItem {
                            Layout.fillWidth: true
                            job: modelData
                            showRetry: modelData.status === "failed"
                            onRetryClicked: {
                                Jobs.JobManager.retryJob(modelData.jobId);
                                _refreshJobs();
                            }
                        }
                    }
                }

                // Empty state
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: _allJobs.running.length === 0 && _allJobs.queued.length === 0 && _allJobs.completed.length === 0

                    Text {
                        anchors.centerIn: parent
                        text: "No background jobs"
                        color: Color.palette.base03
                        font.pixelSize: AppearanceConfig.font.size.md
                        font.family: AppearanceConfig.font.ui
                    }
                }
            }
        }
    }

    // Job Item Component
    component JobItem: Rectangle {
        id: jobItem
        required property var job
        property bool showCancel: false
        property bool showRetry: false

        signal cancelClicked()
        signal retryClicked()

        height: 80
        color: Color.palette.base01
        radius: AppearanceConfig.radius.md
        border.color: Color.palette.base03
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            // Status indicator
            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: {
                    if (job.status === "running") return Color.palette.base0D;
                    if (job.status === "completed") return Color.palette.base0B;
                    if (job.status === "failed") return Color.palette.base08;
                    return Color.palette.base0A;
                }
            }

            // Job info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: job.jobName || job.jobType || "Unknown Job"
                    color: Color.palette.base05
                    font.pixelSize: AppearanceConfig.font.size.md
                    font.weight: AppearanceConfig.font.weight.medium
                    font.family: AppearanceConfig.font.ui
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: {
                        if (job.status === "running") {
                            return `${Math.round(job.progress)}% • ${job.getElapsedTimeFormatted()}`;
                        } else if (job.status === "failed") {
                            return `Failed: ${job.errorMessage}`;
                        } else if (job.status === "completed") {
                            return `Completed in ${job.getElapsedTimeFormatted()}`;
                        } else {
                            return "Queued";
                        }
                    }
                    color: Color.palette.base04
                    font.pixelSize: AppearanceConfig.font.size.sm
                    font.family: AppearanceConfig.font.mono
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                // Progress bar for running jobs
                Rectangle {
                    Layout.fillWidth: true
                    height: 4
                    color: Color.palette.base02
                    radius: 2
                    visible: job.status === "running"

                    Rectangle {
                        width: parent.width * (job.progress / 100)
                        height: parent.height
                        color: Color.palette.base0D
                        radius: parent.radius

                        Behavior on width {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }

            // Action buttons
            RowLayout {
                spacing: 8

                IconButton {
                    iconName: "process-stop"
                    tooltip: "Cancel Job"
                    visible: jobItem.showCancel
                    onClicked: jobItem.cancelClicked()
                }

                IconButton {
                    iconName: "view-refresh"
                    tooltip: "Retry Job"
                    visible: jobItem.showRetry
                    onClicked: jobItem.retryClicked()
                }
            }
        }
    }
}
