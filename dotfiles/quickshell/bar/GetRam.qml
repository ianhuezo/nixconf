pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// your singletons should always have Singleton as the type
Singleton {
    property string ram

    Process {
        id: ramProc
        command: ["date"]
        running: true

        stdout: SplitParser {
            onRead: data => ram = data
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: ramProc.running = true
    }
}
