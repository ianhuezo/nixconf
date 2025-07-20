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
            appName: 'Music 2',
            iconLocation: FileConfig.youtubeConverter,
            selected: false,
            mipmap: true
        }
    ]

    // Get the currently selected index
    property int selectedIndex: {
        for (let i = 0; i < topLevelModel.length; i++) {
            if (topLevelModel[i].selected) {
                return i;
            }
        }
        return 0; // Default to first item
    }

    function moveCarouselPrevious() {
        const currentIndex = selectedIndex;
        const totalItems = topLevelModel.length;
        const prevIndex = (currentIndex - 1 + totalItems) % totalItems;

        // Update selection
        topLevelModel[currentIndex].selected = false;
        topLevelModel[prevIndex].selected = true;

        // Force property binding update
        topLevelModelChanged();
        selectedIndexChanged();
    }

    function moveCarouselNext() {
        const currentIndex = selectedIndex;
        const nextIndex = (currentIndex + 1) % topLevelModel.length;

        // Update selection
        topLevelModel[currentIndex].selected = false;
        topLevelModel[nextIndex].selected = true;

        // Force property binding update
        topLevelModelChanged();
        selectedIndexChanged();
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
            color: 'transparent'

            // Use all items directly - no need for separate carouselModel
            Repeater {
                model: root.topLevelModel

                CarouselItem {
                    // Position all items in the same space - they'll position themselves
                    anchors.centerIn: parent
                    width: narrowedAppChooser.width * 0.3 // Fixed size for each item
                    height: narrowedAppChooser.height

                    // Pass data from model
                    appName: modelData.appName
                    iconLocation: modelData.iconLocation
                    mipmap: modelData.mipmap
                    isSelected: modelData.selected
                    itemIndex: index
                    selectedIndex: root.selectedIndex
                    totalItems: root.topLevelModel.length

                    // Pass styling properties
                    unfocusedScale: root.unfocusedScale
                    carouselRadius: narrowedAppChooser.width * 0.8
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
