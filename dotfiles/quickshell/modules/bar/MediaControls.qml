import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Widgets
import QtQuick
import QtQuick.Shapes
import qs.config
import qs.services

PopupWindow {
    id: root

    required property Item anchorItem
    required property var barWindow
    required property string visualizerMode
    property string fallbackArt: ""
    property bool open: false
    property bool modeListOpen: false
    property MprisPlayer player: null
    property real seekPreview: -1
    property real reveal: 0

    signal visualizerModeSelected(string mode)

    readonly property real padding: 12
    readonly property real widgetWidth: Math.round(anchorItem.width * AppearanceConfig.mediaWidget.widthScale)
    readonly property real widgetHeight: Math.round(widgetWidth / AppearanceConfig.mediaWidget.heightRatio)
    readonly property real cornerRadius: AppearanceConfig.calculateRadius(widgetWidth, widgetHeight, "lg")
    readonly property bool isBrowser: /firefox|chrom|brave|vivaldi|opera|edge|librewolf|floorp|zen/i.test((player?.desktopEntry ?? "") + " " + (player?.identity ?? ""))
    readonly property bool fullControl: player !== null && !isBrowser
    readonly property real trackLength: player?.lengthSupported ? player.length : 0
    readonly property bool canSeek: fullControl && player.canSeek && trackLength > 0
    readonly property real progress: seekPreview >= 0 ? seekPreview : trackLength > 0 ? currentPosition() / trackLength : 0
    readonly property string artSource: player?.trackArtUrl || (player?.identity === "Spotify" ? fallbackArt : "")

    function choosePlayer() {
        const players = Array.from(Mpris.players.values).filter(p => !(p.dbusName ?? "").includes("playerctld"));
        if (root.player && root.player.isPlaying && players.includes(root.player))
            return;
        const playing = players.filter(p => p.isPlaying);
        if (playing.length > 0)
            root.player = playing.find(p => p.identity === "Spotify") || playing[0];
        else if (!root.player || !players.includes(root.player))
            root.player = players.find(p => p.identity === "Spotify") || players[0] || null;
    }

    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(seconds));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor(total % 3600 / 60);
        const secs = String(total % 60).padStart(2, "0");
        return hours > 0 ? `${hours}:${String(minutes).padStart(2, "0")}:${secs}` : `${minutes}:${secs}`;
    }

    function cycleLoop() {
        if (player.loopState === MprisLoopState.None)
            player.loopState = MprisLoopState.Playlist;
        else if (player.loopState === MprisLoopState.Playlist)
            player.loopState = MprisLoopState.Track;
        else
            player.loopState = MprisLoopState.None;
    }

    function seekFraction(x, width) {
        return Math.max(0, Math.min(1, x / width));
    }

    function currentPosition() {
        const position = player?.position ?? 0;
        return trackLength > 0 && position > trackLength ? position % trackLength : position;
    }

    function seekTo(fraction) {
        const target = fraction * trackLength;
        const trackId = player.metadata["mpris:trackid"];
        if (typeof trackId === "string" && !/^\/(\w+(\/\w+)*)?$/.test(trackId))
            player.seek(target - currentPosition());
        else
            player.position = target;
    }

    anchor.item: anchorItem
    anchor.rect.x: (anchorItem.width - implicitWidth) / 2
    anchor.rect.y: anchorItem.height
    implicitWidth: widgetWidth + cornerRadius * 2
    implicitHeight: widgetHeight
    color: "transparent"
    visible: open || reveal > 0
    mask: Region {
        item: drawer
    }

    Component.onCompleted: choosePlayer()

    onOpenChanged: {
        if (open) {
            choosePlayer();
            player?.positionChanged();
            exitAnim.stop();
            enterAnim.start();
        } else {
            modeListOpen = false;
            enterAnim.stop();
            exitAnim.start();
        }
    }

    NumberAnimation {
        id: enterAnim
        target: root
        property: "reveal"
        to: 1
        duration: 500
        easing.type: Easing.Bezier
        easing.bezierCurve: AppearanceConfig.transitions.panelEnter
    }

    NumberAnimation {
        id: exitAnim
        target: root
        property: "reveal"
        to: 0
        duration: 300
        easing.type: Easing.OutCubic
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            root.choosePlayer();
        }
    }

    Variants {
        model: Mpris.players.values
        delegate: Connections {
            required property var modelData
            target: modelData
            function onPlaybackStateChanged() {
                root.choosePlayer();
            }
        }
    }

    Timer {
        running: root.visible && (root.player?.isPlaying ?? false)
        interval: 500
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Timer {
        id: seekHold
        interval: 1000
        onTriggered: root.seekPreview = -1
    }

    Connections {
        target: root.player
        function onPositionChanged() {
            if (seekHold.running && Math.abs(root.currentPosition() - root.seekPreview * root.trackLength) < 1) {
                seekHold.stop();
                root.seekPreview = -1;
            }
        }
    }

    HyprlandFocusGrab {
        active: root.open
        windows: [root, root.barWindow]
        onCleared: root.open = false
    }

    component ControlButton: Item {
        id: button

        property string glyph
        property real glyphSize: 18
        property bool toggle: false
        property bool active: false
        property bool filled: false

        signal clicked

        width: filled ? 34 : 26
        height: 34
        opacity: enabled ? 1 : 0.35

        Rectangle {
            anchors.centerIn: parent
            width: 34
            height: 34
            radius: 17
            visible: button.filled
            color: buttonArea.containsMouse ? Qt.lighter(Color.palette.base0C, 1.15) : Color.palette.base0C
        }

        Text {
            anchors.centerIn: parent
            text: button.glyph
            font.family: AppearanceConfig.font.mono
            font.pixelSize: button.glyphSize
            color: {
                if (button.filled)
                    return Color.palette.base00;
                if (button.toggle)
                    return button.active ? Color.palette.base0C : buttonArea.containsMouse ? Color.palette.base05 : Color.palette.base04;
                return buttonArea.containsMouse ? Color.palette.base0C : Color.palette.base05;
            }
        }

        MouseArea {
            id: buttonArea
            anchors.fill: parent
            hoverEnabled: button.enabled
            cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.clicked()
        }
    }

    Item {
        id: drawer

        readonly property real r: root.cornerRadius

        y: -(1 - root.reveal) * height
        width: root.implicitWidth
        height: root.widgetHeight

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            ShapePath {
                fillColor: Color.palette.base01
                strokeColor: "transparent"
                startX: 0
                startY: 0

                PathLine {
                    x: drawer.width
                    y: 0
                }
                PathArc {
                    x: drawer.width - drawer.r
                    y: drawer.r
                    radiusX: drawer.r
                    radiusY: drawer.r
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: drawer.width - drawer.r
                    y: drawer.height - drawer.r
                }
                PathArc {
                    x: drawer.width - drawer.r * 2
                    y: drawer.height
                    radiusX: drawer.r
                    radiusY: drawer.r
                }
                PathLine {
                    x: drawer.r * 2
                    y: drawer.height
                }
                PathArc {
                    x: drawer.r
                    y: drawer.height - drawer.r
                    radiusX: drawer.r
                    radiusY: drawer.r
                }
                PathLine {
                    x: drawer.r
                    y: drawer.r
                }
                PathArc {
                    x: 0
                    y: 0
                    radiusX: drawer.r
                    radiusY: drawer.r
                    direction: PathArc.Counterclockwise
                }
            }
        }

        Item {
            id: card
            x: drawer.r
            width: root.widgetWidth
            height: root.widgetHeight

            ClippingRectangle {
                id: art
                x: root.padding
                y: root.padding
                width: Math.round(root.widgetHeight * 0.4)
                height: width
                radius: 6
                color: Color.palette.base02

                Image {
                    id: artImage
                    anchors.fill: parent
                    source: root.artSource
                    sourceSize.width: width * 2
                    sourceSize.height: height * 2
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    retainWhileLoading: true
                    smooth: true
                    mipmap: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: artImage.status === Image.Null || artImage.status === Image.Error
                    text: "♪"
                    color: Color.palette.base04
                    font.pixelSize: 22
                }
            }

            Item {
                anchors.left: art.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: root.padding
                anchors.top: art.top
                anchors.bottom: art.bottom

                Text {
                    id: title
                    width: parent.width
                    text: root.player?.trackTitle || "Nothing playing"
                    color: Color.palette.base05
                    font.family: AppearanceConfig.font.ui
                    font.pixelSize: AppearanceConfig.font.size.sm
                    font.weight: AppearanceConfig.font.weight.semibold
                    elide: Text.ElideRight
                }

                Text {
                    anchors.top: title.bottom
                    anchors.topMargin: 2
                    width: parent.width
                    text: root.player?.trackArtist || root.player?.identity || ""
                    color: Color.palette.base04
                    font.family: AppearanceConfig.font.ui
                    font.pixelSize: AppearanceConfig.font.size.xs
                    elide: Text.ElideRight
                }

                Item {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: times.top
                    anchors.bottomMargin: 2
                    height: 10

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Color.palette.base02

                        Rectangle {
                            width: parent.width * root.progress
                            height: parent.height
                            radius: 2
                            color: root.canSeek ? Color.palette.base0C : Color.palette.base04
                        }
                    }

                    Rectangle {
                        x: parent.width * root.progress - width / 2
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10
                        height: 10
                        radius: 5
                        color: Color.palette.base05
                        visible: root.canSeek && (seekArea.containsMouse || seekArea.pressed)
                    }

                    MouseArea {
                        id: seekArea
                        anchors.fill: parent
                        enabled: root.canSeek
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: mouse => {
                            seekHold.stop();
                            root.seekPreview = root.seekFraction(mouse.x, width);
                        }
                        onPositionChanged: mouse => {
                            if (pressed)
                                root.seekPreview = root.seekFraction(mouse.x, width);
                        }
                        onReleased: {
                            root.seekTo(root.seekPreview);
                            seekHold.restart();
                        }
                        onCanceled: root.seekPreview = -1
                    }
                }

                Item {
                    id: times
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: elapsed.implicitHeight

                    Text {
                        id: elapsed
                        text: root.trackLength > 0 ? root.formatTime(root.progress * root.trackLength) : "--:--"
                        color: Color.palette.base04
                        font.family: AppearanceConfig.font.mono
                        font.pixelSize: AppearanceConfig.font.size.xs - 1
                    }

                    Text {
                        anchors.right: parent.right
                        text: root.trackLength > 0 ? root.formatTime(root.trackLength) : "--:--"
                        color: Color.palette.base04
                        font.family: AppearanceConfig.font.mono
                        font.pixelSize: AppearanceConfig.font.size.xs - 1
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: art.y + art.height + (footer.y - art.y - art.height - height) / 2
                spacing: 14

                ControlButton {
                    glyph: "󰒟"
                    glyphSize: 15
                    toggle: true
                    active: root.player?.shuffle ?? false
                    enabled: root.fullControl && root.player.shuffleSupported
                    onClicked: root.player.shuffle = !root.player.shuffle
                }

                ControlButton {
                    glyph: "󰒮"
                    glyphSize: 20
                    enabled: root.fullControl && root.player.canGoPrevious
                    onClicked: root.player.previous()
                }

                ControlButton {
                    glyph: root.player?.isPlaying ? "󰏤" : "󰐊"
                    glyphSize: 22
                    filled: true
                    enabled: root.player?.canTogglePlaying ?? false
                    onClicked: root.player.togglePlaying()
                }

                ControlButton {
                    glyph: "󰒭"
                    glyphSize: 20
                    enabled: root.fullControl && root.player.canGoNext
                    onClicked: root.player.next()
                }

                ControlButton {
                    glyph: root.player?.loopState === MprisLoopState.Track ? "󰑘" : "󰑖"
                    glyphSize: 15
                    toggle: true
                    active: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                    enabled: root.fullControl && root.player.loopSupported
                    onClicked: root.cycleLoop()
                }
            }

            MouseArea {
                anchors.fill: parent
                z: 1
                enabled: root.modeListOpen
                onClicked: root.modeListOpen = false
            }

            Item {
                id: footer
                z: 2
                x: root.padding
                anchors.bottom: parent.bottom
                anchors.bottomMargin: root.padding - 2
                width: parent.width - root.padding * 2
                height: modeButton.height

                Text {
                    id: footerLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: "VISUALIZER"
                    color: Color.palette.base04
                    font.family: AppearanceConfig.font.ui
                    font.pixelSize: AppearanceConfig.font.size.xs - 2
                    font.weight: AppearanceConfig.font.weight.semibold
                    font.letterSpacing: 1
                }

                Rectangle {
                    id: modeButton
                    anchors.left: footerLabel.right
                    anchors.leftMargin: 8
                    width: 78
                    height: 18
                    radius: 4
                    color: modeArea.containsMouse || root.modeListOpen ? Color.palette.base03 : Color.palette.base02

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.visualizerMode
                        color: Color.palette.base05
                        font.family: AppearanceConfig.font.ui
                        font.pixelSize: AppearanceConfig.font.size.xs
                        font.capitalization: Font.Capitalize
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 5
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅀"
                        rotation: root.modeListOpen ? 180 : 0
                        color: Color.palette.base04
                        font.family: AppearanceConfig.font.mono
                        font.pixelSize: AppearanceConfig.font.size.xs
                    }

                    MouseArea {
                        id: modeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.modeListOpen = !root.modeListOpen
                    }
                }

                Rectangle {
                    anchors.left: modeButton.left
                    anchors.bottom: modeButton.top
                    anchors.bottomMargin: 4
                    width: modeButton.width
                    height: modeColumn.implicitHeight + 8
                    radius: 6
                    color: Color.palette.base01
                    border.width: 1
                    border.color: Color.palette.base03
                    visible: root.modeListOpen

                    Column {
                        id: modeColumn
                        x: 4
                        y: 4
                        width: parent.width - 8

                        Repeater {
                            model: AppearanceConfig.visualizerModes

                            delegate: Rectangle {
                                required property string modelData

                                width: modeColumn.width
                                height: 18
                                radius: 4
                                color: optionArea.containsMouse ? Color.palette.base02 : "transparent"

                                Text {
                                    x: 5
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData
                                    color: modelData === root.visualizerMode ? Color.palette.base0C : Color.palette.base05
                                    font.family: AppearanceConfig.font.ui
                                    font.pixelSize: AppearanceConfig.font.size.xs
                                    font.capitalization: Font.Capitalize
                                }

                                MouseArea {
                                    id: optionArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.modeListOpen = false;
                                        root.visualizerModeSelected(modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
