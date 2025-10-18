import Quickshell
import QtQuick
import Quickshell.Wayland
import qs.config
import qs.services
import "root:/modules/music_popup"
import qs.modules.dashboard.ThemeViewer

PanelWindow {
    id: root
    property var modelData
    required property var parentId
    property var windowProperty
    property var currentWlrLayer: WlrLayer.Top
    color: 'transparent'
    implicitWidth: parentId.implicitWidth
    implicitHeight: parentId.implicitHeight

    WlrLayershell.layer: currentWlrLayer
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: 0

    onVisibleChanged: {
        if (root.visible) {
            contentItem.forceActiveFocus();
        }
    }

    signal closeRequested

    Component {
        id: appViewerComponent
        AppViewer {
            id: mainAppViewer
            onAppSelected: {
                root.closeRequested();
            }
        }
    }

    Component {
        id: youtubeComponent
        YoutubeConversionContainer {
            id: youtubeConverter
        }
    }

    Component {
        id: themeComponent
        Theme {
            id: themePicker

            onFolderOpen: isOpen => {
                console.log(isOpen);
                root.currentWlrLayer = isOpen ? WlrLayer.Bottom : WlrLayer.Top;
            }
        }
    }

    property var carouselModel: [
        {
            appName: 'Applications',
            iconLocation: FileConfig.dashboardAppLauncher,
            selected: true,
            mipmap: false,
            loaderComponent: appViewerComponent
        },
        {
            appName: 'Youtube Converter',
            iconLocation: FileConfig.youtubeConverter,
            selected: false,
            mipmap: true,
            loaderComponent: youtubeComponent
        },
        {
            appName: 'Desktop Theme Creator',
            iconLocation: FileConfig.themeChooser,
            selected: false,
            mipmap: true,
            loaderComponent: themeComponent
        }
    ]

    // Get the currently selected app data
    property var selectedApp: {
        for (let i = 0; i < carouselModel.length; i++) {
            if (carouselModel[i].selected) {
                return carouselModel[i];
            }
        }
        return carouselModel[0];
    }

    Item {
        id: contentItem
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closeRequested()
        function isSearchBarActiveForComponent() {
            let activeComponent = appLoader.item;
            return activeComponent && activeComponent.userText && activeComponent.userText.length > 0;
        }
        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Left:
                if (isSearchBarActiveForComponent()) {
                    event.accepted = false;
                    return;
                }
                appCarousel.moveCarouselPrevious();
                event.accepted = true;
                break;
            case Qt.Key_Right:
                if (isSearchBarActiveForComponent()) {
                    event.accepted = false;
                    return;
                }
                appCarousel.moveCarouselNext();
                event.accepted = true;
                break;
            default:
                break;
            }
        }
        Rectangle {
            id: mainDrawArea
            anchors.fill: parent
            color: Color.palette.base00
            radius: 20
            border.width: 1
            border.color: Color.palette.base09

            SplashPanel {
                id: splashPanel
            }
            Carousel {
                id: appCarousel
                topLevelModel: root.carouselModel
                containerBottomMargin: 32
                onSelectionChanged: newIndex => {
                    // Create a new array with updated selection
                    root.carouselModel = root.carouselModel.map((item, i) => {
                        return {
                            appName: item.appName,
                            iconLocation: item.iconLocation,
                            mipmap: item.mipmap,
                            loaderComponent: item.loaderComponent,
                            selected: i === newIndex
                        };
                    });
                }
            }

            Rectangle {
                id: mainApplication
                color: 'transparent'
                height: parent.height - appCarousel.height
                width: parent.width - splashPanel.width
                y: parent.y + appCarousel.height + appCarousel.containerBottomMargin
                bottomLeftRadius: mainDrawArea.radius
                Loader {
                    id: appLoader
                    anchors.fill: parent
                    sourceComponent: root.selectedApp.loaderComponent
                }
            }
        }
    }
}
