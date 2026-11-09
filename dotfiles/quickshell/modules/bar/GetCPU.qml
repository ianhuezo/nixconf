pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real loadAverage: 0
    property int cores: 1
    readonly property real cpu: Math.round(loadAverage / cores * 100)

    property FileView online: FileView {
        id: onlineFile
        path: "/sys/devices/system/cpu/online"
        onLoaded: root.cores = onlineFile.text().trim().split(",").reduce((count, range) => {
            const [first, last] = range.split("-").map(Number);
            return count + (isNaN(last) ? 1 : last - first + 1);
        }, 0) || 1
    }

    property FileView loadavg: FileView {
        id: loadavgFile
        path: "/proc/loadavg"
        onLoaded: root.loadAverage = parseFloat(loadavgFile.text()) || 0
    }

    property Timer timer: Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: loadavgFile.reload()
    }
}
