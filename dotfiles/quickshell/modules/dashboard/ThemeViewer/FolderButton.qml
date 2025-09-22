import qs.components
import QtQuick

IconButton {
    id: root
    iconText: '🗀'

    signal opened(bool isOpen)
    signal pathAdded(string path)

    onClicked: {
        if (!fileExplorer.running) {
            root.opened(true);
            fileExplorer.running = true;
        }
    }

    ThunarOpener {
        id: fileExplorer
        onClosed: path => {
            console.debug(`Got path ${path}`);
            root.opened(false);
            root.pathAdded(path);
            fileExplorer.running = false;
        }
        onError: error => {
            console.debug(`${error}`);
            root.opened(false);
            fileExplorer.running = false;
        }
    }
}
