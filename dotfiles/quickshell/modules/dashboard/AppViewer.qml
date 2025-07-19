import Quickshell
import QtQuick
import QtQuick.Controls
import "root:/config"
import "root:/services"
import "root:/libs/fuzzysort/fuzzysort.js" as Fuzzy

Item {
    id: appViewer
    anchors.fill: parent
    property int userSelectedIndex: 0
    property var userText: ""
    property real selectionHeight: 40
    signal appSelected
    property var blacklistedApps: ["Advanced Network Configuration", "Volume Control"]
    readonly property list<DesktopEntry> list: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    readonly property list<var> preppedApps: list.map(a => ({
                name: Fuzzy.prepare(a.name),
                comment: Fuzzy.prepare(a.comment),
                entry: a
            }))

    // Add property to store current filtered results
    property var currentResults: {
        let results = userText ? fuzzyQuery(userText) : list;
        return results.filter(app => !blacklistedApps.includes(app.name));
    }
    function fuzzyQuery(search: string): var {
        return Fuzzy.go(search, preppedApps, {
            all: true,
            keys: ["name", "comment"],
            scoreFn: r => r[0].score > 0 ? r[0].score * 0.9 + r[1].score * 0.1 : 0
        }).map(r => r.obj.entry);
    }
    function scrollDown() {
        const currentSelectionHeight = selectionHeight * (userSelectedIndex + 1);
        if (currentSelectionHeight > flickable.height) {
            scrollBarVertical.increase();
        }
    }
    function scrollUp() {
        const selectedItemTop = selectionHeight * userSelectedIndex;
        const visibleTop = flickable.contentY;
        if (selectedItemTop < visibleTop) {
            scrollBarVertical.decrease();
        }
    }

    Keys.onPressed: event => {
        let currentIndex = appViewer.userSelectedIndex;
        let maxIndex = Math.max(0, appViewer.currentResults.length - 1);

        if (event.key == Qt.Key_Down) {
            currentIndex += 1;
            appViewer.userSelectedIndex = Math.min(currentIndex, maxIndex);
            scrollDown();
        } else if (event.key == Qt.Key_Up) {
            currentIndex -= 1;
            appViewer.userSelectedIndex = Math.max(0, currentIndex);
            scrollUp();
        } else if (event.key == Qt.Key_Enter || event.key == Qt.Key_Return) {
            if (appViewer.currentResults.length > 0 && appViewer.userSelectedIndex < appViewer.currentResults.length) {
                let execCmd = appViewer.currentResults[appViewer.userSelectedIndex].execString;
                execCmd = execCmd.replace(/\s?%[fFuUdDnNiCkvm]/g, ''); //this gets rid of weird %U or other characters
                Quickshell.execDetached(["sh", "-c", `cd ~ && ${execCmd.trim()}`]);
                appViewer.appSelected();
            }
        }
    }

    Rectangle {
        id: content
        anchors.fill: parent
        color: 'transparent'
        SearchBar {
            id: searchBar
            onSearchText: text => {
                appViewer.userText = text;
            }
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
                    height: appViewer.selectionHeight
                    Rectangle {
                        anchors.fill: parent
                        radius: 5
                        color: {
                            return appItem.index == appViewer.userSelectedIndex ? Color.palette.base0D : 'transparent';
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 8

                            Image {
                                height: appViewer.selectionHeight - 8
                                width: appViewer.selectionHeight - 8
                                sourceSize.width: width
                                sourceSize.height: height
                                source: Quickshell.iconPath(modelData.icon)
                            }

                            Text {
                                text: modelData.name
                                anchors.verticalCenter: parent.verticalCenter
                                color: Color.palette.base07
                                font.family: 'JetBrains Mono Nerd Font'
                                font.weight: 400
                                font.pixelSize: 16
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                appViewer.appSelected();
                                modelData.execute();
                            }
                        }
                    }
                }
            }

            Flickable {
                id: flickable
                anchors.fill: parent
                clip: true
                ScrollBar.vertical: ScrollBar {
                    id: scrollBarVertical
                    parent: flickable.parent
                    anchors.top: flickable.top
                    anchors.left: flickable.right
                    anchors.bottom: flickable.bottom
                    stepSize: {
                        const totalItems = appViewer.currentResults.length + 1;
                        return totalItems > 0 ? 1 / totalItems : 0;
                    }
                }
                contentHeight: (appViewer.selectionHeight * (appViewer.currentResults.length + 1))
                contentWidth: parent.width
                Column {
                    width: parent.width
                    Repeater {
                        model: appViewer.currentResults  // Use filtered results instead of preppedApps
                        delegate: appList
                    }
                }
            }
        }
    }
}
