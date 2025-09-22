import qs.components
import QtQuick

IconButton {
    id: root
    iconText: '✨️'

    property string wallpaperPath: ""

    signal opened(bool isOpen)
    signal colorsGenerated(var json)

    onClicked: {
        if (wallpaperPath.length == 0) {
            console.error("A path must be provided to generate a wallpaper color configuration");
            return;
        }
        if (!coloreGenerator.running) {
            root.opened(true);
            coloreGenerator.running = true;
        }
    }

    GeminiColorGenerator {
        id: coloreGenerator
        onClosed: jsonColors => {
            console.debug(`Got colors ${jsonColors}`);
            root.opened(false);
            root.colorsGenerated(jsonColors);
            coloreGenerator.running = false;
        }
        onError: error => {
            console.debug(`${error}`);
            root.opened(false);
            coloreGenerator.running = false;
        }
    }
}
