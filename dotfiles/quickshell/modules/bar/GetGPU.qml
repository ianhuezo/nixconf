pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property real gpu: 0

    property Process process: Process {
        id: smi
        command: ["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits", "-lms", "1000"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const value = parseFloat(data);
                if (!isNaN(value))
                    root.gpu = value;
            }
        }

        onExited: restart.start()
    }

    property Timer restart: Timer {
        interval: 5000
        onTriggered: smi.running = true
    }
}
