import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property var cavaValues: []
    property bool useCanvasVisualization: true

    CavaDataProcessor {
        id: cavaProcessor
        onNewData: processedValues => root.cavaValues = processedValues
    }

    Variants {
        model: {
            return Quickshell.screens.filter(screen => screen.name == "DP-1");
        }
        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            height: 32
            anchors {
                top: true
                left: true
                right: true
            }

            VisualizerContainer {
                width: parent.width
                cavaValues: root.cavaValues
                useCanvas: root.useCanvasVisualization
                waveColor: '#FF9E64'
                barColor: '#171D23'
                onToggleVisualization: root.useCanvasVisualization = !root.useCanvasVisualization
            }
        }
    }
}
