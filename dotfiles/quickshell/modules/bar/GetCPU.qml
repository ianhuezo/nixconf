pragma Singleton

import Quickshell
import QtQuick
import qs.components

Singleton {
    property real cpu: poller.value

    property MetricPoller poller: MetricPoller {
        command: "awk -v cores=$(nproc) '{printf \"%.0f\", ($1/cores)*100}' /proc/loadavg"
        pollInterval: 5000
        parseFunction: (data) => Math.round(parseFloat(data))
    }
}
