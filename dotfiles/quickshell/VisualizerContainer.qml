import QtQuick
import QtQuick.Layouts
import Quickshell
import QtQuick.Controls

Rectangle {
    id: container
    property var cavaValues: []
    property bool useCanvas: true
    property color waveColor: 'white'
    property color barColor: 'black'
    property var togglePopup: false
    signal toggleVisualization
    signal toggleMusicDownloader

    color: barColor
    width: 166
    height: 32

    Row {
        anchors.centerIn: parent
        height: parent.height
        width: Math.min(parent.width, implicitWidth)

        Item {
            id: imageButton
            width: parent.height
            height: parent.height
            NowPlayingArt {
                height: parent.height
                width: parent.width
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    togglePopup = !togglePopup;
                    popupLoader.active = togglePopup;
                }
            }
        }

        Item {
            id: vizContainer
            height: parent.height
            width: loader.width

            Loader {
                id: loader
                sourceComponent: container.useCanvas ? waveComponent : barComponent
                height: parent.height
                width: 166
            }

            MouseArea {
                anchors.fill: parent
                onClicked: container.toggleVisualization()
            }
        }
    }
    LazyLoader {
        id: popupLoader

        PanelWindow {
            id: downloaderPopup
            anchors {
                top: true
                right: true
                left: true
                bottom: true
            }
            color: 'transparent'
            height: container.height
            visible: popupLoader.active

            PopupWindow {
                id: popupWindow
                anchor.window: downloaderPopup
                anchor.rect.x: container.width / 2 - width / 2
                anchor.rect.y: {
                    console.log(downloaderPopup.height);
                    console.log(container.height);
                    return downloaderPopup.y - container.height;
                }
                width: 500
                height: 500
                visible: popupLoader.active

                Rectangle {
                    anchors.fill: parent
                    x: parent.x
                    y: parent.y
                    border.color: 'black'
                    color: '#171D23'
                }
            }

            MouseArea {
                id: mouseEntireScreen
                anchors.fill: parent

                onClicked: event => {
                    var popupX = popupWindow.anchor.rect.x;
                    var popupY = popupWindow.anchor.rect.y;
                    var popupWidth = popupWindow.width;
                    var popupHeight = popupWindow.height;

                    // Check if the click is inside the popup's bounds
                    var isInsidePopup = (mouseEntireScreen.x >= popupX && mouseEntireScreen.x <= popupX + popupWidth && mouseEntireScreen.y >= popupY && mouseEntireScreen.y <= popupY + popupHeight);

                    // Close the popup if the click is outside
                    if (!isInsidePopup) {
                        togglePopup = false;
                        popupLoader.active = false;
                    }
                }
            }
        }
    }

    Component {
        id: waveComponent
        WaveVisualizer {
            cavaValues: container.cavaValues
            waveColor: container.waveColor
            height: parent.height
        }
    }

    Component {
        id: barComponent
        BarsVisualizer {
            cavaValues: container.cavaValues
            barColor: container.waveColor
            height: parent.height
        }
    }
}
