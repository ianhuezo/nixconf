pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var nvimServers: []
    property bool findingServers: false
    property bool updatingColors: false

    // Helper function to get hex string from QML color (returns format like "#rrggbb")
    function colorToHex(color) {
        return color.toString();
    }

    // Find all running nvim instances
    function findNvimServers() {
        if (!findingServers) {
            findingServers = true;
            serverFinder.running = true;
        }
    }

    Process {
        id: serverFinder
        command: ["sh", "-c", "find /tmp -name 'nvim.*.0' 2>/dev/null"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                let servers = data.trim().split('\n').filter(s => s.length > 0);
                root.nvimServers = servers;
                root.findingServers = false;
                // Now update colors
                root.updateColorsForServers();
            }
        }

        onExited: (code, status) => {
            root.findingServers = false;
        }
    }

    // Update neovim colors using RPC
    function updateColors() {
        if (!Color.palette) {
            console.warn("Color palette not available for Neovim");
            return;
        }

        if (updatingColors || findingServers) {
            return;
        }

        // Find nvim servers first
        if (nvimServers.length === 0) {
            findNvimServers();
            return;
        }

        updateColorsForServers();
    }

    function updateColorsForServers() {
        if (nvimServers.length === 0) {
            // No servers found, nothing to update
            updatingColors = false;
            return;
        }

        updatingColors = true;

        // Build the lua command to update base16 colors
        let luaCmd = `lua << EOF
local base16 = require("base16-colorscheme")
base16.setup({
    base00 = "${colorToHex(Color.palette.base00)}",
    base01 = "${colorToHex(Color.palette.base01)}",
    base02 = "${colorToHex(Color.palette.base02)}",
    base03 = "${colorToHex(Color.palette.base03)}",
    base04 = "${colorToHex(Color.palette.base04)}",
    base05 = "${colorToHex(Color.palette.base05)}",
    base06 = "${colorToHex(Color.palette.base06)}",
    base07 = "${colorToHex(Color.palette.base07)}",
    base08 = "${colorToHex(Color.palette.base08)}",
    base09 = "${colorToHex(Color.palette.base09)}",
    base0A = "${colorToHex(Color.palette.base0A)}",
    base0B = "${colorToHex(Color.palette.base0B)}",
    base0C = "${colorToHex(Color.palette.base0C)}",
    base0D = "${colorToHex(Color.palette.base0D)}",
    base0E = "${colorToHex(Color.palette.base0E)}",
    base0F = "${colorToHex(Color.palette.base0F)}",
})
EOF
`;

        // Update each nvim instance
        for (let i = 0; i < nvimServers.length; i++) {
            updateNvimInstance(nvimServers[i], luaCmd);
        }
    }

    function updateNvimInstance(serverPath, luaCmd) {
        // Create a command to send to this nvim instance
        let cmd = `nvim --server "${serverPath}" --remote-send '<Esc>:${luaCmd.replace(/\n/g, '<CR>:')}<CR>'`;

        let processQml = `
            import Quickshell
            import Quickshell.Io
            Process {
                property string serverPath: "${serverPath}"
                command: ["sh", "-c", ${JSON.stringify(cmd)}]
                running: true

                onExited: (code, status) => {
                    if (code !== 0) {
                        console.error("Failed to update neovim colors for:", serverPath);
                    }
                    destroy();
                }
            }
        `;

        Qt.createQmlObject(processQml, root, "nvimProcess_" + serverPath.replace(/\//g, "_"));
    }

    // Initialize colors on component load
    Component.onCompleted: {
        Qt.callLater(updateColors);
    }
}
