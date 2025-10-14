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

    // Public properties - Tooltip
    property string tooltip: ""

    // Public properties - State
    property bool disabled: false
    property bool loading: false

    // Public properties - Colors
    property color iconColor: disabled || loading ? Color.palette.base03 : Color.palette.base05
    property color textColor: disabled || loading ? Color.palette.base03 : Color.palette.base05
    property color backgroundColor: disabled || loading ? Color.palette.base01 : Color.palette.base02
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

    // Loading spinner overlay
    Item {
        id: loadingSpinner
        visible: root.loading
        anchors.fill: parent

        Canvas {
            id: spinnerCanvas
            anchors.fill: parent
            rotation: 0

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();

                var centerX = width / 2;
                var centerY = height / 2;
                var radius = Math.min(width, height) / 2 - 2;

                // Draw arc
                ctx.strokeStyle = root.iconColor;
                ctx.lineWidth = 2;
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, 0, Math.PI * 1.5);
                ctx.stroke();
            }

            RotationAnimator on rotation {
                running: root.loading
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
            }

            onVisibleChanged: {
                if (visible)
                    requestPaint();
            }
        }

        Connections {
            target: root
            function onIconColorChanged() {
                spinnerCanvas.requestPaint();
            }
        }
    }

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
                visible: true
                layer.enabled: true
                layer.effect: MultiEffect {
                    colorization: 1.0
                    colorizationColor: root.iconColor
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
        cursorShape: root.disabled || root.loading ? Qt.ArrowCursor : Qt.PointingHandCursor
        onPressed: (root.disabled || root.loading) ? () => {} : root.clicked()
        hoverEnabled: !root.disabled && !root.loading

        onEntered: {
            if (root.disabled || root.loading) {
                return;
            }
            root.border.color = Color.palette.base05;
            root.border.width = 1;

            if (root.tooltip !== "") {
                tooltipTimer.start();
            }
        }

        onExited: {
            root.border.color = '';
            root.border.width = 0;
            tooltipTimer.stop();
            tooltipPopup.visible = false;
        }
    }

    // Tooltip timer - delays showing tooltip
    Timer {
        id: tooltipTimer
        interval: 500
        onTriggered: {
            if (root.tooltip !== "" && area.containsMouse) {
                tooltipPopup.visible = true;
            }
        }
    }

    // Tooltip popup
    Rectangle {
        id: tooltipPopup
        visible: false
        color: Color.palette.base0F
        radius: 4
        width: tooltipText.implicitWidth + 16
        height: tooltipText.implicitHeight + 12
        x: root.width / 2 - width / 2
        y: root.height + 8
        z: 1000
        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: root.tooltip
            color: Color.palette.base05
            font.pixelSize: 12
            font.family: root.fontFamily
        }
        // Small arrow pointing up to button
        Canvas {
            id: tooltipArrow
            width: 8
            height: 4
            x: parent.width / 2 - width / 2
            y: -4
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = Color.palette.base05;
                // Draw triangle
                ctx.beginPath();
                ctx.moveTo(0, height);
                ctx.lineTo(width / 2, 0);
                ctx.lineTo(width, height);
                ctx.closePath();
                ctx.fill();
            }
        }
    }
}
