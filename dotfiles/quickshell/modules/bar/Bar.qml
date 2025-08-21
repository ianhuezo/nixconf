import Quickshell
import QtQuick
import Quickshell
import QtQuick
import Quickshell.Io
import qs.config
import qs.services

Item {
    id: bar
    property var active: true
    property var cavaValues: []
    property bool useCanvasVisualization: true
    property var barOffsetX: 10 // New horizontal offset property
    property var verticalPadding: 8// Padding for top and bottom of the inner bar
    property real originalHeight: bar.implicitHeight
    property var mainMonitor: Quickshell.screens.filter(screen => screen.name == "DP-1")

    IpcHandler {
        target: "bar"

        function toggleBar() {
            bar.active = !bar.active;
        }
    }

    CavaDataProcessor {
        id: cavaProcessor
        onNewData: processedValues => bar.cavaValues = processedValues
    }

    Variants {
        model: {
            return bar.mainMonitor;
        }

        delegate: BarPanelWindow {
            modelData: modelData
            cavaValues: bar.cavaValues
            useCanvasVisualization: bar.useCanvasVisualization
            barOffsetY: bar.barOffsetY
            barOffsetX: bar.barOffsetX
            verticalPadding: bar.verticalPadding
            isActive: bar.active
        }
    }
}
