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
    property real panelWidth: parentId.implicitWidth
    property real panelHeight: parentId.implicitHeight
    property real slideY: 99999
    color: 'transparent'

    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: currentWlrLayer
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: 0

    onVisibleChanged: {
        if (root.visible) {
            contentItem.forceActiveFocus();
        }
    }

    signal closeRequested

    function requestClose() {
        closeAnimation.start();
    }

    Connections {
        target: root.parentId
        function onClosingChanged() {
            if (root.parentId.closing) {
                root.requestClose();
            }
        }
    }

    onHeightChanged: {
        if (root.height > 0 && !openAnimation.running && slideY >= root.height) {
            slideY = root.height;
            openAnimation.start();
        }
    }

    NumberAnimation {
        id: openAnimation
        target: root
        property: "slideY"
        to: 0
        duration: 700
        easing.type: Easing.Bezier
        // OutExpo: snaps to position fast, long silky deceleration tail
        easing.bezierCurve: [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
    }

    SequentialAnimation {
        id: closeAnimation
        NumberAnimation {
            target: root
            property: "slideY"
            to: root.height
            duration: 420
            easing.type: Easing.Bezier
            // InExpo: holds briefly then exits decisively
            easing.bezierCurve: [0.7, 0.0, 0.84, 0.0, 1.0, 1.0]
        }
        ScriptAction {
            script: root.closeRequested()
        }
    }

    Component {
        id: appViewerComponent
        AppViewer {
            id: mainAppViewer
            onAppSelected: {
                root.requestClose();
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
        width: root.panelWidth
        height: root.panelHeight
        anchors.centerIn: parent
        transform: Translate { y: root.slideY }
        focus: true
        Keys.onEscapePressed: root.requestClose()
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
