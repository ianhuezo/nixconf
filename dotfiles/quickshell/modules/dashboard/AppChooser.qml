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
        carouselModelChanged();
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
        carouselModelChanged();
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

            Row {
                anchors.fill: parent

                Repeater {
                    model: carouselModel
                    CarouselItem {
                        width: (parent.width - (root.carouselModel.length - 1) * parent.spacing) / root.carouselModel.length
                        height: parent.height

                        // Pass data from model
                        appName: modelData.appName
                        iconLocation: modelData.iconLocation
                        mipmap: modelData.mipmap
                        isSelected: modelData.selected
                        itemIndex: index
                        selectedIndex: 1 // Always the middle item in your 3-item carousel

                        // Pass styling properties
                        unfocusedScale: root.unfocusedScale
                        textColor: Color.palette.base07
                        underlineColor: Color.palette.base08
                        fontFamily: 'JetBrains Mono Nerd Font'
                        fontSize: 18
                        fontWeight: 500
                    }
                }
            }
        }
    }
}
