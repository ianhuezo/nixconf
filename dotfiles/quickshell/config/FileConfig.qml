pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    //
    readonly property string rootPath: "file:///etc/nixos/dotfiles"
    readonly property string scriptRootPath: rootPath + '/scripts'
    readonly property string assetsRootPath: rootPath + '/assets'
    readonly property string themesRootPath: rootPath + '/themes'
    readonly property string homePath: 'Music'

    readonly property string splashArtPath: Qt.resolvedUrl(`${assetsRootPath}/frieren/camp-crop.jpg`)
    readonly property string dashboardAppLauncher: Qt.resolvedUrl(`${assetsRootPath}/frieren/mimic.png`)
    readonly property string youtubeConverter: Qt.resolvedUrl(`${assetsRootPath}/global/youtube.png`)

    function getIconPath(iconName) {
        //for icons that are not from font packages
        return Qt.resolvedUrl(`${assetsRootPath}/icons/${iconName}`);
    }

    function getScriptPath(scriptName) {
        return Qt.resolvedUrl(`${scriptRootPath}/${scriptName}`);
    }

    // Icon paths object with pre-resolved URLs
    readonly property QtObject icons: QtObject {
        readonly property string nix: root.getIconPath("nixos.png")
        readonly property string gpu: root.getIconPath("gpu.svg")
        readonly property string cpu: root.getIconPath("cpu.svg")
        readonly property string ram: root.getIconPath("ram.svg")
        readonly property string media: root.getIconPath("media.svg")
        readonly property string workspace: root.getIconPath("lamp_on.png")
    }

    readonly property QtObject scripts: QtObject {
        readonly property string cava: root.getScriptPath('cava_startup.sh')
        readonly property string downloadYoutube: root.getScriptPath('yt_to_mp3/youtube_dl.sh')
        readonly property string saveMP3: root.getScriptPath('yt_to_mp3/create_mp3_metadata.sh')
    }
}
