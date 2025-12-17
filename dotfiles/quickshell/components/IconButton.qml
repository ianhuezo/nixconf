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

    // Important as this could clip your tooltip if not done correctly
    property var toolTipContainer: root

    // Public properties - SVG
    property string svgSource: ""
    property string iconName: "" // GTK icon name (e.g., "document-save", "edit-copy")

    // Public properties - Tooltip
    property string tooltip: ""

    // Public properties - State
    property bool disabled: false
    property bool loading: false
    property bool active: false // For active/inactive state indicators
    property bool hovered: false // Internal hover state

    // Public properties - Press and hold
    property bool pressHoldEnabled: false
    property int pressHoldDuration: 800 // milliseconds
    property bool isPressHolding: false // Internal state for visual feedback

    // Composable effects - set these to customize loading/state effects
    property string loadingEffectType: "spinner" // "gradient", "spinner", "pulse", "shimmer"
    property string stateEffectType: "" // "glow", "border", "pulse", "shimmer", or "" for none
    property string hoverEffectType: "glow" // Effect to show on hover
    property color loadingPrimaryColor: Color.palette.base05
    property color loadingSecondaryColor: "transparent"
    property color stateActiveColor: Color.palette.base09
    property color stateInactiveColor: Color.palette.base03

    // Public properties - Colors
    property color iconColor: disabled || loading ? Color.palette.base03 : Color.palette.base05
    property color textColor: disabled || loading ? Color.palette.base03 : Color.palette.base05
    property color backgroundColor: disabled || loading ? Color.palette.base00 : Color.palette.base02
    property int buttonRadius: AppearanceConfig.radius.md

    // Signals
    signal clicked
    signal pressHeld // Emitted when press-and-hold duration is reached

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
    opacity: disabled || loading ? 0.5 : 1.0

    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }

    // Composable loading effect overlay
    ButtonLoadingEffect {
        id: loadingEffect
        active: root.loading
        effectType: root.loadingEffectType
        primaryColor: root.loadingPrimaryColor
        secondaryColor: root.loadingSecondaryColor
        radius: root.radius
        anchors.fill: parent
        z: 10
    }

    // Composable state effect (active/inactive indicator)
    ButtonStateEffect {
        id: stateEffect
        active: root.active && !root.disabled && !root.loading
        effectType: root.stateEffectType
        activeColor: root.stateActiveColor
        inactiveColor: root.stateInactiveColor
        radius: root.radius
        anchors.fill: parent
        z: 5
    }

    // Hover effect - simple opacity change
    Rectangle {
        id: hoverOverlay
        anchors.fill: parent
        radius: root.radius
        color: Color.palette.base05
        opacity: root.hovered && !root.disabled && !root.loading ? 0.1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
    }

    // Press-hold progress indicator
    Rectangle {
        id: pressHoldProgress
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 2
        height: 3
        radius: 1.5
        color: Color.palette.base0B // Green from base16
        opacity: root.isPressHolding ? 0.8 : 0
        visible: root.pressHoldEnabled

        width: {
            if (!root.isPressHolding) return 0;
            return (parent.width - 4) * Math.min(1.0, pressHoldTimer.interval > 0 ?
                (Date.now() - pressHoldStartTime) / pressHoldTimer.interval : 0);
        }

        property real pressHoldStartTime: 0

        Behavior on opacity {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutQuad
            }
        }

        Timer {
            id: progressUpdateTimer
            interval: 16 // ~60fps
            repeat: true
            running: root.isPressHolding
            onTriggered: {
                // Force width recalculation
                pressHoldProgress.width = Qt.binding(function() {
                    if (!root.isPressHolding) return 0;
                    return (root.width - 4) * Math.min(1.0, pressHoldTimer.interval > 0 ?
                        (Date.now() - pressHoldProgress.pressHoldStartTime) / pressHoldTimer.interval : 0);
                });
            }
        }

        Connections {
            target: root
            function onIsPressHoldingChanged() {
                if (root.isPressHolding) {
                    pressHoldProgress.pressHoldStartTime = Date.now();
                }
            }
        }
    }

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Color.palette.base00
        shadowVerticalOffset: 1
        shadowHorizontalOffset: 0
        shadowBlur: 0.4
        shadowOpacity: 0.6
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

            ColorizedImage {
                id: svgImage
                anchors.fill: parent
                source: root.resolvedIconSource
                sourceSize.width: root.iconSize
                sourceSize.height: root.iconSize
                iconColor: root.iconColor
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

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }
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

            Behavior on color {
                ColorAnimation {
                    duration: 150
                    easing.type: Easing.OutQuad
                }
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: root.disabled || root.loading ? Qt.ArrowCursor : Qt.PointingHandCursor
        hoverEnabled: !root.disabled && !root.loading

        onPressed: {
            if (root.disabled || root.loading) {
                return;
            }

            if (root.pressHoldEnabled) {
                root.isPressHolding = true;
                pressHoldTimer.start();
            } else {
                root.clicked();
            }
        }

        onReleased: {
            if (root.pressHoldEnabled) {
                pressHoldTimer.stop();
                if (root.isPressHolding) {
                    root.isPressHolding = false;
                    // If timer hasn't fired yet, treat as normal click
                    if (!pressHoldTimer.hasTriggered) {
                        root.clicked();
                    }
                    pressHoldTimer.hasTriggered = false;
                }
            }
        }

        onCanceled: {
            if (root.pressHoldEnabled) {
                pressHoldTimer.stop();
                root.isPressHolding = false;
                pressHoldTimer.hasTriggered = false;
            }
        }

        onEntered: {
            if (root.disabled || root.loading) {
                return;
            }
            root.hovered = true;

            if (root.tooltip !== "") {
                tooltipTimer.start();
            }
        }

        onExited: {
            root.hovered = false;
            tooltipTimer.stop();
            tooltipPopup.visible = false;

            // Cancel press-hold if mouse leaves button
            if (root.pressHoldEnabled && root.isPressHolding) {
                pressHoldTimer.stop();
                root.isPressHolding = false;
                pressHoldTimer.hasTriggered = false;
            }
        }
    }

    // Press and hold timer
    Timer {
        id: pressHoldTimer
        interval: root.pressHoldDuration
        property bool hasTriggered: false
        onTriggered: {
            hasTriggered = true;
            root.isPressHolding = false;
            root.pressHeld();
        }
    }

    // Tooltip timer - delays showing tooltip
    Timer {
        id: tooltipTimer
        interval: 500
        onTriggered: {
            if (root.tooltip !== "" && area.containsMouse) {
                // STEP 1: Map the button's top-left corner (0,0) to global screen coordinates.
                var globalPoint = root.mapToGlobal(0, 0);

                // STEP 2: Map that global screen point into the coordinate system of the tooltip's container.
                var positionInContainer = root.toolTipContainer.mapFromGlobal(globalPoint);

                // STEP 3: Calculate the final position and show the tooltip.
                // This logic remains the same as before.
                tooltipPopup.x = positionInContainer.x + (root.width - tooltipPopup.width) / 2;
                tooltipPopup.y = positionInContainer.y - tooltipPopup.height - 8; // 8px margin

                tooltipPopup.visible = true;
            }
        }
    }

    // Tooltip popup
    Rectangle {
        id: tooltipPopup
        visible: false // Start with visible: false
        color: Color.palette.base01  // Slightly lighter backgrounds (sidebars, cards)
        border.color: Color.palette.base03  // Borders, separators
        border.width: 1
        radius: 6
        width: tooltipText.implicitWidth + 16
        height: tooltipText.implicitHeight + 12

        // Reparent to the toolTipContainer to avoid clipping
        parent: root.toolTipContainer

        // Manual positioning when reparented
        anchors.horizontalCenter: root.toolTipContainer === root ? root.horizontalCenter : undefined
        anchors.bottom: root.toolTipContainer === root ? root.top : undefined
        anchors.bottomMargin: root.toolTipContainer === root ? 8 : 0

        z: 1000
        opacity: visible ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        Text {
            id: tooltipText
            anchors.centerIn: parent
            text: root.tooltip
            color: Color.palette.base05  // Primary text, main body content
            font.pixelSize: 11
            font.family: root.fontFamily
            horizontalAlignment: Text.AlignHCenter
        }

        // Tooltip arrow (now pointing up, positioned at the bottom)
        Rectangle {
            width: 8
            height: 8
            color: tooltipPopup.color
            rotation: 45
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom // Attach to the bottom
            anchors.bottomMargin: -3     // Overlap to create a seamless arrow
        }
    }
}
