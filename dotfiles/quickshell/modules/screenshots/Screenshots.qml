import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Wayland

Item {
    id: screenshotsRoot
    property bool active: false

    IpcHandler {
        target: "screenshots"

        function toggleScreenshots() {
            screenshotsRoot.active = !screenshotsRoot.active;
        }
    }

    Variants {
        model: Quickshell.screens.filter(s => s.name === "HDMI-A-1")

        delegate: ScreenshotsWindow {
            screen: modelData
            isActive: screenshotsRoot.active
            onCloseRequested: screenshotsRoot.active = false
        }
    }
}
