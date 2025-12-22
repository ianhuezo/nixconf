import QtQuick
import QtQuick.Effects
import qs.config
import qs.services
import Quickshell.Widgets

ClippingRectangle {
    id: centerSection
    color: "transparent"

    // Properties
    required property var cavaValues
    required property bool useCanvas
    required property color waveColor
    property bool isSectionedBar: false

    signal toggleVisualization()

    VisualizerContainer {
        anchors.centerIn: parent
        height: centerSection.isSectionedBar ? parent.height : parent.height - 4
        cavaValues: centerSection.cavaValues
        useCanvas: centerSection.useCanvas
        waveColor: centerSection.waveColor
        barColor: "transparent"
        onToggleVisualization: centerSection.toggleVisualization()
    }
}
