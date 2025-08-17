import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Effects
import Quickshell.Widgets
import "root:/modules/dashboard"
import "root:/config"
import "root:/services"

FocusScope {
    id: root
    anchors.fill: parent
    focus: true  // Important: Enable focus for the FocusScope

    property string userText: ''

    function clearSelection() {
        searchBar.readOnly = false;
        searchBar.setSearchText('');
        youtubeThumbnail.source = '';
        tagMP3FileProcess.mp3Path = '';
        tagMP3FileProcess.albumName = '';
        tagMP3FileProcess.albumArtist = '';
        tagMP3FileProcess.albumArtPath = '';
    }

    Rectangle {
        id: background
        anchors.fill: parent
        color: 'transparent'

        SearchBar {
            id: searchBar
            icon: '⇅'
            placeholderText: 'Enter Youtube URL and Press Enter...'
            onSearchText: text => {
                root.userText = text;
            }
        }
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Enter:
            case Qt.Key_Return:
                searchBar.readOnly = true;
                background.triggerDownloadProcess();
                break;
            default:
                break;
            }
        }

        Image {
            id: youtubeMediaSvg
            anchors.centerIn: parent
            width: clippingRectangle.width * 0.75
            height: clippingRectangle.height
            fillMode: Image.PreserveAspectFit
            source: FileConfig.icons.media
            mipmap: true
            layer.enabled: true
            layer.effect: MultiEffect {
                brightness: 1.0
                colorization: 1.0
                opacity: 0.2
                colorizationColor: Color.palette.base04
            }
            visible: false
        }
        ProgressIndicator {
            id: downloadProgress
            onProgressComplete: {
                console.log("Download completed!");
            }

            onClicked: {
                // Handle overlay clicks if needed (e.g., cancel download)
                console.log("Progress overlay clicked");
            }
        }

        ClippingRectangle {
            id: clippingRectangle
            width: parent.width * 0.5
            height: parent.height * 0.5
            anchors.horizontalCenter: youtubeMediaSvg.horizontalCenter
            y: youtubeMediaSvg.y - 24
            visible: youtubeThumbnail.source.toString().length > 0
            clip: true
            radius: 10

            Image {
                id: youtubeThumbnail
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: ''
                visible: source.toString().length > 0
                onVisibleChanged: {
                    if (visible && source.toString().length > 0) {
                        downloadProgress.hide();
                        downloadProgress.reset();
                    }
                }
            }
        }
        Rectangle {
            id: buttonContainer
            width: clearSelection.width + acceptSelection.width + 10  // buttons + spacing
            height: 40
            anchors.horizontalCenter: clippingRectangle.horizontalCenter
            y: clippingRectangle.y + clippingRectangle.height + 24
            visible: youtubeThumbnail.visible
            color: "transparent"  // or whatever background color you prefer

            Rectangle {
                id: clearSelection
                height: 40
                width: 40
                radius: 3
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: Color.palette.base02

                Text {
                    anchors.centerIn: parent
                    color: Color.palette.base05
                    font.pixelSize: 24
                    font.weight: 800
                    text: '⟳'
                    font.family: 'JetBrains Mono Nerd Font'
                }
                MouseArea {
                    id: resetArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.clearSelection();
                    }
                }
            }
            Rectangle {
                id: acceptSelection
                height: 40
                width: 165
                anchors.left: clearSelection.right
                anchors.leftMargin: 10  // 10px spacing
                anchors.verticalCenter: parent.verticalCenter
                color: acceptSelection.animationRunning ? Color.palette.base0B : Color.palette.base0D
                radius: 4

                property bool animationRunning: false
                MouseArea {
                    id: acceptMouseClick
                    anchors.fill: parent
                    enabled: !acceptSelection.animationRunning
                    cursorShape: Qt.PointingHandCursor

                    onClicked: {
                        if (buttonText.text == 'Upload Complete!') {
                            return;
                        }
                        acceptSelection.animationRunning = true;
                        buttonText.text = '';
                        circleAnimation.start();
                    }
                }

                Text {
                    id: buttonText
                    anchors.centerIn: parent
                    text: "♪ Add to Library"
                    color: Color.palette.base05
                    font.family: 'JetBrains Mono Nerd Font'
                    font.pixelSize: 16
                    opacity: acceptSelection.animationRunning ? 0 : 1

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }

                // Animation container
                Item {
                    id: animationContainer
                    anchors.centerIn: parent
                    width: 24
                    height: 24
                    opacity: acceptSelection.animationRunning ? 1 : 0

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }

                    // Progressive circle drawing
                    Canvas {
                        id: progressCircle
                        anchors.centerIn: parent
                        width: 24
                        height: 24

                        property real progress: 0  // 0 to 1
                        property real radius: 10
                        property real lineWidth: 2

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            if (progress > 0) {
                                var centerX = width / 2;
                                var centerY = height / 2;
                                var startAngle = -Math.PI / 2; // Start from top
                                var endAngle = startAngle + (progress * 2 * Math.PI);

                                ctx.strokeStyle = Color.palette.base07;
                                ctx.lineWidth = lineWidth;
                                ctx.lineCap = "round";

                                // Draw the arc with varying opacity based on position
                                var segments = 36; // Smooth drawing
                                var angleStep = (2 * Math.PI) / segments;
                                var currentProgress = progress * segments;

                                for (var i = 0; i < currentProgress && i < segments; i++) {
                                    var segmentAngle = startAngle + (i * angleStep);
                                    var nextAngle = startAngle + ((i + 1) * angleStep);

                                    // Calculate opacity based on how far around we are
                                    var segmentProgress = i / segments;
                                    var opacity = 1.0;

                                    if (segmentProgress >= 0.25)
                                        opacity = 0.8;
                                    if (segmentProgress >= 0.5)
                                        opacity = 0.6;
                                    if (segmentProgress >= 0.75)
                                        opacity = 0.4;

                                    ctx.globalAlpha = opacity;
                                    ctx.beginPath();
                                    ctx.arc(centerX, centerY, radius, segmentAngle, Math.min(nextAngle, endAngle));
                                    ctx.stroke();
                                }

                                ctx.globalAlpha = 1.0; // Reset for next drawings
                            }
                        }

                        onProgressChanged: requestPaint()
                    }

                    // Checkmark
                    Canvas {
                        id: checkmark
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        opacity: 0

                        property real progress: 0

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            if (progress > 0) {
                                ctx.strokeStyle = Color.palette.base07;
                                ctx.lineWidth = 2.5;
                                ctx.lineCap = "round";
                                ctx.lineJoin = "round";

                                ctx.beginPath();

                                // First stroke of checkmark (short line)
                                if (progress <= 0.5) {
                                    var firstProgress = progress * 2;
                                    ctx.moveTo(4, 8);
                                    ctx.lineTo(4 + (3 * firstProgress), 8 + (3 * firstProgress));
                                } else {
                                    // Complete first stroke
                                    ctx.moveTo(4, 8);
                                    ctx.lineTo(7, 11);

                                    // Second stroke of checkmark (long line)
                                    var secondProgress = (progress - 0.5) * 2;
                                    ctx.lineTo(7 + (5 * secondProgress), 11 - (5 * secondProgress));
                                }

                                ctx.stroke();
                            }
                        }

                        onProgressChanged: requestPaint()
                    }
                }

                // Animation sequence
                SequentialAnimation {
                    id: circleAnimation

                    // Draw the circle progressively with fading opacity
                    NumberAnimation {
                        target: progressCircle
                        property: "progress"
                        from: 0
                        to: 1
                        duration: 800
                        easing.type: Easing.OutQuad
                    }

                    // Brief pause
                    PauseAnimation {
                        duration: 100
                    }

                    // Show and animate checkmark
                    ParallelAnimation {
                        NumberAnimation {
                            target: checkmark
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: 100
                        }

                        NumberAnimation {
                            target: checkmark
                            property: "progress"
                            from: 0
                            to: 1
                            duration: 400
                            easing.type: Easing.OutQuad
                        }
                    }

                    // Wait then call the method and reset
                    PauseAnimation {
                        duration: 200
                    }

                    ScriptAction {
                        script: {
                            background.saveToMusicFolder();

                            // Reset animation state after a delay
                            resetTimer.start();
                        }
                    }
                }

                Timer {
                    id: resetTimer
                    interval: 500
                    onTriggered: {
                        acceptSelection.animationRunning = false;
                        progressCircle.progress = 0;
                        checkmark.opacity = 0;
                        checkmark.progress = 0;
                        buttonText.text = "Upload Complete!";
                    }
                }
            }
        }
        CreateMP3Processor {
            id: tagMP3FileProcess
            onError: error => {
                console.log(error);
            }
        }
        YTDataProcessor {
            id: ytDataProcessor
            property var processing: false
            onDownloading: (percent, info) => {
                const {
                    percentage,
                    title,
                    uploader,
                    audio_path,
                    thumbnail_path
                } = info;
                downloadProgress.updateProgress(percent, title || "Downloading...");
                if (userText != title.trim()) {
                    searchBar.setSearchText(title.trim());
                    searchBar.setInitialCursorPosition();
                }
                if (thumbnail_path.length > 0 && percent == 100) {
                    youtubeThumbnail.source = '/tmp/' + encodeURIComponent(thumbnail_path.replace('/tmp/', ''));
                    tagMP3FileProcess.mp3Path = audio_path;
                    tagMP3FileProcess.albumName = title;
                    tagMP3FileProcess.albumArtist = uploader;
                    tagMP3FileProcess.albumArtPath = thumbnail_path;
                }
            }
            onError: error => {
                console.log(error);
            }
            onFinished: {}
        }
        function triggerDownloadProcess() {
            const currentUrl = root.userText;
            if (currentUrl == "") {
                return;
            }
            downloadProgress.show("Starting download...");
            ytDataProcessor.downloadUrl = currentUrl;
            ytDataProcessor.running = true;
        }
        function saveToMusicFolder() {
            const localPath = tagMP3FileProcess.mp3Path;
            if (localPath?.toString().length > 0) {
                tagMP3FileProcess.running = true;
                return;
            }
        }
    }
}
