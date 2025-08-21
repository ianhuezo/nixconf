import Quickshell
import QtQuick
import QtQuick.Controls
import qs.config
import qs.services

FocusScope {
    id: searchBarContainer
    property var leftMargin: parent.width * 0.1
    property var containerHeight: parent.height * 0.1
    property var containerWidth: parent.width * 0.8
    property string currentText: ''
    property string placeholderText: "Search Applications..."
    property bool readOnly: false
    property string icon: "⚲"
    property int iconRotation: 45
    property int iconSize: 20
    signal searchText(string text)

    function setSearchText(text: string) {
        textInput.text = text;
    }
    function setInitialCursorPosition() {
        textInput.cursorPosition = 0;
    }

    width: containerWidth
    x: leftMargin + parent.x
    y: parent.y
    height: containerHeight
    focus: true  // Important!

    Rectangle {
        id: background
        anchors.fill: parent
        radius: 10
        color: Color.palette.base03

        Text {
            id: searchIcon
            text: searchBarContainer.icon
            color: Color.palette.base04
            font.pixelSize: searchBarContainer.iconSize
            width: searchBarContainer.iconSize
            height: searchBarContainer.iconSize
            anchors.left: parent.left
            anchors.leftMargin: parent.width * 0.03
            anchors.verticalCenter: parent.verticalCenter
            rotation: searchBarContainer.iconRotation
        }

        TextField {
            id: textInput
            placeholderText: qsTr(searchBarContainer.placeholderText)
            placeholderTextColor: Color.palette.base04

            anchors.fill: parent
            anchors.leftMargin: searchIcon.width + parent.width * 0.04

            font.family: 'JetBrains Mono Nerd Font'
            font.weight: 400
            font.pixelSize: 16
            text: ''
            readOnly: searchBarContainer.readOnly
            color: Color.palette.base07
            focus: true  // Important!

            onTextChanged: {
                searchBarContainer.searchText(textInput.text);
            }

            cursorDelegate: Rectangle {
                width: 1
                height: textInput.contentHeight || textInput.font.pixelSize
                color: Color.palette.base07
                visible: textInput.activeFocus && !searchBarContainer.readOnly
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: textInput.activeFocus
                    PropertyAnimation {
                        to: 1.0
                        duration: 500
                    }
                    PropertyAnimation {
                        to: 0.0
                        duration: 500
                    }
                }
            }

            background: Rectangle {
                color: Color.palette.base03
                radius: 10
            }
        }
    }

    Component.onCompleted: {
        // Use Qt.callLater to ensure proper focus timing
        Qt.callLater(function () {
            searchBarContainer.forceActiveFocus();
        });
    }
}
