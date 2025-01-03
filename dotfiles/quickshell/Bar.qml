import Quickshell
import Quickshell.Io
import QtQuick
import Quickshell.Widgets

Scope {
  property string time;

  Variants {
    model: Quickshell.screens

    PanelWindow {
      property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }

      height: 30

      Text {
        anchors.centerIn: parent

        // now just time instead of root.time
        text: time
      }
      IconImage {
        source: "nf-md-power"
	implicitSize: 16
      }

    }
  }

  Process {
    id: sysProc
    running: false
    command: ["exec", "hyprlock"]
  }

  Process {
    id: dateProc
    command: ["date"]
    running: true

    stdout: SplitParser {
      // now just time instead of root.time
      onRead: data => time = data
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: dateProc.running = true
  }
}
