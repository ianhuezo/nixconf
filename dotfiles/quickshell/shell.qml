//@ pragma IconTheme Tela-dark

import Quickshell
import QtQuick
import qs.services
import "modules/bar"
import "modules/dashboard"
import "modules/workspace_preview"

ShellRoot {
    Bar {}
    Dashboard {}
    PreviewPopup {}

    // Initialize ConfigManager service
    QtObject {
        Component.onCompleted: {
            // Access ConfigManager to trigger initialization
            ConfigManager.isLoaded;
        }
    }
}
