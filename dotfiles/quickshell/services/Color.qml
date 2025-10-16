pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io
import "root:/libs/nix/nix.js" as NixUtil

Singleton {
    id: root

    Component.onCompleted: {
        // Try to load theme from a default location or config
        let themePath = "/etc/nixos/nix/themes/dark-ethereal/default.nix"; // or read from config
        loadTheme(themePath);
    }

    // Store original colors for fallback
    readonly property QtObject defaultPalette: QtObject {
        // Background colors (darkest to lighter)
        readonly property color base00: "#0D121B"  // UI: Main window background, panel fills | Terminal: Default background
        readonly property color base01: "#111A2C"  // UI: Slightly lighter backgrounds (sidebars, cards) | Terminal: Lighter background (for selections, not commonly used)
        readonly property color base02: "#1A263B"  // UI: Selection backgrounds, hover states, input fields | Terminal: Selection background, highlighted text background
        readonly property color base03: "#2A3E5C"  // UI: Borders, separators, disabled elements | Terminal: Comments, invisibles, line highlighting

        // Foreground colors (darker to brightest text)
        readonly property color base04: "#6C8CB7"  // UI: Secondary text, placeholder text, icons | Terminal: Dark foreground (for prompts, secondary text)
        readonly property color base05: "#E0F2F7"  // UI: Primary text, main body content | Terminal: Default foreground (main text color)
        readonly property color base06: "#F0F8FA"  // UI: Emphasized text, headings | Terminal: Light foreground (not commonly used, for emphasis)
        readonly property color base07: "#FDFEFF"  // UI: Brightest text, important highlights | Terminal: Bright/bold text variants

        // Accent colors (semantic highlighting)
        readonly property color base08: "#F7768E"  // UI: Errors, destructive actions, alerts | Terminal: Red (errors, deletions, ANSI red)
        readonly property color base09: "#FF9E64"  // UI: Warnings, secondary CTAs, notifications | Terminal: Orange (warnings, special numbers, ANSI bright red)
        readonly property color base0A: "#B7C5D3"  // UI: Information highlights, search results | Terminal: Yellow (search, classes, ANSI yellow)
        readonly property color base0B: "#A0E6FF"  // UI: Success states, confirmations, growth | Terminal: Green (success, additions, strings, ANSI green)
        readonly property color base0C: "#89DDFF"  // UI: Info badges, links, auxiliary actions | Terminal: Cyan (escape codes, regex, ANSI cyan)
        readonly property color base0D: "#7AA2F7"  // UI: Primary actions (buttons), focus states, links | Terminal: Blue (functions, keywords, ANSI blue)
        readonly property color base0E: "#BB9AF7"  // UI: Special elements, tags, tertiary CTAs | Terminal: Magenta (variables, keywords, ANSI magenta)
        readonly property color base0F: "#BB9AF7"  // UI: Deprecated warnings, misc. highlights | Terminal: Brown/deprecated (constants, special chars, ANSI bright black)
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
        property color base0A: root.defaultPalette.base0A
        property color base0B: root.defaultPalette.base0B
        property color base0C: root.defaultPalette.base0C
        property color base0D: root.defaultPalette.base0D
        property color base0E: root.defaultPalette.base0E
        property color base0F: root.defaultPalette.base0F
    }
    function convertPaletteToArray(jsonPalette) {
        var paletteArray = [];

        // Define the order of base colors (base00 to base0F)
        var baseKeys = ["base00", "base01", "base02", "base03", "base04", "base05", "base06", "base07", "base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F"];

        // Convert each palette entry
        for (var i = 0; i < baseKeys.length; i++) {
            var key = baseKeys[i];
            if (jsonPalette.hasOwnProperty(key)) {
                paletteArray.push({
                    name: key,
                    color: jsonPalette[key]
                });
            }
        }

        return paletteArray;
    }

    property var paletteData: [
        {
            name: "base00",
            color: root.palette.base00
        },
        {
            name: "base01",
            color: root.palette.base01
        },
        {
            name: "base02",
            color: root.palette.base02
        },
        {
            name: "base03",
            color: root.palette.base03
        },
        {
            name: "base04",
            color: root.palette.base04
        },
        {
            name: "base05",
            color: root.palette.base05
        },
        {
            name: "base06",
            color: root.palette.base06
        },
        {
            name: "base07",
            color: root.palette.base07
        },
        {
            name: "base08",
            color: root.palette.base08
        },
        {
            name: "base09",
            color: root.palette.base09
        },
        {
            name: "base0A",
            color: root.palette.base0A
        },
        {
            name: "base0B",
            color: root.palette.base0B
        },
        {
            name: "base0C",
            color: root.palette.base0C
        },
        {
            name: "base0D",
            color: root.palette.base0D
        },
        {
            name: "base0E",
            color: root.palette.base0E
        },
        {
            name: "base0F",
            color: root.palette.base0F
        }
    ]

    FileView {
        id: themeFile
        blockLoading: true
    }

    function loadTheme(path: string): bool {
        try {
            // Set the path and read the file
            themeFile.path = Qt.resolvedUrl(path);
            let fileContent = themeFile.text();

            if (!fileContent) {
                console.warn("Failed to load theme file:", path);
                resetToDefault();
                return false;
            }

            // Parse JSON
            let themeData = NixUtil.nixToJson(fileContent);

            // Validate that it's a proper theme object
            if (!themeData.palette) {
                console.warn("Invalid theme format: missing 'palette' object");
                resetToDefault();
                return false;
            }

            // Apply colors using EXPLICIT keys instead of Object.keys()
            let newPalette = themeData.palette;
            let baseKeys = ["base00", "base01", "base02", "base03", "base04", "base05", "base06", "base07", "base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F"];

            for (let i = 0; i < baseKeys.length; i++) {
                let key = baseKeys[i];
                if (newPalette.hasOwnProperty(key)) {
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
    function getBorderColor(backgroundColor) {
        // Convert color to RGB values (0-1 range)
        var r = backgroundColor.r;
        var g = backgroundColor.g;
        var b = backgroundColor.b;

        // Calculate relative luminance using sRGB formula
        function srgbToLinear(c) {
            return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
        }

        var rLinear = srgbToLinear(r);
        var gLinear = srgbToLinear(g);
        var bLinear = srgbToLinear(b);

        var luminance = 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;

        // If base00 (background) is dark, use light border for dark colors
        // If base00 is light, use dark border for light colors
        var base00Luminance = getLuminance(Color.paletteData[0].color); // Assuming base00 is first
        var isBase00Dark = base00Luminance < 0.5;

        if (isBase00Dark) {
            // Dark theme - use light border for very dark colors
            return luminance < 0.1 ? "#666666" : "transparent";
        } else {
            // Light theme - use dark border for very light colors
            return luminance > 0.9 ? "#999999" : "transparent";
        }
    }

    function getLuminance(color) {
        var r = color.r;
        var g = color.g;
        var b = color.b;

        function srgbToLinear(c) {
            return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
        }

        var rLinear = srgbToLinear(r);
        var gLinear = srgbToLinear(g);
        var bLinear = srgbToLinear(b);

        return 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
    }

    function resetToDefault(): void {
        let baseKeys = ["base00", "base01", "base02", "base03", "base04", "base05", "base06", "base07", "base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E", "base0F"];

        for (let i = 0; i < baseKeys.length; i++) {
            let key = baseKeys[i];
            palette[key] = defaultPalette[key];
        }
        console.log("Theme reset to default");
    }
}
