pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// your singletons should always have Singleton as the type
Singleton {
    property real ram: 0

    Process {
        id: ramProc
	command: ["sh", "-c", "echo \"scale=2; $(cat /proc/meminfo | awk '/MemAvailable/ {print $2}') / $(cat /proc/meminfo | awk '/MemTotal/ {print $2}')\" | bc"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const number = parseFloat(data);
                if (number === "NaN") {
                    ram = 0;
                    return;
                }

                ram = 100 - parseFloat(data) * 100;
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: ramProc.running = true
    }
}
