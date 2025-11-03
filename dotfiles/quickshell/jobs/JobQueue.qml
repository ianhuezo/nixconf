import QtQuick

pragma Singleton

QtObject {
    id: jobQueue

    // Configuration
    property int maxConcurrentJobs: 3

    // Job storage
    property var queuedJobs: []     // Jobs waiting to run
    property var runningJobs: []    // Jobs currently executing
    property var completedJobs: []  // Jobs that finished (kept for history)

    // Statistics
    property int totalJobsProcessed: 0
    property int totalJobsFailed: 0

    // State
    property bool paused: false

    // Signals
    signal jobQueued(var job)
    signal jobStarted(var job)
    signal jobCompleted(var job, var result)
    signal jobFailed(var job, string error)
    signal queueEmpty()

    // Public API

    function enqueue(job) {
        if (!job) {
            console.error("Cannot enqueue null job");
            return false;
        }

        // Check if job already exists in queue or running
        if (_findJobById(job.jobId)) {
            console.warn("Job already queued or running:", job.jobId);
            return false;
        }

        // Add to queue
        queuedJobs.push(job);
        queuedJobs = queuedJobs.slice(); // Trigger property update
        jobQueued(job);

        // Connect to job signals
        job.started.connect(() => _onJobStarted(job));
        job.completed.connect((result) => _onJobCompleted(job, result));
        job.failed.connect((error) => _onJobFailed(job, error));

        // Try to start immediately if slots available
        _processQueue();

        return true;
    }

    function dequeue(jobId) {
        // Remove from queued jobs
        const queueIndex = queuedJobs.findIndex(j => j.jobId === jobId);
        if (queueIndex >= 0) {
            const job = queuedJobs[queueIndex];
            queuedJobs.splice(queueIndex, 1);
            queuedJobs = queuedJobs.slice();
            return job;
        }

        return null;
    }

    function cancel(jobId) {
        // Try to cancel running job
        const runningJob = runningJobs.find(j => j.jobId === jobId);
        if (runningJob) {
            runningJob.cancel();
            return true;
        }

        // Remove from queue if not started yet
        const dequeuedJob = dequeue(jobId);
        if (dequeuedJob) {
            return true;
        }

        return false;
    }

    function pause() {
        paused = true;
    }

    function resume() {
        paused = false;
        _processQueue();
    }

    function clear() {
        // Cancel all running jobs
        for (let i = 0; i < runningJobs.length; i++) {
            runningJobs[i].cancel();
        }

        // Clear all queues
        queuedJobs = [];
        runningJobs = [];
        completedJobs = [];
    }

    function clearCompleted() {
        completedJobs = [];
    }

    function getJob(jobId) {
        return _findJobById(jobId);
    }

    function getJobByContext(contextId) {
        if (!contextId || contextId.length === 0) {
            return null;
        }

        // Check running jobs first
        let job = runningJobs.find(j => j.contextId === contextId);
        if (job) return job;

        // Check queued jobs
        job = queuedJobs.find(j => j.contextId === contextId);
        if (job) return job;

        // Check completed jobs
        job = completedJobs.find(j => j.contextId === contextId);
        if (job) return job;

        return null;
    }

    function getAllJobs() {
        return {
            queued: queuedJobs.slice(),
            running: runningJobs.slice(),
            completed: completedJobs.slice()
        };
    }

    function getStatistics() {
        return {
            queued: queuedJobs.length,
            running: runningJobs.length,
            completed: completedJobs.length,
            totalProcessed: totalJobsProcessed,
            totalFailed: totalJobsFailed,
            successRate: totalJobsProcessed > 0 ?
                ((totalJobsProcessed - totalJobsFailed) / totalJobsProcessed * 100).toFixed(1) + "%" :
                "N/A"
        };
    }

    // Private methods

    function _processQueue() {
        if (paused) {
            return;
        }

        // Start jobs until we hit the concurrent limit
        while (runningJobs.length < maxConcurrentJobs && queuedJobs.length > 0) {
            const job = queuedJobs.shift();
            queuedJobs = queuedJobs.slice();

            runningJobs.push(job);
            runningJobs = runningJobs.slice();

            // Start the job
            job.start();
        }

        // Emit signal if queue is empty and no jobs running
        if (queuedJobs.length === 0 && runningJobs.length === 0) {
            queueEmpty();
        }
    }

    function _findJobById(jobId) {
        // Search in running jobs
        let job = runningJobs.find(j => j.jobId === jobId);
        if (job) return job;

        // Search in queued jobs
        job = queuedJobs.find(j => j.jobId === jobId);
        if (job) return job;

        // Search in completed jobs
        job = completedJobs.find(j => j.jobId === jobId);
        if (job) return job;

        return null;
    }

    function _removeFromRunning(job) {
        const index = runningJobs.findIndex(j => j.jobId === job.jobId);
        if (index >= 0) {
            runningJobs.splice(index, 1);
            runningJobs = runningJobs.slice();
        }
    }

    // Job event handlers

    function _onJobStarted(job) {
        jobStarted(job);
    }

    function _onJobCompleted(job, result) {
        _removeFromRunning(job);

        // Add to completed jobs
        completedJobs.push(job);
        completedJobs = completedJobs.slice();

        // Update statistics
        totalJobsProcessed++;

        // Emit signal
        jobCompleted(job, result);

        // Process next job in queue
        _processQueue();
    }

    function _onJobFailed(job, error) {
        _removeFromRunning(job);

        // Add to completed jobs (even if failed)
        completedJobs.push(job);
        completedJobs = completedJobs.slice();

        // Update statistics
        totalJobsProcessed++;
        totalJobsFailed++;

        // Emit signal
        jobFailed(job, error);

        // Process next job in queue
        _processQueue();
    }

    // Cleanup old completed jobs periodically
    Timer {
        interval: 60000 // 1 minute
        running: true
        repeat: true
        onTriggered: {
            // Keep only last 50 completed jobs
            if (completedJobs.length > 50) {
                completedJobs = completedJobs.slice(-50);
            }
        }
    }
}
