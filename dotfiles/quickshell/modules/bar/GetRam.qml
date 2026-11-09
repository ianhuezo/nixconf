pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real ram: 0

    property FileView meminfo: FileView {
        id: meminfoFile
        path: "/proc/meminfo"
        onLoaded: {
            const text = meminfoFile.text();
            const total = Number(text.match(/MemTotal:\s+(\d+)/)?.[1]);
            const available = Number(text.match(/MemAvailable:\s+(\d+)/)?.[1]);
            if (total > 0 && !isNaN(available))
                root.ram = Math.round(100 - available / total * 100);
        }
    }

    property Timer timer: Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: meminfoFile.reload()
    }
}
