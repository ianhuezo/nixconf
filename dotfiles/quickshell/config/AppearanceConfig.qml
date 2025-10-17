pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property QtObject radius: QtObject {
        readonly property real none: 0
        readonly property real sm: 4
        readonly property real md: 12
        readonly property real lg: 20
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

    readonly property QtObject font: QtObject {
        // Font families
        readonly property string mono: "JetBrains Mono Nerd Font"
        readonly property string ui: "Inter" // Fallback: system default sans-serif
        readonly property string display: "Inter" // For headings, can be different
        
        // Legacy support
        readonly property string family: mono
        
        // Font sizes
        readonly property QtObject size: QtObject {
            readonly property real xs: 11
            readonly property real sm: 14
            readonly property real md: 16
            readonly property real lg: 20
            readonly property real xl: 24
            readonly property real xxl: 32
        }
        
        // Font weights
        readonly property QtObject weight: QtObject {
            readonly property int light: 300
            readonly property int regular: 400
            readonly property int medium: 500
            readonly property int semibold: 600
            readonly property int bold: 700
        }
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
