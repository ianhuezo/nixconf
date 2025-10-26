import QtQuick

QtObject {
    id: job

    property string jobId: job.generateRandomString(10)
    property list<var> args: []
    property string jobType: ""
    property string notifTitle: job.jobType
    property string finishedMessage: `${job.jobType} finished`

    function generateRandomString(length) {
        const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        let result = '';
        for (let i = 0; i < length; i++) {
            result += characters.charAt(Math.floor(Math.random() * characters.length));
        }
        return result;
    }
}
