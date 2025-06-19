import Quickshell
import QtQuick
import Quickshell.Io

Item {
    id: dashboard
    property bool active: false
    IpcHandler {
        target: "dashboard"

        function toggleDashboard() {
            dashboard.active = !dashboard.active;
        }
    }
    implicitWidth: 200
    implicitHeight: 150
    // Loader {
    //     active: dashboard.active
    //     PanelWindow {
    //
    //         Rectangle {
    //             implicitHeight: parent.implicitHeight
    //             implicitWidth: parent.implicitWidth
    //             anchors.fill: parent
    //             color: 'red'
    //         }
    //     }
    // }
}
