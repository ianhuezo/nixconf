import Quickshell
import Quickshell.Io

Singleton {
    id: jobManager

    property var activeJobs: new Map()
    property int nextJobId: 0

    property var jobComponents: ({
            "encode": "jobs/EncodeJob.qml",
            "download": "jobs/DownloadJob.qml",
            "backup": "jobs/BackupJob.qml",
            "compile": "jobs/CompileJob.qml"
        })

    function enqueueJob(jobType, args, onComplete) {
        const jobId = nextJobId++;
        const componentPath = jobComponents[jobType];

        if (!componentPath) {
            console.error(`Unknown job type: ${jobType}`);
            return -1;
        }

        const component = Qt.createComponent(componentPath);

        if (component.status === Component.Error) {
            console.error("Error loading component:", component.errorString());
            return -1;
        }

        const job = component.createObject(jobManager, {
            jobId: jobId,
            args: args
        });

        job.onCompleted.connect(result => {
            if (onComplete)
                onComplete(result);
            activeJobs.delete(jobId);
            job.destroy();
        });

        job.onFailed.connect(error => {
            console.error(`Job ${jobId} failed:`, error);
            activeJobs.delete(jobId);
            job.destroy();
        });

        activeJobs.set(jobId, job);
        job.start();

        return jobId;
    }
}
