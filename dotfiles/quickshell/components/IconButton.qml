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
    property bool disabled: false
    property color iconColor: disabled ? Color.palette.base03 : Color.palette.base05
    property color backgroundColor: disabled ? Color.palette.base01 : Color.palette.base02
    property int buttonRadius: AppearanceConfig.calculateRadius(width, height, 'lg')

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
        cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onPressed: root.disabled ? () => {} : root.clicked()
        hoverEnabled: !root.disabled
        onEntered: {
            if (root.disabled) {
                return;
            }
            root.border.color = Color.palette.base05;
            root.border.width = 1;
        }
        onExited: {
            root.border.color = '';
            root.border.width = 0;
        }
    }
}
