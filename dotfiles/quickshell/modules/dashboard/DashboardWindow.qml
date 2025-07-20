import Quickshell
import QtQuick
import Quickshell.Wayland
import "root:/config"
import "root:/services"

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
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Left:
                appChooserContainer.moveCarouselPrevious();
                event.accepted = true;
                break;
            case Qt.Key_Right:
                appChooserContainer.moveCarouselNext();
                event.accepted = true;
                break;
            default:
                break;
            }
        }
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
