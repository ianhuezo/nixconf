//@ pragma IconTheme Tela-dark

import Quickshell
import "modules/bar"
import "modules/dashboard"
import "modules/workspace_preview"
import "services"

ShellRoot {
    QueueManager {}
    Bar {}
    Dashboard {}
    PreviewPopup {}
}
