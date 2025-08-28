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
    color: 'transparent'
    implicitWidth: parentId.implicitWidth
    implicitHeight: parentId.implicitHeight

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: 0

    onVisibleChanged: {
        if (root.visible) {
            contentItem.forceActiveFocus();
        }
    }

    signal closeRequested

    Item {
        id: contentItem
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closeRequested()
        function isSearchBarActiveForComponent() {
            let activeComponent = null;
            if (appLoader.componentType === "Applications" && appViewerLoader.item) {
                activeComponent = appViewerLoader.item;
            } else if (appLoader.componentType === "Youtube Converter" && youtubeLoader.item) {
                activeComponent = youtubeLoader.item;
            }
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

            SplashPanel {
                id: splashPanel
            }
            Carousel {
                id: appCarousel
                onAppRequested: appName => {
                    appLoader.componentType = appName;
                }
                containerBottomMargin: 32
            }

            Rectangle {
                id: mainApplication
                color: 'transparent'
                height: parent.height - appCarousel.height
                width: parent.width - splashPanel.width
                y: parent.y + appCarousel.height + appCarousel.containerBottomMargin
                bottomLeftRadius: mainDrawArea.radius
                Item {
                    id: appLoader
                    property string componentType: "Applications"
                    anchors.fill: parent

                    Loader {
                        id: appViewerLoader
                        anchors.fill: parent
                        visible: appLoader.componentType === "Applications"
                        active: visible || appLoader.componentType === "Applications"

                        sourceComponent: Component {
                            AppViewer {
                                id: mainAppViewer
                                onAppSelected: {
                                    root.closeRequested();
                                }
                            }
                        }
                    }

                    Loader {
                        id: youtubeLoader
                        anchors.fill: parent
                        visible: appLoader.componentType === "Youtube Converter"
                        active: visible || appLoader.componentType === "Youtube Converter"

                        sourceComponent: Component {
                            YoutubeConversionContainer {
                                id: youtubeConverter
                            }
                        }
                    }

                    Loader {
                        id: desktopThemes
                        anchors.fill: parent
                        visible: appLoader.componentType === "Desktop Theme Creator"
                        active: visible || appLoader.componentType === "Desktop Theme Creator"

                        sourceComponent: Component {
                            Theme {
                                id: themePicker
                            }
                        }
                    }
                }
            }
        }
    }
}
