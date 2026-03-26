import QtQuick
import qs.config
import qs.services
import "root:/components"

Rectangle {
    id: root

    property string filePath: ""
    signal copyRequested(string path)
    signal deleteRequested(string path)

    readonly property string fileName: {
        const parts = filePath.split("/");
        return parts[parts.length - 1] || "";
    }

    readonly property string displayTime: {
        const m = fileName.match(/screenshot_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})/);
        if (m) return m[4] + ":" + m[5] + "  " + m[2] + "/" + m[3] + "/" + m[1];
        return fileName.replace(".png", "");
    }

    height: 76
    radius: AppearanceConfig.radius.md
    color: cardHover.containsMouse ? Color.palette.base02 : Color.palette.base01
    border.width: 1
    border.color: Color.palette.base03

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    MouseArea {
        id: cardHover
        anchors.fill: parent
        hoverEnabled: true
        // Pass through clicks to child elements
        propagateComposedEvents: true
        onClicked: mouse => mouse.accepted = false
    }

    // Thumbnail
    Rectangle {
        id: thumbnailContainer
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: 8
            topMargin: 8
            bottomMargin: 8
        }
        width: height * (16 / 9)
        radius: AppearanceConfig.radius.sm
        color: Color.palette.base02
        clip: true

        Image {
            id: thumbnail
            anchors.fill: parent
            source: root.filePath.length > 0 ? ("file://" + root.filePath) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
            mipmap: true
        }

        // Placeholder while loading
        Rectangle {
            anchors.fill: parent
            color: Color.palette.base02
            visible: thumbnail.status !== Image.Ready
            radius: parent.radius

            Text {
                anchors.centerIn: parent
                text: "⎙"
                color: Color.palette.base04
                font.pixelSize: 18
            }
        }
    }

    // Info column
    Column {
        anchors {
            left: thumbnailContainer.right
            right: actionButtons.left
            verticalCenter: parent.verticalCenter
            leftMargin: 10
            rightMargin: 6
        }
        spacing: 4

        Text {
            width: parent.width
            text: root.displayTime
            color: Color.palette.base05
            font.pixelSize: AppearanceConfig.font.size.sm
            font.family: AppearanceConfig.font.mono
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: root.fileName
            color: Color.palette.base04
            font.pixelSize: AppearanceConfig.font.size.xs
            font.family: AppearanceConfig.font.mono
            elide: Text.ElideRight
        }
    }

    // Action buttons
    Row {
        id: actionButtons
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: 8
        }
        spacing: 4

        IconButton {
            iconText: "⎘"
            iconSize: 15
            implicitHeight: 32
            implicitWidth: 32
            tooltip: "Copy to clipboard"
            toolTipContainer: root
            onClicked: root.copyRequested(root.filePath)
        }

        IconButton {
            iconText: "✕"
            iconSize: 13
            implicitHeight: 32
            implicitWidth: 32
            iconColor: Color.palette.base08
            tooltip: "Delete"
            toolTipContainer: root
            onClicked: root.deleteRequested(root.filePath)
        }
    }
}
