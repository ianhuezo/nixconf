pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root
    readonly property string scriptRootPath: '../../scripts'
    readonly property string assetsRootPath: '../../assets'

    function getIconPath(iconName) {
        return Qt.resolvedUrl(`${assetsRootPath}/icons/${iconName}`);
    }

    function getScriptPath(scriptName) {
        return Qt.resolvedUrl(`${scriptRootPath}/${scriptName}`);
    }

    // Icon paths object with pre-resolved URLs
    readonly property QtObject icons: QtObject {
        readonly property string nix: root.getIconPath("nixos.png")
    }

    readonly property QtObject scripts: QtObject {
        readonly property string cava: root.getScriptPath('cava_startup.sh')
    }
}
