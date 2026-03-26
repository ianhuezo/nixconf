//@ pragma IconTheme Tela-dark

import Quickshell
import QtQuick
import qs.services
import "modules/bar"
import "modules/dashboard"
import "modules/workspace_preview"
import "modules/screenshots"

ShellRoot {
    Bar {}
    Dashboard {}
    PreviewPopup {}
    Screenshots {}

    // Initialize ConfigManager service
    QtObject {
        Component.onCompleted: {
            // Access ConfigManager to trigger initialization
            ConfigManager.isLoaded;
        }
    }
}
