pragma Singleton

import Quickshell
import QtQuick
import qs.components

Singleton {
    property real ram: poller.value

    property MetricPoller poller: MetricPoller {
        command: "echo \"scale=2; $(cat /proc/meminfo | awk '/MemAvailable/ {print $2}') / $(cat /proc/meminfo | awk '/MemTotal/ {print $2}')\" | bc"
        pollInterval: 1000
        parseFunction: (data) => {
            const number = parseFloat(data);
            if (isNaN(number)) {
                return 0;
            }
            return Math.round(100 - number * 100);
        }
    }
}
