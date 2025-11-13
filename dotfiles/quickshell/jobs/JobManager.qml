pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: jobManager

    // Job type registry
    property var jobComponents: ({
            "YoutubeConversion": "YoutubeConversionJob.qml",
            "SaveAIColorFile": "SaveAIColorFileJob.qml",
            "ApplyAIColor": "ApplyAIColorJob.qml"
        })

    // Job ID counter
    property int _nextJobId: 0

    // Signals
    signal jobEnqueued(var job)
    signal jobStarted(var job)
    signal jobCompleted(var job, var result)
    signal jobFailed(var job, string error)

    // Public API

    /**
     * Enqueue a job with the given type and arguments
     * @param jobType - Type of job (must be registered in jobComponents)
     * @param args - Array of arguments for the job
     * @param contextId - Optional context ID to link job to UI element
     * @param onComplete - Optional callback when job completes
     * @returns Job ID or -1 on error
     */
    function enqueueJob(jobType, args, contextId, onComplete) {
        const componentPath = jobComponents[jobType];

        if (!componentPath) {
            console.error("Unknown job type:", jobType);
            return -1;
        }

        // Create job component
        const component = Qt.createComponent("jobs/" + componentPath);

        if (component.status === Component.Error) {
            console.error("Error loading job component:", component.errorString());
            return -1;
        }

        // Generate job ID
        const jobId = "job_" + (_nextJobId++);

        // Create job instance
        const job = component.createObject(jobManager, {
            jobId: jobId,
            args: args || [],
            jobType: jobType,
            contextId: contextId || ""
        });

        if (!job) {
            console.error("Failed to create job instance");
            return -1;
        }

        // Connect to job signals
        job.started.connect(() => {
            _onJobStarted(job);
        });

        job.progressUpdated.connect((percent, message) => {
            _onJobProgressUpdated(job, percent, message);
        });

        job.completed.connect(result => {
            _onJobCompleted(job, result);
            if (onComplete) {
                onComplete(result);
            }
        });

        job.failed.connect(error => {
            _onJobFailed(job, error);
        });

        // Enqueue in JobQueue
        const success = Jobs.JobQueue.enqueue(job);

        if (success) {
            jobEnqueued(job);

            // Send notification
            Jobs.JobNotification.sendJobStarted(job.jobName || job.jobType, job.jobId, job.notificationIcon);

            return jobId;
        } else {
            console.error("Failed to enqueue job");
            job.destroy();
            return -1;
        }
    }

    /**
     * Get a job by ID
     */
    function getJob(jobId) {
        return Jobs.JobQueue.getJob(jobId);
    }

    /**
     * Get a job by context ID
     */
    function getJobForContext(contextId) {
        return Jobs.JobQueue.getJobByContext(contextId);
    }

    /**
     * Get result from a completed job
     */
    function getJobResult(jobId) {
        const job = getJob(jobId);
        return job ? job.result : null;
    }

    /**
     * Cancel a running job
     */
    function cancelJob(jobId) {
        return Jobs.JobQueue.cancel(jobId);
    }

    /**
     * Retry a failed job
     */
    function retryJob(jobId) {
        const job = getJob(jobId);
        if (!job) {
            console.error("Job not found:", jobId);
            return -1;
        }

        // Re-enqueue with same parameters
        return enqueueJob(job.jobType, job.args, job.contextId);
    }

    /**
     * Clear all completed jobs
     */
    function clearCompleted() {
        Jobs.JobQueue.clearCompleted();
    }

    /**
     * Get all jobs (queued, running, completed)
     */
    function getAllJobs() {
        return Jobs.JobQueue.getAllJobs();
    }

    /**
     * Get statistics
     */
    function getStatistics() {
        return Jobs.JobQueue.getStatistics();
    }

    /**
     * Pause job processing
     */
    function pauseAll() {
        Jobs.JobQueue.pause();
    }

    /**
     * Resume job processing
     */
    function resumeAll() {
        Jobs.JobQueue.resume();
    }

    // Private event handlers

    function _onJobStarted(job) {
        jobStarted(job);
    }

    function _onJobProgressUpdated(job, percent, message) {
        if (job.enableProgressNotifications) {
            Jobs.JobNotification.sendJobProgress(job.jobName || job.jobType, percent, message, job.notificationIcon);
        }
    }

    function _onJobCompleted(job, result) {
        jobCompleted(job, result);
        Jobs.JobNotification.sendJobCompleted(job.jobName || job.jobType, result, job.notificationImage, job.notificationIcon);
    }

    function _onJobFailed(job, error) {
        jobFailed(job, error);
        Jobs.JobNotification.sendJobFailed(job.jobName || job.jobType, error, "critical");
    }

    Component.onCompleted: {
        console.log("JobManager initialized with job types:", Object.keys(jobComponents));
    }
}
