import QtQuick
import QtQuick.Effects
import qs.services
import qs.config

Rectangle {
    id: root

    // Public properties - Text
    property string text: ""
    property string iconText: "⟳"
    property int iconSize: 24
    property int iconWeight: 800
    property string fontFamily: "JetBrains Mono Nerd Font"

    // Public properties - SVG
    property string svgSource: ""
    property string iconName: "" // GTK icon name (e.g., "document-save", "edit-copy")
    property string svgColorBase: Color.palette.base05 // e.g., "base05", "base08", etc.

    // Public properties - State
    property bool disabled: false

    // Public properties - Colors
    property color iconColor: disabled ? Color.palette.base03 : Color.palette.base05
    property color textColor: disabled ? Color.palette.base03 : Color.palette.base05
    property color backgroundColor: disabled ? Color.palette.base01 : Color.palette.base02
    property int buttonRadius: AppearanceConfig.calculateRadius(width, height, 'lg')

    // Signals
    signal clicked

    // Internal properties
    readonly property bool hasIcon: svgSource !== "" || iconText !== "" || iconName !== ""
    readonly property bool hasText: text !== ""
    readonly property bool hasBoth: hasIcon && hasText
    readonly property int contentSpacing: 8
    readonly property int horizontalPadding: hasBoth ? 12 : 0
    readonly property string resolvedIconSource: {
        if (svgSource !== "")
            return svgSource;
        if (iconName !== "")
            return "image://icon/" + iconName;
        return "";
    }

    // Default size - adjusts based on content
    implicitHeight: 40
    implicitWidth: {
        if (hasBoth) {
            return iconSize + contentSpacing + textItem.implicitWidth + (horizontalPadding * 2);
        } else if (hasText) {
            return textItem.implicitWidth + (horizontalPadding * 2);
        } else {
            return 40;
        }
    }

    // Styling
    radius: buttonRadius
    color: backgroundColor

    // Content container
    Row {
        id: contentContainer
        anchors.centerIn: parent
        spacing: root.hasIcon && root.hasText ? root.contentSpacing : 0

        // SVG Icon with MultiEffect for coloring
        Item {
            id: svgContainer
            visible: root.resolvedIconSource !== ""
            anchors.verticalCenter: parent.verticalCenter
            width: root.iconSize
            height: root.iconSize

            Image {
                id: svgImage
                anchors.fill: parent
                source: root.resolvedIconSource
                sourceSize.width: root.iconSize
                sourceSize.height: root.iconSize
                fillMode: Image.PreserveAspectFit
                visible: false
                layer.effect: MultiEffect {
                    brightness: 1.0
                    colorization: 1.0
                    colorizationColor: Color.palette.base05
                }
            }
        }

        // Text Icon (fallback when no SVG or icon name)
        Text {
            id: textIcon
            visible: root.resolvedIconSource === "" && root.iconText !== ""
            anchors.verticalCenter: parent.verticalCenter
            color: root.iconColor
            font.pixelSize: root.iconSize
            font.weight: root.iconWeight
            text: root.iconText
            font.family: root.fontFamily
        }

        // Button text label
        Text {
            id: textItem
            visible: root.hasText
            anchors.verticalCenter: parent.verticalCenter
            color: root.textColor
            font.pixelSize: Math.round(root.iconSize * 0.75)
            font.weight: Font.Medium
            text: root.text
            font.family: root.fontFamily
        }
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
