import Quickshell
import Quickshell.Io
import QtQuick

QtObject {
    id: root

    required property string command
    required property int pollInterval
    property real value: 0
    property var parseFunction: (data) => parseFloat(data)

    property Process process: Process {
        id: proc
        command: ["sh", "-c", root.command]
        running: true

        stdout: SplitParser {
            onRead: data => {
                root.value = root.parseFunction(data);
            }
        }
    }

    property Timer timer: Timer {
        interval: root.pollInterval
        running: true
        repeat: true
        onTriggered: proc.running = true
    }
}
