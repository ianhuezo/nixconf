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
    signal refreshFocus

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
                triggerDownloadProcess();
                root.refreshFocus();
                break;
            default:
                break;
            }
        }

        Image {
            id: youtubeMediaSvg
            anchors.centerIn: parent
            width: clippingRectangle.width
            height: clippingRectangle.height
            fillMode: Image.PreserveAspectFit
            source: FileConfig.icons.media
            mipmap: true
            layer.enabled: true
            layer.effect: MultiEffect {
                brightness: 1.0
                colorization: 1.0
                colorizationColor: Color.palette.base07
            }
            visible: !youtubeThumbnail.visible
        }
        ProgressIndicator {
            id: downloadProgress

            // Customize appearance if needed
            progressColor: "#4CAF50"
            backgroundColor: "#2a2a2a"
            containerWidth: parent.width * 0.7

            onProgressComplete: {
                console.log("Download completed!");
                // Handle completion if needed
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
            anchors.centerIn: youtubeMediaSvg
            visible: youtubeThumbnail.source.toString().length > 0
            clip: true
            radius: 10

            Image {
                id: youtubeThumbnail
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: ''
                visible: source.toString().length > 0
            }
        }
        Rectangle {
            id: dashedBorderRectangle
            // Use paintedWidth/paintedHeight which represent the actual visible size
            // after PreserveAspectFit is applied
            width: youtubeMediaSvg.paintedWidth * 1.1  // 10% larger than actual visible content
            height: youtubeMediaSvg.paintedHeight * 1.1  // 10% larger than actual visible content

            // Center on the actual painted content, not the entire Image component
            x: youtubeMediaSvg.x + (youtubeMediaSvg.width - youtubeMediaSvg.paintedWidth) / 2 - (width - youtubeMediaSvg.paintedWidth) / 2
            y: youtubeMediaSvg.y + (youtubeMediaSvg.height - youtubeMediaSvg.paintedHeight) / 2 - (height - youtubeMediaSvg.paintedHeight) / 2 + 10
            color: "transparent"
            radius: clippingRectangle.radius + 5  // Slightly larger radius to match the scaling

            border.width: 0  // Remove solid border

            // Create dashed border using Canvas
            Canvas {
                id: dashedBorder
                anchors.fill: parent
                visible: tagMP3FileProcess.albumArtPath.length == 0

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    // Set dash pattern - long dashes with spacing
                    ctx.setLineDash([15, 8]);  // 15px dash, 8px gap
                    ctx.strokeStyle = Color.palette.base07;
                    ctx.lineWidth = 2;

                    // Draw rounded rectangle border
                    var x = ctx.lineWidth / 2;
                    var y = ctx.lineWidth / 2;
                    var w = width - ctx.lineWidth;
                    var h = height - ctx.lineWidth;
                    var r = parent.radius;

                    ctx.beginPath();
                    ctx.moveTo(x + r, y);
                    ctx.lineTo(x + w - r, y);
                    ctx.quadraticCurveTo(x + w, y, x + w, y + r);
                    ctx.lineTo(x + w, y + h - r);
                    ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
                    ctx.lineTo(x + r, y + h);
                    ctx.quadraticCurveTo(x, y + h, x, y + h - r);
                    ctx.lineTo(x, y + r);
                    ctx.quadraticCurveTo(x, y, x + r, y);
                    ctx.closePath();
                    ctx.stroke();
                }

                // Repaint when visibility changes
                Connections {
                    target: dashedBorderRectangle
                    function onVisibleChanged() {
                        if (dashedBorderRectangle.visible) {
                            dashedBorder.requestPaint();
                        }
                    }
                }
            }
        }
        CreateMP3Processor {
            id: tagMP3FileProcess
            onError: error => {
                console.log(error);
                downloadProgress.hide();
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
                if (userText != title.trim()) {
                    searchBar.setSearchText(title.trim());
                    searchBar.setInitialCursorPosition();
                }
                if (thumbnail_path.length > 0 && percent == 100) {
                    youtubeThumbnail.source = '/tmp/' + encodeURIComponent(thumbnail_path.replace('/tmp/', ''));

                    downloadProgress.hide();
                    tagMP3FileProcess.mp3Path = audio_path;
                    tagMP3FileProcess.albumName = title;
                    tagMP3FileProcess.albumArtist = uploader;
                    tagMP3FileProcess.albumArtPath = thumbnail_path;
                }
            }
            onError: error => {
                console.log(error);
                downloadProgress.hide();
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
