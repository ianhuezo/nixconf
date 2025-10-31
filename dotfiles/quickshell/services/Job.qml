import QtQuick

QtObject {
    id: job

    property string jobId: job.generateRandomString(10)
    property list<var> args: []
    property int jobType: -1
    property string jobName: ""
    property string notifTitle: job.jobName
    property string finishedMessage: `${job.jobName} finished`

    enum JobType {
        YoutubeToMp3 = 0,
        SaveAIColorFile = 1
    }

    function generateRandomString(length) {
        const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        let result = '';
        for (let i = 0; i < length; i++) {
            result += characters.charAt(Math.floor(Math.random() * characters.length));
        }
        return result;
    }

    function isValidJobType(type) {
        return type === job.JobType.YoutubeToMp3 || type === job.JobType.SaveAIColorFile;
    }

    function isValid() {
        if (jobType === -1) {
            return false;
        }

        if (!isValidJobType(jobType)) {
            return false;
        }

        if (jobName.length === 0) {
            return false;
        }
        return true;
    }
}
