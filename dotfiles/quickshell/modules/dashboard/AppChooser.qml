import QtQuick
import "root:/config"
import "root:/services"

Item {
    id: root
    anchors.top: parent.top
    height: parent.height * 0.2
    width: parent.width * 0.8
    signal appRequested(var appName)
    readonly property var unfocusedScale: 0.6
    readonly property var topLevelModel: [
        {
            appName: 'Applications',
            iconLocation: FileConfig.dashboardAppLauncher,
            selected: true,
            mipmap: false
        },
        {
            appName: 'Youtube Convert',
            iconLocation: FileConfig.youtubeConverter,
            selected: false,
            mipmap: true
        },
        {
            appName: 'Music',
            iconLocation: FileConfig.youtubeConverter,
            selected: false,
            mipmap: true
        },
        {
            appName: 'Music',
            iconLocation: FileConfig.youtubeConverter,
            selected: false,
            mipmap: true
        }
    ]

    property var carouselModel: {
        // Find the selected item index in topLevelModel
        let selectedIndex = -1;
        for (let i = 0; i < root.topLevelModel.length; i++) {
            if (root.topLevelModel[i].selected) {
                selectedIndex = i;
                break;
            }
        }

        if (selectedIndex === -1)
            return []; // No selected item found

        // Get previous, current, and next items (with wrapping)
        const totalItems = root.topLevelModel.length;
        const prevIndex = (selectedIndex - 1 + totalItems) % totalItems;
        const nextIndex = (selectedIndex + 1) % totalItems;

        return [root.topLevelModel[prevIndex], root.topLevelModel[selectedIndex], root.topLevelModel[nextIndex]];
    }
    function moveCarouselPrevious() {
        // Find current selected index
        let currentIndex = -1;
        for (let i = 0; i < root.topLevelModel.length; i++) {
            if (root.topLevelModel[i].selected) {
                currentIndex = i;
                break;
            }
        }

        if (currentIndex === -1)
            return;

        // Calculate previous index with wrapping
        const totalItems = root.topLevelModel.length;
        const prevIndex = (currentIndex - 1 + totalItems) % totalItems;

        // Update selection
        root.topLevelModel[currentIndex].selected = false;
        root.topLevelModel[prevIndex].selected = true;
    }
    function moveCarouselNext() {
        // Find current selected index
        let currentIndex = -1;
        for (let i = 0; i < root.topLevelModel.length; i++) {
            if (root.topLevelModel[i].selected) {
                currentIndex = i;
                break;
            }
        }

        if (currentIndex === -1)
            return;

        // Calculate next index with wrapping
        const nextIndex = (currentIndex + 1) % root.topLevelModel.length;

        // Update selection
        root.topLevelModel[currentIndex].selected = false;
        root.topLevelModel[nextIndex].selected = true;
    }

    Rectangle {
        id: appChooserContainer
        color: 'transparent'
        anchors.fill: parent

        Rectangle {
            id: narrowedAppChooser
            implicitWidth: root.width * 0.86
            implicitHeight: root.height * 0.9
            x: parent.x + root.width * 0.075
            y: parent.y + root.height * 0.15
            // implicitHeight:

            color: 'transparent'
            // border.color: 'purple'
            // border.width: 1

            Row {
                anchors.fill: parent
                // anchors.margins: 2
                // spacing: 2

                Repeater {
                    model: carouselModel
                    Rectangle {
                        id: app
                        width: (parent.width - (root.carouselModel.length - 1) * parent.spacing) / root.carouselModel.length
                        height: parent.height
                        color: 'transparent'

                        // Transform properties for carousel effect
                        property bool isSelected: modelData.selected
                        property int itemIndex: index
                        property int selectedIndex: 1 // Always the middle item in our 3-item carousel

                        // In a 3-item carousel, the selected item is always at index 1
                        property int relativePosition: itemIndex - 1

                        // Scale and offset calculations
                        property real targetScale: isSelected ? 1.0 : root.unfocusedScale
                        property real targetYOffset: isSelected ? 0 : height * 0.1
                        property real targetXOffset: {
                            if (isSelected)
                                return 0;
                            return relativePosition < 0 ? -width * 0.05 : width * 0.05;
                        }

                        transform: [
                            Scale {
                                id: scaleTransform
                                origin.x: app.width / 2
                                origin.y: app.height / 2
                                xScale: app.targetScale
                                yScale: app.targetScale

                                Behavior on xScale {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on yScale {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            },
                            Translate {
                                id: translateTransform
                                x: app.targetXOffset
                                y: app.targetYOffset

                                Behavior on x {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }

                                Behavior on y {
                                    NumberAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            }
                        ]

                        // Optional: Add opacity fade for non-selected items
                        opacity: isSelected ? 1.0 : 0.7

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }

                        Rectangle {
                            id: appIcon
                            width: parent.width
                            height: parent.height * 0.75
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            color: 'transparent'
                            Image {
                                anchors.centerIn: parent
                                source: modelData.iconLocation
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                antialiasing: true
                                mipmap: modelData.mipmap
                                sourceSize.width: width
                                sourceSize.height: height
                            }
                        }
                        Rectangle {
                            id: appTextContainer
                            property var underlineMargin: 2
                            width: parent.width
                            height: parent.height * 0.25
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            color: 'transparent'
                            Text {
                                id: appText
                                anchors.centerIn: parent
                                text: modelData.appName
                                font.family: 'JetBrains Mono Nerd Font'
                                font.weight: 500
                                font.pixelSize: 18
                                color: Color.palette.base07
                            }
                            Rectangle {
                                id: appUnderliner
                                width: appText.width * 0.75
                                x: appText.x + 0.15 * width
                                height: 5
                                y: appText.y + appText.height + appTextContainer.underlineMargin
                                radius: 3
                                color: modelData.selected ? Color.palette.base08 : 'transparent'

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                        easing.type: Easing.OutCubic
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
