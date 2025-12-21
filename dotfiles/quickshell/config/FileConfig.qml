pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    //
    readonly property string rootPath: "file:///etc/nixos/dotfiles"
    readonly property string configPath: "file:///home/ianh/.config"
    readonly property string scriptRootPath: rootPath + '/scripts'
    readonly property string assetsRootPath: rootPath + '/assets'
    readonly property string themesRootPath: rootPath + '/themes'
    readonly property string environmentRootPath: configPath
    readonly property string homePath: 'Music'

    //art for app selector
    readonly property string splashArtPath: Qt.resolvedUrl(`${assetsRootPath}/frieren/camp-crop.jpg`)
    readonly property string dashboardAppLauncher: Qt.resolvedUrl(`${assetsRootPath}/frieren/mimic.png`)

    //art for youtube converter
    readonly property string youtubeConverter: Qt.resolvedUrl(`${assetsRootPath}/global/youtube.png`)
    readonly property string downloadingVideoMP3: Qt.resolvedUrl(`${assetsRootPath}/frieren/fern-pout.gif`)

    //art for theme selector
    readonly property string themeChooser: Qt.resolvedUrl(`${assetsRootPath}/frieren/lookup.png`)

    function getIconPath(iconName) {
        //for icons that are not from font packages
        return Qt.resolvedUrl(`${assetsRootPath}/icons/${iconName}`);
    }

    function getScriptPath(scriptName) {
        return Qt.resolvedUrl(`${scriptRootPath}/${scriptName}`);
    }

    function getEnvironmentPath(environmentName) {
        return Qt.resolvedUrl(`${environmentRootPath}/${environmentName}`);
    }

    // Icon paths object with pre-resolved URLs
    readonly property QtObject icons: QtObject {
        readonly property string nix: root.getIconPath("nixos.png")
        readonly property string gpu: root.getIconPath("gpu.svg")
        readonly property string cpu: root.getIconPath("cpu.svg")
        readonly property string ram: root.getIconPath("ram.svg")
        readonly property string media: root.getIconPath("media.svg")
        readonly property string workspace: root.getIconPath("lamp_on.png")
        readonly property string spark: root.getIconPath("spark.svg")
    }

    readonly property QtObject scripts: QtObject {
        readonly property string cava: root.getScriptPath('cava_startup.sh')
        readonly property string downloadYoutube: root.getScriptPath('yt_to_mp3/youtube_dl.sh')
        readonly property string saveMP3: root.getScriptPath('yt_to_mp3/create_mp3_metadata.sh')
        readonly property string extractMP3AlbumImage: root.getScriptPath('yt_to_mp3/extract_mp3_image.sh')
        readonly property string generateWallpaper: root.getScriptPath('ai_color_creator/generate_wallpaper.sh')
        readonly property string generateClaudeWallpaper: root.getScriptPath('ai_color_creator/generate_claude_wallpaper.sh')
        readonly property string generateAIColorPrompt: root.getScriptPath('ai_color_creator/prompt.md')
        readonly property string kmeansColors: root.getScriptPath('kmeans_colors/kmeans.sh')
    }

    readonly property QtObject environment: QtObject {
        readonly property string geminiAPIKeyPath: root.getEnvironmentPath('gemini/api.json')
        readonly property string wallhavenAPIKeyPath: root.getEnvironmentPath('wallhaven/api.json')
    }
}
