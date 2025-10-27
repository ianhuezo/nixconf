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

    // Update mako colors by rewriting config and reloading
    function updateColors() {
        if (!Color.palette) {
            console.warn("Color palette not available for Mako");
            return;
        }

        if (updatingColors) {
            return;
        }

        updatingColors = true;

        // Build the mako config with current colors
        let bgColor = colorToHex(Color.palette.base00) + "80"; // Add alpha
        let textColor = colorToHex(Color.palette.base05);
        let borderColor = colorToHex(Color.palette.base0D);

        let makoConfig = `default-timeout=10000
font=JetBrains Mono Nerd Font
background-color=${bgColor}
border-radius=20
padding=10,5,10,5
border-color=${colorToHex(Color.palette.base0C)}
border-size=2
text-color=${textColor}

[urgency=low]
border-color=${colorToHex(Color.palette.base0C)}

[urgency=normal]
border-color=${colorToHex(Color.palette.base0C)}

[urgency=high]
border-color=${colorToHex(Color.palette.base08)}
`;

        // Remove symlink (if it exists) and write the config file
        configWriter.command = ["sh", "-c", `rm -f ~/.config/mako/config && cat > ~/.config/mako/config << 'EOF'
${makoConfig}
EOF
`];
        configWriter.running = true;
    }

    Process {
        id: configWriter
        running: false

        onExited: (code, status) => {
            if (code === 0) {
                // Config written, now reload mako
                makoReloader.running = true;
            } else {
                console.error("Failed to write mako config. Exit code:", code);
                root.updatingColors = false;
            }
        }
    }

    Process {
        id: makoReloader
        command: ["makoctl", "reload"]
        running: false

        onExited: (code, status) => {
            if (code !== 0) {
                console.error("Failed to reload mako. Exit code:", code);
            }
            root.updatingColors = false;
        }
    }

    // Initialize colors on component load
    Component.onCompleted: {
        Qt.callLater(updateColors);
    }
}
