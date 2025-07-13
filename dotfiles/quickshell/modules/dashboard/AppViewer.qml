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
    function fuzzyQuery(search: string): var { // Idk why list<DesktopEntry> doesn't work
        return Fuzzy.go(search, preppedApps, {
            all: true,
            keys: ["name", "comment"],
            scoreFn: r => r[0].score > 0 ? r[0].score * 0.9 + r[1].score * 0.1 : 0
        }).map(r => r.obj.entry);
    }
    Rectangle {
        id: content
        anchors.fill: parent
        Component.onCompleted: {
            fuzzyQuery("").forEach(result => {
                console.log(result.name);
            });
        }
    }
}
