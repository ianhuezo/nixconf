pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    // Store original colors for fallback
    readonly property QtObject defaultPalette: QtObject {
        readonly property color base00: "#0D121B"
        readonly property color base01: "#111A2C"
        readonly property color base02: "#1A263B"
        readonly property color base03: "#2A3E5C"
        readonly property color base04: "#6C8CB7"
        readonly property color base05: "#E0F2F7"
        readonly property color base06: "#F0F8FA"
        readonly property color base07: "#FDFEFF"
        readonly property color base08: "#F7768E"
        readonly property color base09: "#FF9E64"
        readonly property color base0B: "#A0E6FF"
        readonly property color base0C: "#89DDFF"
        readonly property color base0D: "#7AA2F7"
    }

    // Current palette (modifiable)
    property QtObject palette: QtObject {
        property color base00: root.defaultPalette.base00
        property color base01: root.defaultPalette.base01
        property color base02: root.defaultPalette.base02
        property color base03: root.defaultPalette.base03
        property color base04: root.defaultPalette.base04
        property color base05: root.defaultPalette.base05
        property color base06: root.defaultPalette.base06
        property color base07: root.defaultPalette.base07
        property color base08: root.defaultPalette.base08
        property color base09: root.defaultPalette.base09
        property color base0B: root.defaultPalette.base0B
        property color base0C: root.defaultPalette.base0C
        property color base0D: root.defaultPalette.base0D
    }

    function loadTheme(path: string): bool {
        try {
            // Read the JSON file
            let xhr = new XMLHttpRequest();
            xhr.open("GET", "file://" + path, false);
            xhr.send();

            if (xhr.status !== 200) {
                console.warn("Failed to load theme file:", path);
                resetToDefault();
                return false;
            }

            // Parse JSON
            let themeData = JSON.parse(xhr.responseText);

            // Validate that it's a proper theme object
            if (!themeData.palette) {
                console.warn("Invalid theme format: missing 'palette' object");
                resetToDefault();
                return false;
            }

            // Apply colors using loop
            let newPalette = themeData.palette;
            for (let key in newPalette) {
                if (palette.hasOwnProperty(key)) {
                    palette[key] = newPalette[key];
                }
            }

            console.log("Theme loaded successfully:", path);
            return true;
        } catch (error) {
            console.error("Error loading theme:", error.message);
            resetToDefault();
            return false;
        }
    }

    function resetToDefault(): void {
        for (let key in defaultPalette) {
            if (palette.hasOwnProperty(key)) {
                palette[key] = defaultPalette[key];
            }
        }
        console.log("Theme reset to default");
    }
}
