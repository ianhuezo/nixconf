import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Effects
import "root:/modules/dashboard"

FocusScope {
    id: root
    anchors.fill: parent
    focus: true  // Important: Enable focus for the FocusScope

    property string userText: ''

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
    }
}

// Rectangle {
//     id: imageUploadedArea
//     width: parent.width
//     height: parent.height * 0.5
//     radius: parent.radius
//     color: 'transparent'
//     y: parent.y + 8
//
//     Image {
//         id: youtubeMediaSvg
//         anchors.centerIn: parent
//         width: parent.width
//         height: parent.height
//         fillMode: Image.PreserveAspectFit
//         source: '../assets/icons/media.svg'
//         layer.enabled: true
//         layer.effect: MultiEffect {
//             brightness: 1.0
//             colorization: 1.0
//             colorizationColor: '#efefef'
//         }
//         visible: !youtubeThumbnail.visible
//     }
//
//     Rectangle {
//         id: clippingRectangle
//         width: 150
//         height: 150
//         y: (parent.height - height) / 2
//         x: (parent.width - width) / 2
//         color: "transparent"
//         visible: youtubeThumbnail.source.toString().length > 0
//         clip: true
//
//         Image {
//             id: youtubeThumbnail
//             anchors.fill: parent
//             fillMode: Image.PreserveAspectCrop
//             source: ''
//             visible: source.toString().length > 0
//         }
//     }
// }

