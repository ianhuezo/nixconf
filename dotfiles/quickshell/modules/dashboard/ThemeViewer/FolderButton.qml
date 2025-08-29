import qs.components
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

IconButton {
    id: root
    iconText: '🗀'

    signal opened(bool isOpen)

    onClicked: {
        if (!fileExplorer.running) {
            root.opened(true);
            fileExplorer.running = true;
        }
    }

    ThunarOpener {
        id: fileExplorer
        onClosed: path => {
            console.log(`Got path ${path}`);
            root.opened(false);
            fileExplorer.running = false;
        }
        onError: error => {
            console.log(`${error}`);
            root.opened(false);
            fileExplorer.running = false;
        }
    }
}
