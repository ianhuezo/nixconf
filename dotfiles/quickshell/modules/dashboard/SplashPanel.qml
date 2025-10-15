import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.config
import qs.services
import QtQuick.Effects

ClippingRectangle {
    id: rightSplashPanel
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.rightMargin: mainDrawArea.border.width
    anchors.topMargin: mainDrawArea.border.width
    anchors.bottomMargin: mainDrawArea.border.width
    width: parent.width * 0.2
    color: 'transparent'

    topRightRadius: mainDrawArea.radius
    bottomRightRadius: mainDrawArea.radius
    topLeftRadius: 0
    bottomLeftRadius: 0

    Image {
        id: splashArt
        source: FileConfig.splashArtPath
        fillMode: Image.PreserveAspectCrop
        anchors.fill: parent
        antialiasing: true
        smooth: true
    }
}
