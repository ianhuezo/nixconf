import Quickshell
import QtQuick

Singleton {

    readonly property QtObject radius: QtObject {
        readonly property real none: 0
        readonly property real sm: 4
        readonly property real md: 12
        readonly property real lg: 20
    }
    readonly property QtObject font: QtObject {
        readonly property string family: "JetBrains Mono Nerd Font"
        readonly property QtObject size: QtObject {
            readonly property real sm: 16
            readonly property real md: 20
            readonly property real lg: 24
            readonly property real xl: 32
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
