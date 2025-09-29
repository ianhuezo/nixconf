import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import qs.config
import qs.services
import "root:/libs/fuzzysort/fuzzysort.js" as Fuzzy

Item {
    id: appViewer
    anchors.fill: parent
    property int userSelectedIndex: 0
    property var userText: ""
    property real selectionHeight: 40
    signal appSelected
    //these dont have 32x32 icons... strange
    property var blacklistedApps: ["Advanced Network Configuration", "Volume Control"]
    property list<DesktopEntry> list: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    property list<var> preppedApps: list.filter(a => !blacklistedApps.includes(a.name))  // Filter blacklist here
    .map(a => ({
                name: Fuzzy.prepare(a.name),
                comment: Fuzzy.prepare(a.comment),
                entry: a
            }))

    // Use the filtered list from preppedApps for the fallback
    property var currentResults: {
        return userText ? fuzzyQuery(userText) : preppedApps.map(p => p.entry);
    }
    function fuzzyQuery(search: string): var {
        return Fuzzy.go(search, preppedApps, {
            all: true,
            keys: ["name", "comment"],
            scoreFn: r => r[0].score > 0 ? r[0].score * 0.9 + r[1].score * 0.1 : 0
        }).map(r => r.obj.entry);
    }
    function scrollDown() {
        let currentIndex = appViewer.userSelectedIndex;
        let maxIndex = Math.max(0, appViewer.currentResults.length - 1);
        currentIndex += 1;
        appViewer.userSelectedIndex = Math.min(currentIndex, maxIndex);

        const currentSelectionHeight = selectionHeight * (userSelectedIndex + 1);
        if (currentSelectionHeight > flickable.height) {
            scrollBarVertical.increase();
        }
    }
    function scrollUp() {
        let currentIndex = appViewer.userSelectedIndex;
        currentIndex -= 1;
        appViewer.userSelectedIndex = Math.max(0, currentIndex);
        const selectedItemTop = selectionHeight * userSelectedIndex;
        const visibleTop = flickable.contentY;
        if (selectedItemTop < visibleTop) {
            scrollBarVertical.decrease();
        }
    }
    function selectApplication() {
        if (appViewer.currentResults.length > 0 && appViewer.userSelectedIndex < appViewer.currentResults.length) {
            let execCmd = appViewer.currentResults[appViewer.userSelectedIndex].execString;
            execCmd = execCmd.replace(/\s?%[fFuUdDnNiCkvm]/g, ''); //this gets rid of weird %U or other characters
            Quickshell.execDetached(["sh", "-c", `cd ~ && ${execCmd.trim()}`]);
            appViewer.appSelected();
        }
    }
    onActiveFocusChanged: {
        if (activeFocus) {
            searchBar.forceActiveFocus();
        }
    }
    Keys.onPressed: event => {
        let currentIndex = appViewer.userSelectedIndex;
        let maxIndex = Math.max(0, appViewer.currentResults.length - 1);

        if (event.key == Qt.Key_Down) {
            scrollDown();
        } else if (event.key == Qt.Key_Up) {
            scrollUp();
        } else if (event.key == Qt.Key_Enter || event.key == Qt.Key_Return) {
            selectApplication();
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
                                id: appIcon
                                height: appViewer.selectionHeight - 8
                                width: appViewer.selectionHeight - 8
                                sourceSize.width: width
                                sourceSize.height: height
                                source: {
                                    if (modelData.icon) {
                                        return Quickshell.iconPath(modelData.icon);
                                    }
                                    return FileConfig.icons.media;
                                }

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    colorization: !modelData.icon ? 1.0 : 0.0
                                    colorizationColor: !modelData.icon ? Color.palette.base07 : "transparent"
                                    saturation: modelData.icon ? 0.0 : -1.0
                                    brightness: modelData.icon ? 0.0 : 1.0
                                }
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
                    ListView {
                        width: parent.width
                        height: contentHeight  // This might not update properly
                        interactive: true
                        model: appViewer.currentResults
                        delegate: appList

                        // populate: Transition {
                        //     id: populateTrans
                        //     SequentialAnimation {
                        //         // Stagger delay for cascading effect
                        //         PauseAnimation {
                        //             duration: (populateTrans.ViewTransition.index - populateTrans.ViewTransition.targetIndexes[0]) * 60
                        //         }
                        //
                        //         ParallelAnimation {
                        //             // Smooth opacity fade-in
                        //             NumberAnimation {
                        //                 property: "opacity"
                        //                 from: 0
                        //                 to: 1
                        //                 duration: 350
                        //                 easing.type: Easing.InCirc
                        //             }
                        //
                        //             // Gentle horizontal slide (optional)
                        //             NumberAnimation {
                        //                 property: "x"
                        //                 from: 30
                        //                 to: 0
                        //                 duration: 300
                        //                 easing.type: Easing.OutCubic
                        //             }
                        //         }
                        //     }
                        // }
                    }
                }
            }
        }
    }
}
