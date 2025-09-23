import qs.components
import QtQuick
import qs.config
import Quickshell.Io

IconButton {
    id: root
    iconText: "✨"

    property string wallpaperPath: ""
    property var apiKey: JSON.parse(jsonFile.text())['apiKey'] ?? ""

    signal colorsGenerated(var json)

    onClicked: {
        if (wallpaperPath.length == 0) {
            console.error("A path must be provided to generate a wallpaper color configuration");
            return;
        }
        if (apiKey.length == 0) {
            console.error("API Key could not be read");
        }
        if (!colorGenerator.running) {
            console.log("starting color generation");
            colorGenerator.wallpaperPath = wallpaperPath;
            colorGenerator.geminiAPIKey = apiKey;
            colorGenerator.running = true;
        }
    }

    onWallpaperPathChanged: data => {
        console.log(`Wallpaper path changed to ${wallpaperPath}`);
    }
    FileView {
        id: jsonFile
        path: FileConfig.environment.geminiAPIKeyPath
        blockLoading: true
    }

    GeminiColorGenerator {
        id: colorGenerator
        onClosed: jsonColors => {
            root.colorsGenerated(jsonColors);
            colorGenerator.running = false;
        }
        wallpaperPath: root.wallpaperPath
        onError: error => {
            console.debug(`${error}`);
            colorGenerator.running = false;
        }
    }
}
