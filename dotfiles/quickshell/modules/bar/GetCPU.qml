pragma Singleton

import Quickshell
import QtQuick
import qs.components

Singleton {
    property real cpu: poller.value

    property MetricPoller poller: MetricPoller {
        command: "awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else print ($2+$4-u1) * 100 / (t-t1); }' <(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat)"
        pollInterval: 5000
        parseFunction: (data) => Math.round(parseFloat(data))
    }
}
