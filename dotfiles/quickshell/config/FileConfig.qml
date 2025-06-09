pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property string scriptRootPath: '../../scripts'
    readonly property string assetsRootPath: '../../assets'
    readonly property string nixIcon: Qt.resolvedUrl(`${assetsRootPath}/icons/nixos.png`)

    component IconPaths: QtObject {}

    component ScriptPaths: QtObject {}
}
