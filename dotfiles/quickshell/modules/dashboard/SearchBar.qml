import Quickshell
import QtQuick
import QtQuick.Controls
import "root:/config"
import "root:/services"

Rectangle {
    id: searchBarContainer
    property var leftMargin: parent.width * 0.1
    property var topMargin: parent.height * 0.05
    property var containerHeight: parent.height * 0.1
    property var containerWidth: parent.width * 0.8
    property string currentText: ''

    signal searchText(string text)

    width: containerWidth
    x: leftMargin + parent.x
    y: parent.y + topMargin
    height: containerHeight
    radius: 10
    color: Color.palette.base03//'#1e262e'
    Text {
        id: searchIcon
        text: "⚲"
        color: Color.palette.base04//'#828282'
        font.pixelSize: parent.height * 0.4
        anchors.left: parent.left
        anchors.leftMargin: parent.width * 0.03
        anchors.verticalCenter: parent.verticalCenter
        rotation: 45
    }
    TextField {
        id: textInput
        placeholderText: qsTr("Search Applications...")
        placeholderTextColor: Color.palette.base04//'#828282'
        onFocusChanged: {
            textInput.forceActiveFocus();
        }
        anchors.fill: parent
        anchors.leftMargin: searchIcon.width + parent.width * 0.04
        width: parent.width
        height: parent.height
        font.family: 'JetBrains Mono Nerd Font'
        font.weight: 400
        font.pixelSize: 16
        text: ''
        readOnly: false
        color: Color.palette.base07
        onTextChanged: {
            searchBarContainer.searchText(textInput.text);
        }

        cursorDelegate: Rectangle {
            width: 1
            height: textInput.font.pixelSize
            color: Color.palette.base07
            visible: textInput.activeFocus

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
            color: Color.palette.base03//'#1e262e'
            radius: 10
        }
        Component.onCompleted: {
            textInput.forceActiveFocus();
        }
    }
}
