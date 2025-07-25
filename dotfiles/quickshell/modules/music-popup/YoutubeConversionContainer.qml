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
            width: parent.width * 0.5
            height: parent.height
            fillMode: Image.PreserveAspectFit
            source: FileConfig.icons.media
            mipmap: true
            layer.enabled: true
            layer.effect: MultiEffect {
                brightness: 1.0
                colorization: 1.0
                colorizationColor: '#efefef'
            }
            visible: !youtubeThumbnail.visible
        }
        ClippingRectangle {
            id: clippingRectangle
            width: parent.width * 0.5
            height: parent.height * 0.5
            y: (parent.height - height) / 2
            x: (parent.width - width) / 2
            color: "transparent"
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
            const localPath = tagMP3FileProcess.mp3Path;
            if (localPath?.toString().length > 0) {
                tagMP3FileProcess.running = true;
                return;
            }
            const currentUrl = root.userText;
            if (currentUrl == "") {
                return;
            }
            ytDataProcessor.downloadUrl = currentUrl;
            ytDataProcessor.running = true;
        }
    }
}
