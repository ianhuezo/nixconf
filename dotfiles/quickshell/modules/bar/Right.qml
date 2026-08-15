import QtQuick
import QtQuick.Effects
import qs.config
import qs.services
import qs.components

Rectangle {
    id: rightSection
    color: "transparent"

    // Properties
    property color widgetColor: Color.palette.base0C
    property color clockColor: Color.palette.base08

    // Lets the bar size its pane to the content instead of a fixed width
    implicitWidth: statsRow.implicitWidth

    Row {
        id: statsRow
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
        }
        height: parent.height
        layoutDirection: Qt.RightToLeft
        spacing: 4

        property var statsData: [
            {
                percentage: GetGPU.gpu,
                statText: GetGPU.gpu + "%",
                iconSource: FileConfig.icons.gpu
            },
            {
                percentage: GetCPU.cpu,
                statText: GetCPU.cpu + "%",
                iconSource: FileConfig.icons.cpu
            },
            {
                percentage: GetRam.ram,
                statText: GetRam.ram + "%",
                iconSource: FileConfig.icons.ram
            }
        ]

        Clock {
            height: parent.height
            clockColor: rightSection.clockColor
            separatorColor: rightSection.clockColor
        }

        Repeater {
            model: statsRow.statsData
            delegate: CircleProgress {
                percentage: modelData.percentage
                statText: modelData.statText
                iconSource: modelData.iconSource
                textColor: rightSection.widgetColor
                backgroundColor: "transparent"
                progressColor: rightSection.widgetColor
                color: "transparent"
            }
        }
    }
}
