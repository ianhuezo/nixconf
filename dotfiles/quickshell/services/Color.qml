pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    function loadTheme(path: string) {
    }

    component Colors: QtObject {
        readonly property color base00: "#0D121B" // Deepest background
        readonly property color base01: "#111A2C" // Slightly lighter background
        readonly property color base02: "#1A263B" // Mid-dark background
        readonly property color base03: "#2A3E5C" // Foreground Dim / Subtle border
        readonly property color base04: "#6C8CB7" // Foreground Mid
        readonly property color base05: "#E0F2F7" // Foreground Light / Primary text
        readonly property color base06: "#F0F8FA" // Foreground Lighter
        readonly property color base07: "#FDFEFF" // Foreground Lightest
        readonly property color base09: "#FF9E64" // Foreground Lightest
        readonly property color base0B: "#A0E6FF" // Glowing Cyan-Blue (excellent for accents)
        readonly property color base0C: "#89DDFF" // Cyan (another great accent)
        readonly property color base0D: "#7AA2F7" // Blue (deeper accent)
    }
}
