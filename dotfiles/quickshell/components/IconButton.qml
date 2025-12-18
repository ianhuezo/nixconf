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
    property int pressHoldDuration: 2000 // milliseconds - increased for better UX
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

    // Vertical translation for hover and press states
    transform: Translate {
        y: {
            if (root.disabled || root.loading) return 0;
            if (area.pressed || root.isPressHolding) return 2;  // Pressed: translate down
            if (root.hovered) return -2;  // Hovered: translate up
            return 0;  // Default: no translation
        }

        Behavior on y {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
    }

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
        active: false  // Disabled - using new animated border instead
        effectType: root.loadingEffectType
        primaryColor: root.loadingPrimaryColor
        secondaryColor: root.loadingSecondaryColor
        radius: root.radius
        anchors.fill: parent
        z: 10
        visible: false
    }

    // Loading/processing animated border (similar to NowPlayingArt)
    Canvas {
        id: loadingBorder
        anchors.fill: parent
        anchors.margins: -3
        z: 20
        visible: root.loading
        opacity: root.loading ? 1.0 : 0.0

        property real phase: 0
        property color glowColor: Color.palette.base09

        Behavior on opacity {
            NumberAnimation {
                duration: root.loading ? 300 : 800
                easing.type: Easing.InOutQuad
            }
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            // Only draw if there's any opacity
            if (opacity <= 0) {
                return;
            }

            var borderWidth = 3;
            var radius = root.radius;
            var glowLength = 60; // Length of the glowing section in pixels
            var offset = borderWidth / 2;

            // Calculate rounded rect path
            var w = width - borderWidth;
            var h = height - borderWidth;

            // Calculate perimeter including rounded corners
            var straightW = w - 2 * radius;
            var straightH = h - 2 * radius;
            var cornerPerimeter = Math.PI * radius / 2; // Quarter circle
            var perimeter = 2 * straightW + 2 * straightH + 4 * cornerPerimeter;

            // Current position along perimeter based on phase
            var currentPos = (phase / 360) * perimeter;

            ctx.lineWidth = borderWidth;
            ctx.lineCap = "round";

            // Draw the glowing segment
            for (var i = 0; i < glowLength; i++) {
                var pos = (currentPos + i) % perimeter;

                // Calculate opacity (fade from full to transparent)
                var segmentOpacity = 1 - (i / glowLength);
                segmentOpacity = segmentOpacity * segmentOpacity; // Ease out

                // Multiply by border opacity for fade in/out
                ctx.strokeStyle = Qt.rgba(
                    glowColor.r,
                    glowColor.g,
                    glowColor.b,
                    segmentOpacity * 0.9 * opacity
                );

                // Draw a small segment at this position
                ctx.beginPath();
                var segmentLength = 2;
                drawRoundedRectSegment(ctx, pos, segmentLength, w, h, radius, offset);
                ctx.stroke();
            }
        }

        function drawRoundedRectSegment(ctx, startPos, length, w, h, radius, offset) {
            var straightW = w - 2 * radius;
            var straightH = h - 2 * radius;
            var cornerPerimeter = Math.PI * radius / 2;

            var pos = startPos;

            // Top edge (excluding corners)
            if (pos < straightW) {
                ctx.moveTo(offset + radius + pos, offset);
                ctx.lineTo(offset + radius + Math.min(pos + length, straightW), offset);
                return;
            }
            pos -= straightW;

            // Top-right corner
            if (pos < cornerPerimeter) {
                var angle = -Math.PI / 2 + (pos / cornerPerimeter) * (Math.PI / 2);
                var endAngle = -Math.PI / 2 + (Math.min(pos + length, cornerPerimeter) / cornerPerimeter) * (Math.PI / 2);
                ctx.arc(offset + radius + straightW, offset + radius, radius, angle, endAngle, false);
                return;
            }
            pos -= cornerPerimeter;

            // Right edge
            if (pos < straightH) {
                ctx.moveTo(offset + w, offset + radius + pos);
                ctx.lineTo(offset + w, offset + radius + Math.min(pos + length, straightH));
                return;
            }
            pos -= straightH;

            // Bottom-right corner
            if (pos < cornerPerimeter) {
                var angle = 0 + (pos / cornerPerimeter) * (Math.PI / 2);
                var endAngle = 0 + (Math.min(pos + length, cornerPerimeter) / cornerPerimeter) * (Math.PI / 2);
                ctx.arc(offset + radius + straightW, offset + radius + straightH, radius, angle, endAngle, false);
                return;
            }
            pos -= cornerPerimeter;

            // Bottom edge
            if (pos < straightW) {
                ctx.moveTo(offset + radius + straightW - pos, offset + h);
                ctx.lineTo(offset + radius + straightW - Math.min(pos + length, straightW), offset + h);
                return;
            }
            pos -= straightW;

            // Bottom-left corner
            if (pos < cornerPerimeter) {
                var angle = Math.PI / 2 + (pos / cornerPerimeter) * (Math.PI / 2);
                var endAngle = Math.PI / 2 + (Math.min(pos + length, cornerPerimeter) / cornerPerimeter) * (Math.PI / 2);
                ctx.arc(offset + radius, offset + radius + straightH, radius, angle, endAngle, false);
                return;
            }
            pos -= cornerPerimeter;

            // Left edge
            if (pos < straightH) {
                ctx.moveTo(offset, offset + radius + straightH - pos);
                ctx.lineTo(offset, offset + radius + straightH - Math.min(pos + length, straightH));
                return;
            }
            pos -= straightH;

            // Top-left corner
            if (pos < cornerPerimeter) {
                var angle = Math.PI + (pos / cornerPerimeter) * (Math.PI / 2);
                var endAngle = Math.PI + (Math.min(pos + length, cornerPerimeter) / cornerPerimeter) * (Math.PI / 2);
                ctx.arc(offset + radius, offset + radius, radius, angle, endAngle, false);
                return;
            }
        }

        NumberAnimation on phase {
            from: 0
            to: 360
            duration: 2500
            loops: Animation.Infinite
            easing.type: Easing.InOutSine
            running: root.loading
        }

        onPhaseChanged: requestPaint()
        onOpacityChanged: requestPaint()
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

    // Hover effect - border highlight using layered rectangle for smooth borders
    Rectangle {
        id: hoverBorder
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.color: Color.palette.base05
        border.width: root.hovered && !root.disabled && !root.loading && !root.isPressHolding ? 1 : 0
        z: 10

        layer.enabled: true
        layer.smooth: true
        layer.samples: 4

        Behavior on border.width {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
    }

    // Press-hold animated border indicator - draws continuous border filling to 100%
    Canvas {
        id: pressHoldBorder
        anchors.fill: parent
        anchors.margins: -2
        z: 15
        visible: root.pressHoldEnabled
        opacity: root.isPressHolding ? 1.0 : 0

        property real progress: 0  // 0 to 1
        property real pressHoldStartTime: 0

        Behavior on opacity {
            NumberAnimation {
                duration: 100
                easing.type: Easing.OutQuad
            }
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            if (opacity <= 0 || progress <= 0) {
                return;
            }

            var borderWidth = 2;
            var radius = root.radius;
            var offset = borderWidth / 2;

            // Calculate rounded rect path
            var w = width - borderWidth;
            var h = height - borderWidth;

            // Calculate perimeter including rounded corners
            var straightW = w - 2 * radius;
            var straightH = h - 2 * radius;
            var cornerPerimeter = Math.PI * radius / 2; // Quarter circle
            var perimeter = 2 * straightW + 2 * straightH + 4 * cornerPerimeter;

            // Length to draw based on progress (0 to full perimeter)
            var drawLength = progress * perimeter;

            ctx.lineWidth = borderWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            // Draw the border from start (0) to current progress position
            var baseColor = Color.palette.base0C;
            ctx.strokeStyle = Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.9);

            // Draw continuous path from 0 to drawLength
            ctx.beginPath();
            drawBorderPath(ctx, 0, drawLength, w, h, radius, offset);
            ctx.stroke();
        }

        function drawBorderPath(ctx, startLength, endLength, w, h, radius, offset) {
            var straightW = w - 2 * radius;
            var straightH = h - 2 * radius;
            var cornerPerimeter = Math.PI * radius / 2;

            var currentLength = 0;
            var started = false;

            // Helper function to draw or move based on whether we've started
            function processSegment(segmentStart, segmentEnd, drawFunc) {
                if (endLength <= segmentStart) return false; // We're done
                if (startLength >= segmentEnd) return true; // Skip this segment

                var localStart = Math.max(0, startLength - segmentStart);
                var localEnd = Math.min(segmentEnd - segmentStart, endLength - segmentStart);

                if (!started) {
                    started = true;
                    drawFunc(localStart, localEnd, true); // true = move to start
                } else {
                    drawFunc(localStart, localEnd, false); // false = continue path
                }
                return endLength > segmentEnd;
            }

            // Top edge
            var topEnd = currentLength + straightW;
            if (!processSegment(currentLength, topEnd, function(start, end, moveToStart) {
                if (moveToStart) {
                    ctx.moveTo(offset + radius + start, offset);
                }
                ctx.lineTo(offset + radius + end, offset);
            })) return;
            currentLength = topEnd;

            // Top-right corner
            var trEnd = currentLength + cornerPerimeter;
            if (!processSegment(currentLength, trEnd, function(start, end, moveToStart) {
                var startAngle = -Math.PI / 2 + (start / cornerPerimeter) * (Math.PI / 2);
                var endAngle = -Math.PI / 2 + (end / cornerPerimeter) * (Math.PI / 2);
                if (moveToStart) {
                    var startX = offset + radius + straightW + radius * Math.cos(startAngle);
                    var startY = offset + radius + radius * Math.sin(startAngle);
                    ctx.moveTo(startX, startY);
                }
                ctx.arc(offset + radius + straightW, offset + radius, radius, startAngle, endAngle, false);
            })) return;
            currentLength = trEnd;

            // Right edge
            var rightEnd = currentLength + straightH;
            if (!processSegment(currentLength, rightEnd, function(start, end, moveToStart) {
                if (moveToStart) {
                    ctx.moveTo(offset + w, offset + radius + start);
                }
                ctx.lineTo(offset + w, offset + radius + end);
            })) return;
            currentLength = rightEnd;

            // Bottom-right corner
            var brEnd = currentLength + cornerPerimeter;
            if (!processSegment(currentLength, brEnd, function(start, end, moveToStart) {
                var startAngle = 0 + (start / cornerPerimeter) * (Math.PI / 2);
                var endAngle = 0 + (end / cornerPerimeter) * (Math.PI / 2);
                if (moveToStart) {
                    var startX = offset + radius + straightW + radius * Math.cos(startAngle);
                    var startY = offset + radius + straightH + radius * Math.sin(startAngle);
                    ctx.moveTo(startX, startY);
                }
                ctx.arc(offset + radius + straightW, offset + radius + straightH, radius, startAngle, endAngle, false);
            })) return;
            currentLength = brEnd;

            // Bottom edge
            var bottomEnd = currentLength + straightW;
            if (!processSegment(currentLength, bottomEnd, function(start, end, moveToStart) {
                if (moveToStart) {
                    ctx.moveTo(offset + radius + straightW - start, offset + h);
                }
                ctx.lineTo(offset + radius + straightW - end, offset + h);
            })) return;
            currentLength = bottomEnd;

            // Bottom-left corner
            var blEnd = currentLength + cornerPerimeter;
            if (!processSegment(currentLength, blEnd, function(start, end, moveToStart) {
                var startAngle = Math.PI / 2 + (start / cornerPerimeter) * (Math.PI / 2);
                var endAngle = Math.PI / 2 + (end / cornerPerimeter) * (Math.PI / 2);
                if (moveToStart) {
                    var startX = offset + radius + radius * Math.cos(startAngle);
                    var startY = offset + radius + straightH + radius * Math.sin(startAngle);
                    ctx.moveTo(startX, startY);
                }
                ctx.arc(offset + radius, offset + radius + straightH, radius, startAngle, endAngle, false);
            })) return;
            currentLength = blEnd;

            // Left edge
            var leftEnd = currentLength + straightH;
            if (!processSegment(currentLength, leftEnd, function(start, end, moveToStart) {
                if (moveToStart) {
                    ctx.moveTo(offset, offset + radius + straightH - start);
                }
                ctx.lineTo(offset, offset + radius + straightH - end);
            })) return;
            currentLength = leftEnd;

            // Top-left corner
            var tlEnd = currentLength + cornerPerimeter;
            processSegment(currentLength, tlEnd, function(start, end, moveToStart) {
                var startAngle = Math.PI + (start / cornerPerimeter) * (Math.PI / 2);
                var endAngle = Math.PI + (end / cornerPerimeter) * (Math.PI / 2);
                if (moveToStart) {
                    var startX = offset + radius + radius * Math.cos(startAngle);
                    var startY = offset + radius + radius * Math.sin(startAngle);
                    ctx.moveTo(startX, startY);
                }
                ctx.arc(offset + radius, offset + radius, radius, startAngle, endAngle, false);
            });
        }

        Timer {
            id: progressUpdateTimer
            interval: 16 // ~60fps
            repeat: true
            running: root.isPressHolding
            onTriggered: {
                if (root.isPressHolding && pressHoldBorder.pressHoldStartTime > 0) {
                    var elapsed = Date.now() - pressHoldBorder.pressHoldStartTime;
                    pressHoldBorder.progress = Math.min(1.0, elapsed / root.pressHoldDuration);
                    pressHoldBorder.requestPaint();
                }
            }
        }

        Connections {
            target: root
            function onIsPressHoldingChanged() {
                if (root.isPressHolding) {
                    pressHoldBorder.pressHoldStartTime = Date.now();
                    pressHoldBorder.progress = 0;
                } else {
                    pressHoldBorder.progress = 0;
                }
                pressHoldBorder.requestPaint();
            }
        }

        onProgressChanged: requestPaint()
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
