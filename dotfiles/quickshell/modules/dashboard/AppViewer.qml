import Quickshell
import QtQuick
import QtQuick.Controls
import "root:/config"
import "root:/services"
import "root:/libs/fuzzysort/fuzzysort.js" as Fuzzy

Item {
    id: appViewer
    anchors.fill: parent
    property var listIndex: 0
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
        color: 'transparent'
        SearchBar {
            id: searchBar
        }
        Rectangle {
            id: appListContainer
            property real verticalMargin: 30
            x: searchBar.x
            y: searchBar.y + searchBar.height + verticalMargin
            width: searchBar.width
            height: parent.height - searchBar.height - verticalMargin * 4
            color: 'transparent'
            Component {
                id: appList

                Item {
                    id: appItem
                    required property var modelData
                    required property int index
                    width: searchBar.width
                    height: 40
                    Rectangle {
                        anchors.fill: parent
                        color: {
                            return appItem.index == 0 ? 'blue' : 'transparent';
                        }
                    }
                }
            }

            ScrollView {
                anchors.fill: parent
                Column {
                    width: parent.width
                    Repeater {
                        model: appViewer.preppedApps
                        delegate: appList
                    }
                }
            }
        }
    }
}
