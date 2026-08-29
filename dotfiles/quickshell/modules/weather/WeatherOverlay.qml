import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services

// Frameless weather overlay that reads as if painted onto the wallpaper.
// No surface, border, or gradient: text and line-art sit directly on the
// wallpaper, kept legible by a low-alpha deep-navy outline/shadow.
// Placement and styling are chosen per active wallpaper (via `swww query`).
PanelWindow {
    id: root

    required property var weather

    // --- wallpaper-aware profiles -------------------------------------------
    // Keyed by substring of the wallpaper file basename reported by swww.
    // "default" is the fallback for any unmatched wallpaper. The anchor side
    // is fixed (always left-anchored, marginX 64); profiles only tune the
    // vertical margin, scale and outline strength per backdrop.
    property var wallpaperProfiles: ({
        "frieren": {
            marginY: 70,
            scale: 1.0,
            shadowAlpha: 0.45
        },
        "default": {
            // Unknown wallpaper: slightly stronger outline for safety on
            // busy backdrops.
            marginY: 84,
            scale: 0.9,
            shadowAlpha: 0.65
        }
    })

    property string wallpaperName: ""
    readonly property var profile: resolveProfile()

    function resolveProfile() {
        const name = wallpaperName.toLowerCase();
        for (const key in wallpaperProfiles) {
            if (key === "default")
                continue;
            if (name.indexOf(key) !== -1)
                return wallpaperProfiles[key];
        }
        return wallpaperProfiles["default"];
    }

    // Parse `swww query` output: prefer a line naming our monitor, otherwise
    // the first path-like token found. Empty/failed output keeps the current
    // profile (which starts as "default") — never crash on failure.
    function applySwwwQuery(output) {
        if (!output)
            return;
        const lines = output.split("\n");
        let chosen = "";
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            const match = line.match(/([^\s]+\.(?:png|jpe?g|webp|gif|bmp))/i);
            if (!match)
                continue;
            if (line.indexOf("HDMI-A-1") !== -1 || chosen.length === 0)
                chosen = match[1];
        }
        if (chosen.length === 0)
            return;
        wallpaperName = chosen.replace(/^.*\//, "").toLowerCase();
    }

    function refreshWallpaper() {
        if (!swwwQuery.running)
            swwwQuery.running = true;
    }

    readonly property color textMain: Color.palette.base05
    readonly property color textAccent: Color.palette.base0C
    readonly property color textMuted: Color.palette.base04
    readonly property color shadowColor: Qt.rgba(
        Color.palette.base00.r,
        Color.palette.base00.g,
        Color.palette.base00.b,
        profile.shadowAlpha
    )

    implicitWidth: 560
    implicitHeight: 360
    color: "transparent"
    visible: true

    anchors {
        top: true
        left: true
    }

    margins {
        top: profile.marginY
        left: 64
    }

    WlrLayershell.namespace: "quickshell-weather"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    Process {
        id: swwwQuery

        command: ["swww", "query"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.applySwwwQuery(text)
        }

        stderr: StdioCollector {}

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                console.warn("WeatherOverlay: swww query failed with exit code", exitCode, "- using default profile");
        }
    }

    // Re-check the wallpaper periodically and after each fetch cycle.
    Timer {
        interval: 10 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refreshWallpaper()
    }

    Connections {
        target: root.weather

        function onUpdatedAtChanged() {
            root.refreshWallpaper();
        }
    }

    Column {
        id: content

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 12
            rightMargin: 12
            topMargin: 4
        }
        spacing: 4

        WeatherIcon {
            width: 116 * root.profile.scale
            height: width
            kind: root.weather.weatherKind
            isNight: root.weather.isNight
            opacity: root.weather.hasData ? 0.95 : 0.45

            Behavior on opacity {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.InOutCubic
                }
            }
        }

        Text {
            width: parent.width
            text: root.weather.temperature + "°"
            color: root.textMain
            font.family: AppearanceConfig.font.display
            font.pixelSize: Math.round(68 * root.profile.scale)
            font.weight: AppearanceConfig.font.weight.light
            style: Text.Outline
            styleColor: root.shadowColor
        }

        Text {
            width: parent.width
            text: root.weather.errorMessage.length > 0
                ? root.weather.errorMessage
                : (root.weather.hasData ? root.weather.description : "Waiting for wttr.in")
            color: root.textAccent
            font.family: AppearanceConfig.font.ui
            font.pixelSize: AppearanceConfig.font.size.md
            font.weight: AppearanceConfig.font.weight.medium
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: root.shadowColor
        }

        Text {
            width: parent.width
            text: (root.weather.windDirection.length > 0 ? root.weather.windDirection + " " : "")
                + root.weather.windSpeed + " mph   ·   "
                + root.weather.humidity + "%   ·   feels "
                + root.weather.feelsLike + "°F"
            color: root.textMuted
            font.family: AppearanceConfig.font.mono
            font.pixelSize: AppearanceConfig.font.size.xs
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: root.shadowColor
        }

        Text {
            width: parent.width
            visible: root.weather.hasData && root.weather.location.length > 0
            text: root.weather.location.toUpperCase()
            color: root.textMuted
            opacity: 0.6
            font.family: AppearanceConfig.font.mono
            font.pixelSize: AppearanceConfig.font.size.xs
            font.letterSpacing: 1.5
            elide: Text.ElideRight
            style: Text.Outline
            styleColor: root.shadowColor
        }
    }
}
