pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// your singletons should always have Singleton as the type
Singleton {
    property real gpu: 0

    Process {
        id: gpuProc
        command: ["sh", "-c", "echo $(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)"]
        running: true

        stdout: SplitParser {
            onRead: data => gpu = data
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: gpuProc.running = true
    }
}
