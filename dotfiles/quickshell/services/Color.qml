pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    function loadTheme(path: string) {
    }

    property QtObject palette: QtObject {
        property color base00: "#0D121B" // Deepest background
        property color base01: "#111A2C" // Slightly lighter background
        property color base02: "#1A263B" // Mid-dark background
        property color base03: "#2A3E5C" // Foreground Dim / Subtle border
        property color base04: "#6C8CB7" // Foreground Mid
        property color base05: "#E0F2F7" // Foreground Light / Primary text
        property color base06: "#F0F8FA" // Foreground Lighter
        property color base07: "#FDFEFF" // Foreground Lightest
        property color base08: "#F7768E" //
        property color base09: "#FF9E64" // Foreground Lightest
        property color base0B: "#A0E6FF" // Glowing Cyan-Blue (excellent for accents)
        property color base0C: "#89DDFF" // Cyan (another great accent)
        property color base0D: "#7AA2F7" // Blue (deeper accent)
    }
}
