import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import "root:/config"
import "root:/services"
import QtQuick.Effects

PanelWindow {
    id: root
    property var modelData
    required property var parentId
    property var windowProperty
    color: 'transparent'
    implicitWidth: parentId.implicitWidth
    implicitHeight: parentId.implicitHeight

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: 0

    onVisibleChanged: {
        if (root.visible) {
            contentItem.forceActiveFocus();
        }
    }

    signal closeRequested

    Item {
        id: contentItem
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closeRequested()
        Rectangle {
            id: mainDrawArea
            anchors.fill: parent
            color: Color.palette.base00
            radius: 20

	    SplashPanel {
	      id: splashPanel
	    }
            AppChooser {
                id: appChooserContainer
            }

            Rectangle {
                id: mainApplication
                color: 'transparent'
                height: parent.height - appChooserContainer.height
                width: parent.width - splashPanel.width
                y: parent.y + appChooserContainer.height
                bottomLeftRadius: mainDrawArea.radius
                AppViewer {
                    id: mainAppViewer
                    onAppSelected: {
                        root.closeRequested();
                    }
                }
            }
        }
    }
}
