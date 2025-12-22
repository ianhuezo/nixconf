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

    // Apply the same offset that nix config uses to avoid transparent background in kitty
    // This increments the last hex character by 1
    function offsetColor(hexColor) {
        const hexSuccessor = {
            "0": "1", "1": "2", "2": "3", "3": "4", "4": "5",
            "5": "6", "6": "7", "7": "8", "8": "9", "9": "a",
            "a": "b", "b": "c", "c": "d", "d": "e", "e": "f", "f": "0"
        };

        let hex = hexColor.toLowerCase();
        if (hex.startsWith('#')) {
            hex = hex.substring(1);
        }

        let lastChar = hex[hex.length - 1];
        let newLastChar = hexSuccessor[lastChar] || lastChar;
        let newHex = hex.substring(0, hex.length - 1) + newLastChar;

        return "#" + newHex;
    }

    // Get offset color from palette (same offset as nix config applies)
    function getOffsetColor(color) {
        return offsetColor(colorToHex(color));
    }

    // Watch /run/user directory for new nvim sockets using inotify
    Process {
        id: serverWatcher
        command: ["sh", "-c", "inotifywait -m -e create -e moved_to /run/user/$UID 2>/dev/null | grep --line-buffered 'nvim\\.'"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                // inotifywait output: /run/user/1000/ CREATE nvim.12345.0
                // Extract if it's a nvim socket (ends with .0)
                let match = data.match(/nvim\.\d+\.0/);
                if (match) {
                    // Get UID from the inotify output path
                    let pathMatch = data.match(/\/run\/user\/(\d+)\//);
                    let uid = pathMatch ? pathMatch[1] : "1000";
                    let socketPath = "/run/user/" + uid + "/" + match[0];
                    console.log("New Neovim instance detected:", socketPath);

                    // Add to our list
                    if (!root.nvimServers.includes(socketPath)) {
                        root.nvimServers.push(socketPath);
                    }

                    // Apply colors to the new instance
                    let luaCmd = buildLuaCommand();
                    updateNvimInstance(socketPath, luaCmd);
                }
            }
        }
    }

    // Helper function to build the lua command for RPC updates
    function buildLuaCommand() {
        // Note: RPC updates are now redundant since we use file watching,
        // but keeping this for new instances before the file is watched
        return `lua << EOF
require('base16-colorscheme').setup({
    base00 = "${getOffsetColor(Color.palette.base00)}",
    base01 = "${getOffsetColor(Color.palette.base01)}",
    base02 = "${getOffsetColor(Color.palette.base02)}",
    base03 = "${getOffsetColor(Color.palette.base03)}",
    base04 = "${getOffsetColor(Color.palette.base04)}",
    base05 = "${getOffsetColor(Color.palette.base05)}",
    base06 = "${getOffsetColor(Color.palette.base06)}",
    base07 = "${getOffsetColor(Color.palette.base07)}",
    base08 = "${getOffsetColor(Color.palette.base08)}",
    base09 = "${getOffsetColor(Color.palette.base09)}",
    base0A = "${getOffsetColor(Color.palette.base0A)}",
    base0B = "${getOffsetColor(Color.palette.base0B)}",
    base0C = "${getOffsetColor(Color.palette.base0C)}",
    base0D = "${getOffsetColor(Color.palette.base0D)}",
    base0E = "${getOffsetColor(Color.palette.base0E)}",
    base0F = "${getOffsetColor(Color.palette.base0F)}",
})
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "${getOffsetColor(Color.palette.base09)}", bold = true })
vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "TelescopePromptNormal", { bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base0B)}", bold = true })
vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { fg = "${getOffsetColor(Color.palette.base0D)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "TelescopeResultsBorder", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base0C)}", bold = true })
vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { fg = "${getOffsetColor(Color.palette.base0E)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base0E)}", bold = true })
vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = "${getOffsetColor(Color.palette.base05)}", bg = "${getOffsetColor(Color.palette.base02)}", bold = true })
vim.api.nvim_set_hl(0, "TelescopeSelectionCaret", { fg = "${getOffsetColor(Color.palette.base0D)}", bg = "${getOffsetColor(Color.palette.base02)}" })
vim.api.nvim_set_hl(0, "TelescopeMatching", { fg = "${getOffsetColor(Color.palette.base0B)}", bold = true })
vim.api.nvim_set_hl(0, "TelescopePromptCounter", { fg = "${getOffsetColor(Color.palette.base04)}" })
vim.api.nvim_set_hl(0, "@function", { fg = "${getOffsetColor(Color.palette.base0D)}", bold = true })
vim.api.nvim_set_hl(0, "@method", { fg = "${getOffsetColor(Color.palette.base0D)}", italic = true })
vim.api.nvim_set_hl(0, "@variable", { fg = "${getOffsetColor(Color.palette.base0C)}" })
vim.api.nvim_set_hl(0, "@property", { fg = "${getOffsetColor(Color.palette.base0E)}" })
vim.api.nvim_set_hl(0, "BufferLineFill", { bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineBackground", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineBuffer", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { fg = "${getOffsetColor(Color.palette.base05)}", bg = "${getOffsetColor(Color.palette.base00)}", bold = true, italic = false })
vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineTab", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineTabSelected", { fg = "${getOffsetColor(Color.palette.base0D)}", bg = "${getOffsetColor(Color.palette.base00)}", bold = true })
vim.api.nvim_set_hl(0, "BufferLineTabSeparator", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineTabSeparatorSelected", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineSeparator", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineSeparatorSelected", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineSeparatorVisible", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineIndicatorSelected", { fg = "${getOffsetColor(Color.palette.base0D)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineIndicatorVisible", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineModified", { fg = "${getOffsetColor(Color.palette.base09)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineModifiedSelected", { fg = "${getOffsetColor(Color.palette.base09)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineModifiedVisible", { fg = "${getOffsetColor(Color.palette.base09)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineCloseButton", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineCloseButtonSelected", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineCloseButtonVisible", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineNumbers", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineNumbersSelected", { fg = "${getOffsetColor(Color.palette.base0D)}", bg = "${getOffsetColor(Color.palette.base00)}", bold = true })
vim.api.nvim_set_hl(0, "BufferLineNumbersVisible", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineDiagnostic", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineDiagnosticSelected", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineDiagnosticVisible", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineError", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineErrorSelected", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineErrorVisible", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineErrorDiagnostic", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineErrorDiagnosticSelected", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineErrorDiagnosticVisible", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineWarning", { fg = "${getOffsetColor(Color.palette.base0A)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineWarningSelected", { fg = "${getOffsetColor(Color.palette.base0A)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineWarningVisible", { fg = "${getOffsetColor(Color.palette.base0A)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineWarningDiagnostic", { fg = "${getOffsetColor(Color.palette.base0A)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineWarningDiagnosticSelected", { fg = "${getOffsetColor(Color.palette.base0A)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineWarningDiagnosticVisible", { fg = "${getOffsetColor(Color.palette.base0A)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineInfo", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineInfoSelected", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineInfoVisible", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineInfoDiagnostic", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineInfoDiagnosticSelected", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineInfoDiagnosticVisible", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineHint", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineHintSelected", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineHintVisible", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineHintDiagnostic", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineHintDiagnosticSelected", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineHintDiagnosticVisible", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineDuplicate", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}", italic = true })
vim.api.nvim_set_hl(0, "BufferLineDuplicateSelected", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base00)}", italic = true })
vim.api.nvim_set_hl(0, "BufferLineDuplicateVisible", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}", italic = true })
vim.api.nvim_set_hl(0, "BufferLinePick", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base01)}", bold = true })
vim.api.nvim_set_hl(0, "BufferLinePickSelected", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base00)}", bold = true })
vim.api.nvim_set_hl(0, "BufferLinePickVisible", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base01)}", bold = true })
if pcall(require, 'lualine') then require('lualine').setup() end
EOF
`;
    }

    // Write colors.lua file to ~/.config/nvim/colors.lua
    function writeColorsFile() {
        let luaContent = `-- Auto-generated by QuickShell - DO NOT EDIT MANUALLY
-- This file is watched by Neovim and reloaded automatically

require('base16-colorscheme').setup({
    base00 = "${getOffsetColor(Color.palette.base00)}",
    base01 = "${getOffsetColor(Color.palette.base01)}",
    base02 = "${getOffsetColor(Color.palette.base02)}",
    base03 = "${getOffsetColor(Color.palette.base03)}",
    base04 = "${getOffsetColor(Color.palette.base04)}",
    base05 = "${getOffsetColor(Color.palette.base05)}",
    base06 = "${getOffsetColor(Color.palette.base06)}",
    base07 = "${getOffsetColor(Color.palette.base07)}",
    base08 = "${getOffsetColor(Color.palette.base08)}",
    base09 = "${getOffsetColor(Color.palette.base09)}",
    base0A = "${getOffsetColor(Color.palette.base0A)}",
    base0B = "${getOffsetColor(Color.palette.base0B)}",
    base0C = "${getOffsetColor(Color.palette.base0C)}",
    base0D = "${getOffsetColor(Color.palette.base0D)}",
    base0E = "${getOffsetColor(Color.palette.base0E)}",
    base0F = "${getOffsetColor(Color.palette.base0F)}",
})

-- Apply custom highlight groups for plugins
vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "${getOffsetColor(Color.palette.base09)}", bold = true })

-- Telescope highlights
vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "TelescopePromptNormal", { bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base0B)}", bold = true })
vim.api.nvim_set_hl(0, "TelescopePromptPrefix", { fg = "${getOffsetColor(Color.palette.base0D)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "TelescopeResultsBorder", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base0C)}", bold = true })
vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { fg = "${getOffsetColor(Color.palette.base0E)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base0E)}", bold = true })
vim.api.nvim_set_hl(0, "TelescopeSelection", { fg = "${getOffsetColor(Color.palette.base05)}", bg = "${getOffsetColor(Color.palette.base02)}", bold = true })
vim.api.nvim_set_hl(0, "TelescopeSelectionCaret", { fg = "${getOffsetColor(Color.palette.base0D)}", bg = "${getOffsetColor(Color.palette.base02)}" })
vim.api.nvim_set_hl(0, "TelescopeMatching", { fg = "${getOffsetColor(Color.palette.base0B)}", bold = true })
vim.api.nvim_set_hl(0, "TelescopePromptCounter", { fg = "${getOffsetColor(Color.palette.base04)}" })

-- Treesitter highlights
vim.api.nvim_set_hl(0, "@function", { fg = "${getOffsetColor(Color.palette.base0D)}", bold = true })
vim.api.nvim_set_hl(0, "@method", { fg = "${getOffsetColor(Color.palette.base0D)}", italic = true })
vim.api.nvim_set_hl(0, "@variable", { fg = "${getOffsetColor(Color.palette.base0C)}" })
vim.api.nvim_set_hl(0, "@property", { fg = "${getOffsetColor(Color.palette.base0E)}" })

-- Bufferline highlights (top tabs)
vim.api.nvim_set_hl(0, "BufferLineFill", { bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineBackground", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineBuffer", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineBufferSelected", { fg = "${getOffsetColor(Color.palette.base05)}", bg = "${getOffsetColor(Color.palette.base00)}", bold = true, italic = false })
vim.api.nvim_set_hl(0, "BufferLineBufferVisible", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base01)}" })

-- Tab highlights
vim.api.nvim_set_hl(0, "BufferLineTab", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineTabSelected", { fg = "${getOffsetColor(Color.palette.base0D)}", bg = "${getOffsetColor(Color.palette.base00)}", bold = true })
vim.api.nvim_set_hl(0, "BufferLineTabSeparator", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineTabSeparatorSelected", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base00)}" })

-- Separator highlights
vim.api.nvim_set_hl(0, "BufferLineSeparator", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineSeparatorSelected", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineSeparatorVisible", { fg = "${getOffsetColor(Color.palette.base00)}", bg = "${getOffsetColor(Color.palette.base01)}" })

-- Indicator highlights
vim.api.nvim_set_hl(0, "BufferLineIndicatorSelected", { fg = "${getOffsetColor(Color.palette.base0D)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineIndicatorVisible", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}" })

-- Modified buffer highlights
vim.api.nvim_set_hl(0, "BufferLineModified", { fg = "${getOffsetColor(Color.palette.base09)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineModifiedSelected", { fg = "${getOffsetColor(Color.palette.base09)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineModifiedVisible", { fg = "${getOffsetColor(Color.palette.base09)}", bg = "${getOffsetColor(Color.palette.base01)}" })

-- Close button highlights (fixes gray bars on close icons)
vim.api.nvim_set_hl(0, "BufferLineCloseButton", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineCloseButtonSelected", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineCloseButtonVisible", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}" })

-- Numbers highlights
vim.api.nvim_set_hl(0, "BufferLineNumbers", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineNumbersSelected", { fg = "${getOffsetColor(Color.palette.base0D)}", bg = "${getOffsetColor(Color.palette.base00)}", bold = true })
vim.api.nvim_set_hl(0, "BufferLineNumbersVisible", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base01)}" })

-- Diagnostic highlights (fixes gray bars on diagnostic icons)
vim.api.nvim_set_hl(0, "BufferLineDiagnostic", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineDiagnosticSelected", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineDiagnosticVisible", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}" })

-- Error diagnostic highlights
vim.api.nvim_set_hl(0, "BufferLineError", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineErrorSelected", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineErrorVisible", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineErrorDiagnostic", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineErrorDiagnosticSelected", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineErrorDiagnosticVisible", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base01)}" })

-- Warning diagnostic highlights
vim.api.nvim_set_hl(0, "BufferLineWarning", { fg = "${getOffsetColor(Color.palette.base0A)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineWarningSelected", { fg = "${getOffsetColor(Color.palette.base0A)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineWarningVisible", { fg = "${getOffsetColor(Color.palette.base0A)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineWarningDiagnostic", { fg = "${getOffsetColor(Color.palette.base0A)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineWarningDiagnosticSelected", { fg = "${getOffsetColor(Color.palette.base0A)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineWarningDiagnosticVisible", { fg = "${getOffsetColor(Color.palette.base0A)}", bg = "${getOffsetColor(Color.palette.base01)}" })

-- Info diagnostic highlights
vim.api.nvim_set_hl(0, "BufferLineInfo", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineInfoSelected", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineInfoVisible", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineInfoDiagnostic", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineInfoDiagnosticSelected", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineInfoDiagnosticVisible", { fg = "${getOffsetColor(Color.palette.base0C)}", bg = "${getOffsetColor(Color.palette.base01)}" })

-- Hint diagnostic highlights
vim.api.nvim_set_hl(0, "BufferLineHint", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineHintSelected", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineHintVisible", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineHintDiagnostic", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base01)}" })
vim.api.nvim_set_hl(0, "BufferLineHintDiagnosticSelected", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base00)}" })
vim.api.nvim_set_hl(0, "BufferLineHintDiagnosticVisible", { fg = "${getOffsetColor(Color.palette.base0B)}", bg = "${getOffsetColor(Color.palette.base01)}" })

-- Duplicate buffer highlights
vim.api.nvim_set_hl(0, "BufferLineDuplicate", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}", italic = true })
vim.api.nvim_set_hl(0, "BufferLineDuplicateSelected", { fg = "${getOffsetColor(Color.palette.base04)}", bg = "${getOffsetColor(Color.palette.base00)}", italic = true })
vim.api.nvim_set_hl(0, "BufferLineDuplicateVisible", { fg = "${getOffsetColor(Color.palette.base03)}", bg = "${getOffsetColor(Color.palette.base01)}", italic = true })

-- Pick mode highlights
vim.api.nvim_set_hl(0, "BufferLinePick", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base01)}", bold = true })
vim.api.nvim_set_hl(0, "BufferLinePickSelected", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base00)}", bold = true })
vim.api.nvim_set_hl(0, "BufferLinePickVisible", { fg = "${getOffsetColor(Color.palette.base08)}", bg = "${getOffsetColor(Color.palette.base01)}", bold = true })

-- Lualine will automatically use base16 colors, but we can ensure it refreshes
if pcall(require, 'lualine') then
    require('lualine').setup()
end
`;

        // Write to ~/.config/nvim/colors.lua using a shell command
        let cmd = ["sh", "-c", "mkdir -p ~/.config/nvim && cat > ~/.config/nvim/colors.lua << 'LUAEOF'\n" + luaContent + "\nLUAEOF"];

        let processQml = `
            import Quickshell
            import Quickshell.Io
            Process {
                command: ${JSON.stringify(cmd)}
                running: true

                onExited: (code, status) => {
                    if (code === 0) {
                        console.log("Successfully wrote colors.lua");
                    } else {
                        console.error("Failed to write colors.lua, exit code:", code);
                    }
                    destroy();
                }

                stderr: SplitParser {
                    onRead: data => {
                        console.error("Error writing colors.lua:", data);
                    }
                }
            }
        `;

        Qt.createQmlObject(processQml, root, "writeColorsFile");
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
        command: ["sh", "-c", "find /run/user/$UID -name 'nvim.*.0' 2>/dev/null"]
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
        console.log("Neovim.updateColors() called");
        if (!Color.palette) {
            console.warn("Color palette not available for Neovim");
            return;
        }

        if (updatingColors || findingServers) {
            console.log("Skipping update - updatingColors:", updatingColors, "findingServers:", findingServers);
            return;
        }

        console.log("Writing colors file and finding servers...");
        // Write colors.lua file for auto-reload via BufWritePost autocmd
        writeColorsFile();

        // Always refresh the server list to catch new instances
        findNvimServers();
    }

    function updateColorsForServers() {
        if (nvimServers.length === 0) {
            // No servers found, nothing to update
            updatingColors = false;
            console.log("No neovim servers found");
            return;
        }

        updatingColors = true;
        console.log("Updating colors for", nvimServers.length, "neovim instance(s)");

        // Build the lua command using helper function
        let luaCmd = buildLuaCommand();

        // Update each nvim instance
        for (let i = 0; i < nvimServers.length; i++) {
            updateNvimInstance(nvimServers[i], luaCmd);
        }

        // Reset the flag after all updates are queued
        updatingColors = false;
    }

    function updateNvimInstance(serverPath, luaCmd) {
        // Instead of sending complex multi-line Lua via RPC, just tell nvim to source the colors file
        // This is more reliable and works better across workspaces
        let cmd = `nvim --server "${serverPath}" --remote-expr "execute('source ~/.config/nvim/colors.lua')"`;

        let processQml = `
            import Quickshell
            import Quickshell.Io
            Process {
                property string serverPath: "${serverPath}"
                command: ["sh", "-c", ${JSON.stringify(cmd)}]
                running: true

                onExited: (code, status) => {
                    if (code === 0) {
                        console.log("Successfully updated neovim colors for:", serverPath);
                    } else {
                        console.error("Failed to update neovim colors for:", serverPath, "exit code:", code);
                    }
                    destroy();
                }

                stderr: SplitParser {
                    onRead: data => {
                        console.error("Neovim RPC error for", serverPath, ":", data);
                    }
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
