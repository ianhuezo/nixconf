import Quickshell
import QtQuick
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Wayland
import qs.config
import qs.services
import "root:/components"

PanelWindow {
    id: root

    required property bool isActive
    signal closeRequested

    readonly property int panelWidth: 360
    readonly property int panelRightMargin: 8
    readonly property int topOffset: 70

    visible: isActive || slideX <= (panelWidth + panelRightMargin)
    color: "transparent"
    implicitWidth: panelWidth + panelRightMargin
    implicitHeight: 620

    anchors {
        top: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: isActive ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.margins {
        top: topOffset
        right: 0
        bottom: 0
        left: 0
    }

    // ---- File listing ----
    ListModel {
        id: screenshotModel

        function reload(paths) {
            clear();
            for (let p of paths) {
                append({ filePath: p });
            }
        }
    }

    Process {
        id: fileLister
        command: ["sh", "-c", "ls -t /tmp/screenshots/*.png 2>/dev/null | head -50"]
        running: false

        property var collectedPaths: []

        stdout: SplitParser {
            onRead: line => {
                const t = line.trim();
                if (t) fileLister.collectedPaths.push(t);
            }
        }

        onStarted: collectedPaths = []
        onExited: exitCode => screenshotModel.reload(collectedPaths)
    }

    Process {
        id: clipboardCopier
        property string targetPath: ""
        command: ["sh", "-c", "wl-copy < \"" + targetPath + "\""]
        running: false
        onExited: running = false
    }

    Process {
        id: fileDeleter
        property string targetPath: ""
        command: ["rm", "-f", targetPath]
        running: false
        onExited: exitCode => {
            running = false;
            fileLister.collectedPaths = [];
            fileLister.running = true;
        }
    }

    // ---- State ----
    property bool showAll: false

    // ---- Slide animation ----
    // slideX = 0: panel fully visible at right edge of screen
    // slideX = panelWidth + panelRightMargin: content pushed outside surface (invisible)
    property real slideX: panelWidth + panelRightMargin + 1

    NumberAnimation {
        id: enterAnim
        target: root
        property: "slideX"
        to: 0
        duration: 500
        easing.type: Easing.Bezier
        easing.bezierCurve: AppearanceConfig.transitions.panelEnter
    }

    NumberAnimation {
        id: exitAnim
        target: root
        property: "slideX"
        to: root.panelWidth + root.panelRightMargin + 2
        duration: 300
        easing.type: Easing.OutCubic
    }

    Timer {
        id: autoCloseTimer
        interval: 10000
        onTriggered: root.closeRequested()
    }

    function resetAutoClose() {
        if (isActive) autoCloseTimer.restart();
    }

    onIsActiveChanged: {
        if (isActive) {
            enterAnim.start();
            showAll = false;
            fileLister.collectedPaths = [];
            fileLister.running = true;
            contentWrapper.forceActiveFocus();
            autoCloseTimer.restart();
        } else {
            exitAnim.start();
            showAll = false;
            autoCloseTimer.stop();
        }
    }

    // ---- Content ----
    Item {
        id: contentWrapper
        x: root.slideX
        width: root.panelWidth
        height: parent.height
        focus: true

        Keys.onEscapePressed: root.closeRequested()

        // Reset auto-close timer on any mouse activity over the panel
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            acceptedButtons: Qt.NoButton
            onPositionChanged: root.resetAutoClose()
            onEntered: root.resetAutoClose()
        }

        Rectangle {
            id: panel
            anchors {
                top: parent.top
                right: parent.right
                rightMargin: root.panelRightMargin
            }
            width: root.panelWidth - root.panelRightMargin

            readonly property int headerH: 44
            readonly property int dividerH: 1
            readonly property int itemH: 84
            readonly property int footerH: screenshotModel.count > 3 ? 40 : 0
            readonly property int emptyH: screenshotModel.count === 0 ? 60 : 0
            readonly property int maxScrollH: 440

            height: {
                if (root.showAll) {
                    const scrollH = Math.min(screenshotModel.count * itemH, maxScrollH);
                    return headerH + dividerH + 12 + scrollH + footerH + 8;
                } else {
                    const visibleCount = Math.min(screenshotModel.count, 3);
                    const listH = visibleCount > 0 ? visibleCount * itemH : emptyH;
                    return headerH + dividerH + 12 + listH + footerH + 8;
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 260
                    easing.type: Easing.InOutCubic
                }
            }

            color: Color.palette.base00
            radius: AppearanceConfig.radius.lg
            border.width: 1
            border.color: Color.palette.base0C

            // Header
            Item {
                id: headerRow
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    topMargin: 4
                    leftMargin: 12
                    rightMargin: 8
                }
                height: 40

                Text {
                    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                    text: "Screenshots"
                    color: Color.palette.base05
                    font.pixelSize: AppearanceConfig.font.size.md
                    font.weight: AppearanceConfig.font.weight.semibold
                    font.family: AppearanceConfig.font.ui
                }

                Row {
                    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                    spacing: 2

                    IconButton {
                        iconText: "↺"
                        iconSize: 15
                        implicitHeight: 30
                        implicitWidth: 30
                        backgroundColor: "transparent"
                        onClicked: {
                            root.resetAutoClose();
                            fileLister.collectedPaths = [];
                            fileLister.running = true;
                        }
                    }

                    IconButton {
                        iconText: "✕"
                        iconSize: 13
                        implicitHeight: 30
                        implicitWidth: 30
                        backgroundColor: "transparent"
                        onClicked: root.closeRequested()
                    }
                }
            }

            // Divider
            Rectangle {
                id: divider
                anchors {
                    top: headerRow.bottom
                    left: parent.left
                    right: parent.right
                    leftMargin: 12
                    rightMargin: 12
                }
                height: 1
                color: Color.palette.base03
            }

            // Collapsed: top 3 cards
            Column {
                id: collapsedList
                visible: !root.showAll
                anchors {
                    top: divider.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: 8
                    leftMargin: 8
                    rightMargin: 8
                }
                spacing: 6

                Repeater {
                    model: Math.min(screenshotModel.count, 3)
                    delegate: ScreenshotItem {
                        required property int index
                        width: collapsedList.width
                        filePath: screenshotModel.get(index).filePath
                        onCopyRequested: path => {
                            root.resetAutoClose();
                            clipboardCopier.targetPath = path;
                            clipboardCopier.running = true;
                        }
                        onDeleteRequested: path => {
                            root.resetAutoClose();
                            fileDeleter.targetPath = path;
                            fileDeleter.running = true;
                        }
                    }
                }
            }

            // Expanded: scrollable all cards
            Flickable {
                id: scrollArea
                visible: root.showAll
                clip: true
                anchors {
                    top: divider.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: 8
                    leftMargin: 8
                    rightMargin: 8
                }
                height: Math.min(expandedColumn.implicitHeight, panel.maxScrollH)
                contentHeight: expandedColumn.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Column {
                    id: expandedColumn
                    width: scrollArea.width
                    spacing: 6

                    Repeater {
                        model: screenshotModel
                        delegate: ScreenshotItem {
                            width: expandedColumn.width
                            filePath: model.filePath
                            onCopyRequested: path => {
                                root.resetAutoClose();
                                clipboardCopier.targetPath = path;
                                clipboardCopier.running = true;
                            }
                            onDeleteRequested: path => {
                                root.resetAutoClose();
                                fileDeleter.targetPath = path;
                                fileDeleter.running = true;
                            }
                        }
                    }
                }
            }

            // Empty state
            Text {
                visible: screenshotModel.count === 0
                anchors {
                    top: divider.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: 16
                }
                horizontalAlignment: Text.AlignHCenter
                text: "No screenshots in /tmp/screenshots"
                color: Color.palette.base04
                font.pixelSize: AppearanceConfig.font.size.sm
                font.family: AppearanceConfig.font.ui
            }

            // Show more / show less footer
            Rectangle {
                id: showMoreRow
                visible: screenshotModel.count > 3
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    right: parent.right
                    bottomMargin: 8
                    leftMargin: 8
                    rightMargin: 8
                }
                height: 32
                radius: AppearanceConfig.radius.sm
                color: showMoreArea.containsMouse ? Color.palette.base02 : "transparent"

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }

                Text {
                    anchors.centerIn: parent
                    text: root.showAll
                        ? "▲  Show less"
                        : "▼  Show all  (" + screenshotModel.count + ")"
                    color: Color.palette.base0C
                    font.pixelSize: AppearanceConfig.font.size.sm
                    font.family: AppearanceConfig.font.ui
                }

                MouseArea {
                    id: showMoreArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.resetAutoClose();
                        root.showAll = !root.showAll;
                    }
                }
            }
        }
    }
}
