pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var kittySockets: []
    property bool findingSocketsInProgress: false

    // Helper function to get hex string from QML color (returns format like "#rrggbb")
    function colorToHex(color) {
        return color.toString();
    }

    // Find all kitty sockets
    function findKittySockets() {
        if (!findingSocketsInProgress) {
            findingSocketsInProgress = true;
            socketFinder.running = true;
        }
    }

    Process {
        id: socketFinder
        command: ["sh", "-c", "ls /tmp/kitty-* 2>/dev/null"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                let sockets = data.trim().split('\n').filter(s => s.length > 0);
                root.kittySockets = sockets;
                root.findingSocketsInProgress = false;
                // Now update colors
                root.updateColors();
            }
        }

        onExited: (code, status) => {
            root.findingSocketsInProgress = false;
        }
    }

    // Update kitty colors using remote control
    function updateColors() {
        if (!Color.palette) {
            console.warn("Color palette not available");
            return;
        }

        // If we don't have the sockets yet, find them first
        if (kittySockets.length === 0 && !findingSocketsInProgress) {
            findKittySockets();
            return;
        }

        // If we're currently finding sockets, wait for that to complete
        if (findingSocketsInProgress) {
            return;
        }

        // Update each kitty instance
        for (let i = 0; i < kittySockets.length; i++) {
            updateKittyInstance(kittySockets[i], i);
        }
    }

    // Update a single kitty instance
    function updateKittyInstance(socketPath, index) {
        // Build the command arguments
        let args = ["@", "--to", "unix:" + socketPath, "set-colors",
            // Foreground and background
            "foreground=" + colorToHex(Color.palette.base05), "background=" + colorToHex(Color.palette.base00),

            // Grayscale colors (color0/color8)
            "color0=" + colorToHex(Color.palette.base03), "color8=" + colorToHex(Color.palette.base03),

            // Red/Salmon (color1/color9)
            "color1=" + colorToHex(Color.palette.base08), "color9=" + colorToHex(Color.palette.base08),

            // Green (color2/color10)
            "color2=" + colorToHex(Color.palette.base0C), "color10=" + colorToHex(Color.palette.base0C),

            // Yellow-brown (color3/color11)
            "color3=" + colorToHex(Color.palette.base09), "color11=" + colorToHex(Color.palette.base09),

            // Blue (color4/color12)
            "color4=" + colorToHex(Color.palette.base0D), "color12=" + colorToHex(Color.palette.base0D),

            // Magenta (color5/color13)
            "color5=" + colorToHex(Color.palette.base0E), "color13=" + colorToHex(Color.palette.base0E),

            // Cyan (color6/color14)
            "color6=" + colorToHex(Color.palette.base0C), "color14=" + colorToHex(Color.palette.base0C),

            // White (color7/color15)
            "color7=" + colorToHex(Color.palette.base05), "color15=" + colorToHex(Color.palette.base05),

            // Cursor
            "cursor=" + colorToHex(Color.palette.base05), "cursor_text_color=" + colorToHex(Color.palette.base00),

            // Selection
            "selection_foreground=none", "selection_background=" + colorToHex(Color.palette.base03),

            // URL color
            "url_color=" + colorToHex(Color.palette.base0B),

            // Window borders
            "active_border_color=" + colorToHex(Color.palette.base0D), "inactive_border_color=" + colorToHex(Color.palette.base00), "bell_border_color=" + colorToHex(Color.palette.base09),

            // Tab bar
            "active_tab_foreground=" + colorToHex(Color.palette.base0D), "active_tab_background=" + colorToHex(Color.palette.base00), "inactive_tab_foreground=" + colorToHex(Color.palette.base04), "inactive_tab_background=" + colorToHex(Color.palette.base00), "tab_bar_background=" + colorToHex(Color.palette.base00)];

        let fullCommand = ["kitty"].concat(args);

        // Create a new process for each socket using QML string
        let processQml = `
            import Quickshell
            import Quickshell.Io
            Process {
                property string socketPath: "${socketPath}"
                command: ${JSON.stringify(fullCommand)}
                running: true

                onExited: (code, status) => {
                    if (code !== 0) {
                        console.error("Failed to update kitty colors for:", socketPath, "Exit code:", code);
                    }
                    destroy();
                }
            }
        `;

        let processComponent = Qt.createQmlObject(processQml, root, "kittyProcess_" + index);
    }

    // Initialize colors on component load
    Component.onCompleted: {
        Qt.callLater(updateColors);
    }
}
