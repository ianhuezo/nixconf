pragma Singleton
import Quickshell
import QtQuick
import qs.services

Singleton {
    id: root

    property QtObject radius: QtObject {
        readonly property real none: 0
        property real sm: 4  // Default fallback
        property real md: 12  // Default fallback
        property real lg: 20  // Default fallback
    }

    property var calculateRadius: function (width, height, radiusType) {
        var minDimension = Math.min(width, height);
        switch (radiusType.toLowerCase()) {
        case "none":
            return 0;
        case "sm":
            return Math.min(4, minDimension * 0.02);
        case "md":
            return Math.min(8, minDimension * 0.04);
        case "lg":
            return Math.min(12, minDimension * 0.06);
        case "xl":
            return Math.min(16, minDimension * 0.08);
        case "round":
            return minDimension / 2;
        default:
            console.warn("Unknown radius type:", radiusType, "- defaulting to 'none'");
            return 0;
        }
    }

    property QtObject font: QtObject {
        // Font families - defaults as fallback
        property string mono: "JetBrains Mono Nerd Font"
        property string ui: "Inter"
        property string display: "Inter"

        // Legacy support
        readonly property string family: mono

        // Font sizes - defaults as fallback
        property QtObject size: QtObject {
            property real xs: 11
            property real sm: 14
            property real md: 16
            property real lg: 20
            property real xl: 24
            property real xxl: 32
        }

        // Font weights - defaults as fallback
        property QtObject weight: QtObject {
            property int light: 300
            property int regular: 400
            property int medium: 500
            property int semibold: 600
            property int bold: 700
        }
    }

    // Update from ConfigManager when config changes
    Component.onCompleted: {
        updateFromConfig();
    }

    Connections {
        target: ConfigManager
        function onAppearanceUpdated() {
            root.updateFromConfig();
        }
    }

    function updateFromConfig() {
        // Update radius
        radius.sm = ConfigManager.appearance.radius.sm;
        radius.md = ConfigManager.appearance.radius.md;
        radius.lg = ConfigManager.appearance.radius.lg;

        // Update fonts
        font.mono = ConfigManager.appearance.font.mono;
        font.ui = ConfigManager.appearance.font.ui;
        font.display = ConfigManager.appearance.font.display;

        // Update font sizes
        font.size.xs = ConfigManager.appearance.font.size.xs;
        font.size.sm = ConfigManager.appearance.font.size.sm;
        font.size.md = ConfigManager.appearance.font.size.md;
        font.size.lg = ConfigManager.appearance.font.size.lg;
        font.size.xl = ConfigManager.appearance.font.size.xl;
        font.size.xxl = ConfigManager.appearance.font.size.xxl;

        // Update font weights
        font.weight.light = ConfigManager.appearance.font.weight.light;
        font.weight.regular = ConfigManager.appearance.font.weight.regular;
        font.weight.medium = ConfigManager.appearance.font.weight.medium;
        font.weight.semibold = ConfigManager.appearance.font.weight.semibold;
        font.weight.bold = ConfigManager.appearance.font.weight.bold;
    }
    readonly property QtObject transitions: QtObject {
        //from soramame ;)
        readonly property list<real> emphasized: [0.05, 0, 2 / 15, 0.06, 1 / 6, 0.4, 5 / 24, 0.82, 0.25, 1, 1, 1]
        readonly property list<real> emphasizedAccel: [0.3, 0, 0.8, 0.15, 1, 1]
        readonly property list<real> emphasizedDecel: [0.05, 0.7, 0.1, 1, 1, 1]
        readonly property list<real> standard: [0.2, 0, 0, 1, 1, 1]
        readonly property list<real> standardAccel: [0.3, 0, 1, 1, 1, 1]
        readonly property list<real> standardDecel: [0, 0, 0, 1, 1, 1]
        readonly property list<real> expressiveFastSpatial: [0.42, 1.67, 0.21, 0.9, 1, 1]
        readonly property list<real> expressiveDefaultSpatial: [0.38, 1.21, 0.22, 1, 1, 1]
        readonly property list<real> expressiveEffects: [0.34, 0.8, 0.34, 1, 1, 1]
    }
}
