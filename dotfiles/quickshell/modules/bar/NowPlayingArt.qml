import QtQuick
import Quickshell.Services.Mpris
import Quickshell.Io
import QtQuick.Effects
import QtQuick.Shapes
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
    Shape {
        id: borderGlow
        anchors.fill: parent
        z: 1
        visible: root.borderOpacity > 0
        opacity: root.borderOpacity
        preferredRendererType: Shape.CurveRenderer

        property real phase: 0
        property color glowColor: Color.palette.base0C
        readonly property real trail: 60 / (2 * (width + height))

        function glowAt(fraction) {
            return Qt.rgba(glowColor.r, glowColor.g, glowColor.b, 0.9 * fraction * fraction);
        }

        ShapePath {
            strokeColor: "transparent"
            fillRule: ShapePath.OddEvenFill
            fillGradient: ConicalGradient {
                centerX: borderGlow.width / 2
                centerY: borderGlow.height / 2
                angle: -borderGlow.phase

                GradientStop {
                    position: 0
                    color: borderGlow.glowAt(0)
                }
                GradientStop {
                    position: borderGlow.trail * 0.25
                    color: borderGlow.glowAt(0.25)
                }
                GradientStop {
                    position: borderGlow.trail * 0.5
                    color: borderGlow.glowAt(0.5)
                }
                GradientStop {
                    position: borderGlow.trail * 0.75
                    color: borderGlow.glowAt(0.75)
                }
                GradientStop {
                    position: borderGlow.trail
                    color: borderGlow.glowAt(1)
                }
                GradientStop {
                    position: borderGlow.trail + 0.001
                    color: borderGlow.glowAt(0)
                }
            }

            PathRectangle {
                width: borderGlow.width
                height: borderGlow.height
                radius: 9.5
            }
            PathRectangle {
                x: 3
                y: 3
                width: borderGlow.width - 6
                height: borderGlow.height - 6
                radius: 6.5
            }
        }

        // Traveling glow, stepped at ~30fps instead of every vsync (240Hz on
        // the primary monitor), and paused entirely while the glow is faded
        // out. Same 144 deg/s sweep as the old always-running animation.
        Timer {
            interval: 33
            running: root.borderOpacity > 0
            repeat: true
            onTriggered: borderGlow.phase = (borderGlow.phase + 360 * interval / 2500) % 360
        }
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
        retainWhileLoading: true
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
        visible: artImage.status === Image.Null || artImage.status === Image.Error
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
