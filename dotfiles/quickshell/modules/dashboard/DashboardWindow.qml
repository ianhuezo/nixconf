import Quickshell
import QtQuick
import Quickshell.Wayland
import QtQuick.Layouts
import "root:/config"
import "root:/services"
import "root:/modules/music-popup"

PanelWindow {
    id: root
    property var modelData
    required property var parentId
    property var windowProperty
    color: 'transparent'
    implicitWidth: parentId.implicitWidth
    implicitHeight: parentId.implicitHeight

    WlrLayershell.layer: WlrLayer.Overlay
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
        Keys.onPressed: event => {
            let activeComponent = null;
            switch (event.key) {
            case Qt.Key_Left:
                // Check the currently active loader's component for text
                if (appLoader.componentType === "Applications" && appViewerLoader.item) {
                    activeComponent = appViewerLoader.item;
                } else if (appLoader.componentType === "Youtube Converter" && youtubeLoader.item) {
                    activeComponent = youtubeLoader.item;
                }

                if (activeComponent && activeComponent.userText && activeComponent.userText.length > 0) {
                    event.accepted = false;
                    return;
                }

                appChooserContainer.forceActiveFocus();
                appChooserContainer.moveCarouselPrevious();

                // Restore focus to the active component after navigation
                Qt.callLater(function () {
                    if (activeComponent) {
                        activeComponent.forceActiveFocus();
                    }
                });

                event.accepted = true;
                break;
            case Qt.Key_Right:
                // Similar logic for right key
                if (appLoader.componentType === "Applications" && appViewerLoader.item) {
                    activeComponent = appViewerLoader.item;
                } else if (appLoader.componentType === "Youtube Converter" && youtubeLoader.item) {
                    activeComponent = youtubeLoader.item;
                }

                if (activeComponent && activeComponent.userText && activeComponent.userText.length > 0) {
                    event.accepted = false;
                    return;
                }

                appChooserContainer.forceActiveFocus();
                appChooserContainer.moveCarouselNext();

                // Restore focus to the active component after navigation
                Qt.callLater(function () {
                    if (activeComponent) {
                        activeComponent.forceActiveFocus();
                    }
                });

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
            AppChooser {
                id: appChooserContainer
                onAppRequested: appName => {
                    appLoader.componentType = appName;
                }
            }

            Rectangle {
                id: mainApplication
                color: 'transparent'
                height: parent.height - appChooserContainer.height
                width: parent.width - splashPanel.width
                y: parent.y + appChooserContainer.height
                bottomLeftRadius: mainDrawArea.radius
                Item {
                    id: appLoader
                    property string componentType: "Applications"
                    anchors.fill: parent

                    // Add this to manage focus when componentType changes
                    onComponentTypeChanged: {
                        Qt.callLater(function () {
                            if (componentType === "Applications" && appViewerLoader.item) {
                                appViewerLoader.item.forceActiveFocus();
                            } else if (componentType === "Youtube Converter" && youtubeLoader.item) {
                                youtubeLoader.item.forceActiveFocus();
                            }
                        });
                    }

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

                        onItemChanged: {
                            if (item && visible) {
                                Qt.callLater(function () {
                                    item.forceActiveFocus();
                                });
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

                        onItemChanged: {
                            if (item && visible) {
                                Qt.callLater(function () {
                                    item.forceActiveFocus();
                                });
                            }
                        }
                    }
                }
            }
        }
    }
}
