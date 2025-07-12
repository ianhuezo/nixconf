import Quickshell
import QtQuick
import "root:/libs/fuzzysort/fuzzysort.js" as Fuzzy

Item {
    id: appViewer
    anchors.fill: parent
    readonly property list<DesktopEntry> list: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    readonly property list<var> preppedApps: list.map(a => ({
            name: Fuzzy.prepare(a.name),
            comment: Fuzzy.prepare(a.comment),
            entry: a
        }))
    Rectangle {
        id: content
        anchors.fill: parent
        onStateChanged: {
            print(appViewer.list);
        }
    }
}
