// Clock.qml
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services
import qs.components

Item {
    id: clockRoot
    width: clockRow.width
    height: parent.height

    // Properties to customize the clock
    property color clockColor: Color.palette.base0D  // Blue accent
    property color separatorColor: Color.palette.base0D

    Row {
        id: clockRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        // Clock icon
        ColorizedImage {
            anchors.verticalCenter: parent.verticalCenter
            source: FileConfig.icons.clock
            width: 15
            height: 15
            sourceSize.width: 30
            sourceSize.height: 30
            antialiasing: true
            smooth: true
            iconColor: clockRoot.clockColor
            brightness: 1.0
        }

        // Time display
        Text {
            id: timeText
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatTime(new Date(), "h:mm AP")
            color: clockRoot.clockColor
            font.pixelSize: AppearanceConfig.font.size.sm
            font.family: AppearanceConfig.font.mono
        }
    }

    // Timer to update the clock every second
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            timeText.text = Qt.formatTime(new Date(), "h:mm AP")
        }
    }
}
