import qs.components
import Quickshell.Wayland
import Quickshell.Io
import QtQuick

IconButton {
    id: root
    iconText: '🗀'

    onClicked: {
        if (!fileExplorer.running) {
            fileExplorer.running = true;
        }
    }

    ThunarOpener {
        id: fileExplorer
        onClosed: path => {
            console.log(`Got path ${path}`);
            fileExplorer.running = false;
        }
        onError: error => {
            console.log(`${error}`);
            fileExplorer.running = false;
        }
    }
}
