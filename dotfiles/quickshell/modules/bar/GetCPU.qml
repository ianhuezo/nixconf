pragma Singleton

import Quickshell
import QtQuick
import qs.components

Singleton {
    property real cpu: poller.value

    property MetricPoller poller: MetricPoller {
        command: "awk '{t=0; for(i=2;i<=NF;i++) t+=$i; u=t-$5; if(NR==1){u1=u;t1=t}else print (u-u1)*100/(t-t1)}' <(grep 'cpu ' /proc/stat) <(sleep 1;grep 'cpu ' /proc/stat)"
        pollInterval: 5000
        parseFunction: (data) => Math.round(parseFloat(data))
    }
}
