pragma Singleton

import Quickshell
import QtQuick
import qs.components

Singleton {
    property real gpu: poller.value

    property MetricPoller poller: MetricPoller {
        command: "echo $(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits)"
        pollInterval: 1000
        parseFunction: (data) => parseFloat(data)
    }
}