// Rectangle {
//     id: imageTextInputs
//     width: parent.width
//     color: 'transparent'
//     y: imageUploadedArea.y + imageUploadedArea.height + 8
//     height: parent.height * 0.5
//     radius: parent.radius
//
//     Rectangle {
//         id: textInputBottom
//         width: parent.width * 0.8
//         height: 2
//         radius: 1
//         x: parent.x + (parent.width - textInputBottom.width) / 2
//         y: parent.height * 0.2 + 4
//         color: '#E8E8E8'
//     }
//
//     Rectangle {
//         id: textInputBox
//         height: parent.height * 0.2 + 4
//         width: textInputBottom.width
//         x: textInputBottom.x
//         color: 'transparent'
//
//         TextField {
//             id: textInput
//             placeholderText: qsTr("Add Link...")
//             placeholderTextColor: '#828282'
//             anchors.fill: parent
//             text: ''
//             readOnly: false
//             color: 'white'
//
//             // Handle focus when clicked
//             MouseArea {
//                 anchors.fill: parent
//                 onClicked: {
//                     textInput.forceActiveFocus();
//                 }
//                 // Let the TextField handle the actual text input
//                 propagateComposedEvents: true
//                 acceptedButtons: Qt.NoButton
//             }
//
//             background: Rectangle {
//                 color: '#1e262e'
//                 radius: 5
//             }
//         }
//     }
//
//     Button {
//         id: convertButton
//         x: Math.round(textInputBottom.x)
//         y: Math.round(textInputBottom.y + textInputBottom.height + 8)
//         width: Math.round(textInputBottom.width)
//         height: Math.round(textInputBox.height)
//
//         text: youtubeThumbnail.source.toString().length > 0 ? "Add to Library" : "Convert to MP3"
//
//         font {
//             family: "Helvetica"
//             pixelSize: 14
//             bold: true
//         }
//
//         MouseArea {
//             anchors.fill: parent
//             hoverEnabled: true
//             cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
//             acceptedButtons: Qt.NoButton
//         }
//
//         onClicked: {
//             const localPath = tagMP3FileProcess.mp3Path;
//             if (localPath?.toString().length > 0) {
//                 tagMP3FileProcess.running = true;
//                 return;
//             }
//             const currentUrl = textInput.text;
//             if (currentUrl == "") {
//                 return;
//             }
//             ytDataProcessor.downloadUrl = currentUrl;
//             ytDataProcessor.running = true;
//         }
//
//         CreateMP3Processor {
//             id: tagMP3FileProcess
//             onError: error => {
//                 console.log(error);
//             }
//         }
//
//         YTDataProcessor {
//             id: ytDataProcessor
//             onDownloading: (percent, info) => {
//                 const {
//                     percentage,
//                     title,
//                     uploader,
//                     audio_path,
//                     thumbnail_path
//                 } = info;
//
//                 if (thumbnail_path.length > 0 && percent == 100) {
//                     youtubeThumbnail.source = '/tmp/' + encodeURIComponent(thumbnail_path.replace('/tmp/', ''));
//                     textInput.text = title;
//                     textInput.readOnly = true;
//                     tagMP3FileProcess.mp3Path = audio_path;
//                     tagMP3FileProcess.albumName = title;
//                     tagMP3FileProcess.albumArtist = uploader;
//                     tagMP3FileProcess.albumArtPath = thumbnail_path;
//                 }
//             }
//             onError: error => {
//                 console.log(error);
//             }
//             onFinished: {}
//         }
//
//         palette.buttonText: "#E8E8E8"
//
//         contentItem: Text {
//             text: convertButton.text
//             font: convertButton.font
//             color: convertButton.palette.buttonText
//             horizontalAlignment: Text.AlignHCenter
//             verticalAlignment: Text.AlignVCenter
//             renderType: Text.NativeRendering
//             antialiasing: true
//         }
//
//         background: Rectangle {
//             color: youtubeThumbnail.source.toString().length > 0 ? '#2da3a9' : "#7AA2F7"
//             radius: imageTextInputs.radius
//         }
//     }
//
//     Button {
//         id: cancelButton
//         width: convertButton.width
//         x: convertButton.x
//         y: convertButton.y + convertButton.height + 8
//         height: convertButton.height
//
//         text: "Cancel"
//         font: convertButton.font
//         enabled: youtubeThumbnail.source.toString().length > 0
//         palette.buttonText: youtubeThumbnail.source.toString().length > 0 ? '#F7768E' : 'gray'
//
//         background: Rectangle {
//             border.color: youtubeThumbnail.source.toString().length > 0 ? '#F7768E' : 'gray'
//             border.width: 2
//             radius: imageTextInputs.radius
//             color: 'transparent'
//         }
//
//         MouseArea {
//             anchors.fill: parent
//             hoverEnabled: true
//             cursorShape: containsMouse ? Qt.PointingHandCursor : Qt.ArrowCursor
//             acceptedButtons: Qt.NoButton
//         }
//
//         onClicked: {
//             youtubeThumbnail.source = '';
//             textInput.text = '';
//             textInput.horizontalAlignment = Text.AlignLeft;
//             textInput.readOnly = false;
//             tagMP3FileProcess.mp3Path = '';
//             tagMP3FileProcess.albumName = '';
//             tagMP3FileProcess.albumArtist = '';
//             tagMP3FileProcess.albumArtPath = '';
//
//             // Return focus to search bar after cancel
//             Qt.callLater(function () {
//                 searchBar.forceActiveFocus();
//             });
//         }
//
//         contentItem: Text {
//             text: cancelButton.text
//             font: cancelButton.font
//             color: cancelButton.palette.buttonText
//             horizontalAlignment: Text.AlignHCenter
//             verticalAlignment: Text.AlignVCenter
//             renderType: Text.NativeRendering
//         }
//     }
// }
// }

// Add methods for external focus control
// function focusSearchBar() {
//     searchBar.forceActiveFocus();
// }
//
// function focusTextInput() {
//     textInput.forceActiveFocus();
// }
//
// // Key navigation between the two inputs
// Keys.onTabPressed: {
//     if (searchBar.activeFocus) {
//         textInput.forceActiveFocus();
//     } else if (textInput.activeFocus) {
//         searchBar.forceActiveFocus();
//     }
// }
//
// Component.onCompleted: {
//     // Give initial focus to search bar
//     Qt.callLater(function () {
//         searchBar.forceActiveFocus();
//     });
// }
// }

