import QtQuick
import qs.services
import qs.config

Rectangle {
    id: root

    // Public properties
    property string iconText: "⟳"
    property int iconSize: 24
    property int iconWeight: 800
    property string fontFamily: "JetBrains Mono Nerd Font"
    property color iconColor: Color.palette.base05
    property color backgroundColor: Color.palette.base02
    property int buttonRadius: AppearanceConfig.calculateRadius(width,height,'lg')

    // Signals
    signal clicked

    // Default size
    implicitHeight: 40
    implicitWidth: 40

    // Styling
    radius: buttonRadius
    color: backgroundColor

    Text {
        anchors.centerIn: parent
        color: root.iconColor
        font.pixelSize: root.iconSize
        font.weight: root.iconWeight
        text: root.iconText
        font.family: root.fontFamily
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: root.clicked()
        hoverEnabled: true
        onEntered: {
            root.border.color = Color.palette.base05;
            root.border.width = 1;
        }
        onExited: {
            root.border.color = '';
            root.border.width = 0;
        }
    }
}
