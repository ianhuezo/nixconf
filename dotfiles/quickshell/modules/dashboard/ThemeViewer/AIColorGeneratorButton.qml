import qs.components
import QtQuick
import qs.config
import qs.services
import Quickshell.Io

IconButton {
    id: root
    iconText: "✨"

    tooltip: "Generate" + "\n" + "Theme"
    property string wallpaperPath: ""
    property var apiKey: JSON.parse(jsonFile.text())['apiKey'] ?? ""
    loading: colorGenerator.running
    disabled: colorGenerator.running
    signal colorsGenerated(var json)

    // Use gradient loading effect with gold/orange colors
    loadingEffectType: "gradient"
    loadingPrimaryColor: Color.palette.base09
    loadingSecondaryColor: Qt.rgba(Color.palette.base09.r, Color.palette.base09.g, Color.palette.base09.b, 0.1)

    // Add active state glow when ready
    active: wallpaperPath.length > 0 && !colorGenerator.running
    stateEffectType: "glow"
    stateActiveColor: Color.palette.base09

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
