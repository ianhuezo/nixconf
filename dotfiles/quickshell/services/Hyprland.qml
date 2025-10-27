pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool updatingColors: false

    // Helper function to get hex string from QML color (returns format like "#rrggbb")
    function colorToHex(color) {
        return color.toString();
    }

    // Helper function to strip # from hex color
    function stripHash(hexColor) {
        return hexColor.replace("#", "");
    }

    // Update hyprland border colors using hyprctl
    function updateColors() {
        if (!Color.palette) {
            console.warn("Color palette not available for Hyprland");
            return;
        }

        if (updatingColors) {
            return;
        }

        updatingColors = true;

        // Build hyprctl commands for border colors
        let activeBorder1 = stripHash(colorToHex(Color.palette.base0C)) + "ee"; // Cyan with alpha
        let activeBorder2 = stripHash(colorToHex(Color.palette.base01)) + "ee"; // Dark bg with alpha
        let inactiveBorder = stripHash(colorToHex(Color.palette.base03)) + "aa"; // Darker with alpha

        hyprctlUpdater.command = ["sh", "-c",
            `hyprctl keyword general:col.active_border "rgba(${activeBorder1}) rgba(${activeBorder2}) 45deg" && ` +
            `hyprctl keyword general:col.inactive_border "rgba(${inactiveBorder})"`
        ];
        hyprctlUpdater.running = true;
    }

    Process {
        id: hyprctlUpdater
        running: false

        onExited: (code, status) => {
            if (code !== 0) {
                console.error("Failed to update hyprland colors. Exit code:", code);
            }
            root.updatingColors = false;
        }
    }

    // Initialize colors on component load
    Component.onCompleted: {
        Qt.callLater(updateColors);
    }
}
