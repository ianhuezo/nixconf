pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    readonly property string scriptRootPath: '../../scripts'
    readonly property string assetsRootPath: '../../assets'
    readonly property string themesRootPath: '../../themes'

    readonly property string splashArtPath: Qt.resolvedUrl(`${assetsRootPath}/transparent/frieren-camp-crop.jpg`)
    readonly property string dashboardAppLauncher: Qt.resolvedUrl(`${assetsRootPath}/transparent/mimic.png`)
    readonly property string musicAppLauncher: Qt.resolvedUrl(`${assetsRootPath}/transparent/frieren-wand.png`)

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
    }

    readonly property QtObject scripts: QtObject {
        readonly property string cava: root.getScriptPath('cava_startup.sh')
    }
}
