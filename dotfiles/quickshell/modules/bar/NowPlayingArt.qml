import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick.Effects
import qs.services
import qs.modules.music_popup

Item {
    id: root

    property var cavaValues: []
    property real audioThreshold: 0.05  // Threshold below which animation pauses
    property bool hasAudio: false
    property real borderOpacity: 0.0  // Controls fade in/out

    // Calculate if there's active audio
    onCavaValuesChanged: {
        if (!cavaValues || cavaValues.length === 0) {
            hasAudio = false;
            return;
        }

        // Check if any cava value exceeds threshold
        let maxValue = 0;
        for (let i = 0; i < cavaValues.length; i++) {
            if (cavaValues[i] > maxValue) {
                maxValue = cavaValues[i];
            }
        }
        hasAudio = maxValue > audioThreshold;
    }

    // Fade in when audio starts, fade out when it stops
    Behavior on borderOpacity {
        NumberAnimation {
            duration: 800 // Faster fade in, slower fade out
            easing.type: Easing.Linear
        }
    }

    onHasAudioChanged: {
        borderOpacity = hasAudio ? 1.0 : 0.0;
    }

    // Animated border that travels around the perimeter
    Canvas {
        id: borderCanvas
        anchors.fill: parent
        z: 1

        property real phase: 0
        property color glowColor: Color.palette.base0C

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            // Only draw if there's any opacity
            if (root.borderOpacity <= 0) {
                return;
            }

            var borderWidth = 3;
            var imageRadius = 5; // The mask radius
            var radius = imageRadius + 3; // Border radius = image radius + margin
            var glowLength = 60; // Length of the glowing section in pixels

            // Draw border around the inset image (outset border)
            // The image has 3px margins, border goes around the outside of those margins
            var w = width - borderWidth;
            var h = height - borderWidth;
            var offset = borderWidth / 2;
            var offsetY = borderWidth / 2;

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
                var opacity = 1 - (i / glowLength);
                opacity = opacity * opacity; // Ease out

                // Multiply by borderOpacity for fade in/out
                ctx.strokeStyle = Qt.rgba(glowColor.r, glowColor.g, glowColor.b, opacity * 0.9 * root.borderOpacity);

                // Draw a small segment at this position
                ctx.beginPath();
                var segmentLength = 2;
                drawRoundedRectSegment(ctx, pos, segmentLength, w, h, radius, offset, offsetY);
                ctx.stroke();
            }
        }

        onGlowColorChanged: requestPaint()

        Connections {
            target: root
            function onBorderOpacityChanged() {
                borderCanvas.requestPaint();
            }
        }

        function drawRoundedRectSegment(ctx, startPos, length, w, h, radius, offsetX, offsetY) {
            var straightW = w - 2 * radius;
            var straightH = h - 2 * radius;
            var cornerPerimeter = Math.PI * radius / 2;

            var pos = startPos;

            // Top edge (excluding corners)
            if (pos < straightW) {
                ctx.moveTo(offsetX + radius + pos, offsetY);
                ctx.lineTo(offsetX + radius + Math.min(pos + length, straightW), offsetY);
                return;
            }
            pos -= straightW;

            // Top-right corner
            if (pos < cornerPerimeter) {
                var angle = -Math.PI / 2 + (pos / cornerPerimeter) * (Math.PI / 2);
                var endAngle = -Math.PI / 2 + (Math.min(pos + length, cornerPerimeter) / cornerPerimeter) * (Math.PI / 2);
                ctx.arc(offsetX + radius + straightW, offsetY + radius, radius, angle, endAngle, false);
                return;
            }
            pos -= cornerPerimeter;

            // Right edge
            if (pos < straightH) {
                ctx.moveTo(offsetX + w, offsetY + radius + pos);
                ctx.lineTo(offsetX + w, offsetY + radius + Math.min(pos + length, straightH));
                return;
            }
            pos -= straightH;

            // Bottom-right corner
            if (pos < cornerPerimeter) {
                var angle = 0 + (pos / cornerPerimeter) * (Math.PI / 2);
                var endAngle = 0 + (Math.min(pos + length, cornerPerimeter) / cornerPerimeter) * (Math.PI / 2);
                ctx.arc(offsetX + radius + straightW, offsetY + radius + straightH, radius, angle, endAngle, false);
                return;
            }
            pos -= cornerPerimeter;

            // Bottom edge
            if (pos < straightW) {
                ctx.moveTo(offsetX + radius + straightW - pos, offsetY + h);
                ctx.lineTo(offsetX + radius + straightW - Math.min(pos + length, straightW), offsetY + h);
                return;
            }
            pos -= straightW;

            // Bottom-left corner
            if (pos < cornerPerimeter) {
                var angle = Math.PI / 2 + (pos / cornerPerimeter) * (Math.PI / 2);
                var endAngle = Math.PI / 2 + (Math.min(pos + length, cornerPerimeter) / cornerPerimeter) * (Math.PI / 2);
                ctx.arc(offsetX + radius, offsetY + radius + straightH, radius, angle, endAngle, false);
                return;
            }
            pos -= cornerPerimeter;

            // Left edge
            if (pos < straightH) {
                ctx.moveTo(offsetX, offsetY + radius + straightH - pos);
                ctx.lineTo(offsetX, offsetY + radius + straightH - Math.min(pos + length, straightH));
                return;
            }
            pos -= straightH;

            // Top-left corner
            if (pos < cornerPerimeter) {
                var angle = Math.PI + (pos / cornerPerimeter) * (Math.PI / 2);
                var endAngle = Math.PI + (Math.min(pos + length, cornerPerimeter) / cornerPerimeter) * (Math.PI / 2);
                ctx.arc(offsetX + radius, offsetY + radius, radius, angle, endAngle, false);
                return;
            }
        }

        NumberAnimation on phase {
            from: 0
            to: 360
            duration: 2500
            loops: Animation.Infinite
            easing.type: Easing.Linear
            running: true  // Always running for smooth continuous loop
        }

        onPhaseChanged: requestPaint()
    }

    Image {
        id: artImage
        anchors.fill: parent
        anchors.margins: 3  // Inset by border width
        fillMode: Image.PreserveAspectFit
        sourceSize.width: height
        sourceSize.height: height
        mipmap: true
        smooth: true
        antialiasing: true
        asynchronous: true
        cache: true
        visible: true
        layer.enabled: true
        layer.smooth: true
        layer.samples: 4
        layer.effect: MultiEffect {
            maskEnabled: true
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: artImage.width
                    height: artImage.height
                    radius: 5
                }
                width: artImage.width
                height: artImage.height
            }
        }
    }
    // Separate property to determine the art URL
    property var currentPlayer: null
    property string defaultFilePath: root.getPreferredPlayer()?.trackArtUrl || ""
    property string filePath: ""
    property string localTrackFile: ""
    property string currentSource: "" // Add this property to break the binding loop

    function getPreferredPlayer() {
        let activePlayer = null;
        let players = Array.from(Mpris.players.values);
        activePlayer = players.find(p => p.identity === "Spotify" && p.playbackState === MprisPlaybackState.Playing);
        if (!activePlayer) {
            activePlayer = players.find(p => p.playbackState === MprisPlaybackState.Playing);
        }
        if (!activePlayer) {
            activePlayer = players.find(p => p.identity === "Spotify") || players[0];
        }
        if (activePlayer?.identity == "Spotify") {
            const trackTitle = activePlayer.trackTitle;
            root.localTrackFile = trackTitle;
        }
        return activePlayer;
    }

    function updateSource() {
        let baseSource = root.defaultFilePath || root.getPreferredPlayer()?.trackArtUrl || extractMP3Image.localFilePath || "";
        // Add cache busting for local files based on current timestamp
        if (baseSource && (baseSource.startsWith("file://") || baseSource.startsWith("/tmp/FRONT_COVER"))) {
            baseSource += "?t=" + Date.now();
        }
        root.currentSource = baseSource;
    }

    Component.onCompleted: updateSource()
    onDefaultFilePathChanged: updateSource()

    Connections {
        target: root.getPreferredPlayer() || null
        ignoreUnknownSignals: true
        function onPostTrackChanged() {
            root.defaultFilePath = null; //no longer need a default
            root.filePath = target?.trackArtUrl || "";
            if (root.filePath === "" && target?.identity === "Spotify") {
                const trackTitle = target?.trackTitle;
                root.localTrackFile = trackTitle;
            }
            root.updateSource(); // Update source after track change
        }
        function onPlaybackStateChanged() {
            // Requery image when playback state changes (e.g., play is triggered)
            root.updateSource();
        }
    }
    onLocalTrackFileChanged: {
        if (root.localTrackFile.length <= 0) {
            return;
        }
        extractMP3Image.mp3FileName = root.localTrackFile + '.mp3';
        extractMP3Image.running = true;
    }

    ExtractMP3Image {
        id: extractMP3Image
        mediaFolder: '/home/ianh/Music'
        mp3FileName: ''
        property string localFilePath: ''
        onFileCreated: fileName => {
            localFilePath = fileName;
            extractMP3Image.running = false;
            root.updateSource(); // Update source when local file is ready
        }
        onError: error => {}
        // Clear local file when track changes
        onMp3FileNameChanged: {
            localFilePath = '';
            root.updateSource(); // Update source when local file is cleared
        }
    }

    Rectangle {
        id: placeholder
        anchors.fill: artImage
        color: Color.palette.base03// Darker gray for better contrast
        visible: artImage.status !== Image.Ready
        // Music note icon as placeholder
        Text {
            anchors.centerIn: parent
            text: "♪"  // Music note symbol
            color: Color.palette.base09
            font.pixelSize: 16
        }
        // Rounded corners for placeholder too
        radius: 4
    }

    // Bind the source to artImage
    Binding {
        target: artImage
        property: "source"
        value: root.currentSource
    }

    // Handle HTTP/2 and other loading errors
    Connections {
        target: artImage
        function onStatusChanged() {
            if (artImage.status === Image.Error) {
                console.warn("Failed to load album art:", root.currentSource);
                // On error, try to reload or clear the source
                if (root.currentSource && !root.currentSource.startsWith("/tmp/")) {
                    // If it's a remote URL that failed, trigger local extraction as fallback
                    const player = root.getPreferredPlayer();
                    if (player?.identity === "Spotify" && player?.trackTitle) {
                        console.log("Attempting to load local album art for:", player.trackTitle);
                        root.localTrackFile = player.trackTitle;
                    }
                }
            }
        }
    }
    // Item {
    //     id: mask
    //     width: root.width
    //     height: root.height
    //     layer.enabled: true
    //     visible: false
    //
    //     Rectangle {
    //         width: root.width
    //         height: root.height
    //         radius: width / 2
    //         color: "white"  // Mask should use white/black, not palette colors
    //     }
    // }
    //
    // MultiEffect {
    //     source: root
    //     anchors.fill: root
    //     maskEnabled: true
    //     maskSource: mask
    //     maskThresholdMin: 0.5
    //     maskSpreadAtMin: 1.0
    // }
}
