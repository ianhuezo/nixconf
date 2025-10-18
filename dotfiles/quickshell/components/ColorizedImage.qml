import QtQuick
import QtQuick.Effects

Image {
    id: root

    property color iconColor: "white"
    property real colorization: 1.0
    property real brightness: 0.0
    property bool enableShadow: false
    property color shadowColor: "black"
    property real shadowBlur: 0.4
    property real shadowOpacity: 0.6
    property int shadowVerticalOffset: 0
    property int shadowHorizontalOffset: 0

    fillMode: Image.PreserveAspectFit
    layer.enabled: true
    layer.effect: MultiEffect {
        colorization: root.colorization
        colorizationColor: root.iconColor
        brightness: root.brightness
        shadowEnabled: root.enableShadow
        shadowColor: root.shadowColor
        shadowBlur: root.shadowBlur
        shadowOpacity: root.shadowOpacity
        shadowVerticalOffset: root.shadowVerticalOffset
        shadowHorizontalOffset: root.shadowHorizontalOffset
    }
}
