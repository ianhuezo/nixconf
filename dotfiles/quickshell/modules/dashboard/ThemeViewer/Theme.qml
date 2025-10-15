import QtQuick
import Quickshell.Widgets
import Quickshell.Io
import qs.services
import qs.config
import qs.components

Item {
    id: root
    anchors.fill: parent
    signal folderOpen(bool isOpen)
    property string imagePath: ""
    property var paletteData: Color.paletteData
    property var aiGeneratedTheme: null
    property var isLayOutDebugEnabled: false

    Rectangle {
        id: rootArea
        color: 'transparent'
        anchors.fill: parent

        Rectangle {
            id: marginedArea
            color: 'transparent'
            width: parent.width * 0.8
            height: parent.height
            anchors.centerIn: parent
            border.color: root.isLayOutDebugEnabled ? 'green' : ''
            border.width: root.isLayOutDebugEnabled ? 1 : 0

            Rectangle {
                id: widgetArea
                color: Color.palette.base03
                width: parent.width
                height: parent.height * 0.15
                radius: 8
                border.color: root.isLayOutDebugEnabled ? 'pink' : ''
                border.width: root.isLayOutDebugEnabled ? 1 : 0

                Column {
                    spacing: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter

                    // Top row - primary actions and color palette
                    Row {
                        spacing: 20
                        anchors.horizontalCenter: parent.horizontalCenter

                        FolderButton {
                            id: folderButton
                            toolTipContainer: rootArea
                            onOpened: flag => {
                                root.folderOpen(flag);
                            }
                            onPathAdded: path => {
                                root.imagePath = path;
                            }
                        }

                        AIColorGeneratorButton {
                            id: generateColors
                            wallpaperPath: root.imagePath
                            toolTipContainer: rootArea
                            onColorsGenerated: jsonColors => {
                                const aiGeneratedPalette = jsonColors.palette;
                                root.paletteData = Color.convertPaletteToArray(aiGeneratedPalette);
                                root.aiGeneratedTheme = jsonColors;
                            }
                        }

                        IconButton {
                            id: saveJsonButton
                            iconName: "document-save-as"
                            iconSize: 26
                            z: -1
                            toolTipContainer: rootArea
                            iconColor: Color.palette.base04
                            tooltip: "Save Theme"
                            disabled: root.aiGeneratedTheme == null
                            property var jsonData: root.aiGeneratedTheme
                            property string filePath: ""
                            onClicked: {
                                if (!jsonData) {
                                    return;
                                }
                                saveJsonToLocation.json = root.aiGeneratedTheme;
                                saveJsonToLocation.running = true;
                            }

                            Process {
                                id: saveJsonToLocation
                                property var json: null
                                property string filePath: "/etc/nixos/nix/themes"
                                signal error(string message)
                                function jsonToNix(obj, indent = 0) {
                                    const spaces = "  ".repeat(indent);
                                    const lines = [];

                                    for (const [key, value] of Object.entries(obj)) {
                                        if (typeof value === "object" && value !== null) {
                                            lines.push(`${spaces}${key} = ${jsonToNix(value, indent + 1)};`);
                                        } else {
                                            lines.push(`${spaces}${key} = ${JSON.stringify(value)};`);
                                        }
                                    }

                                    const closingSpaces = indent > 0 ? "  ".repeat(indent - 1) : "";
                                    return `{\n${lines.join("\n")}\n${closingSpaces}}`;
                                }
                                command: {
                                    if (!json) {
                                        error("no json provided");
                                        return []; // no-op command
                                    }
                                    if (filePath.length == 0) {
                                        error("filePath was not provided");
                                        return [];
                                    }
                                    const folderName = json["slug"];
                                    if (!folderName) {
                                        error("The slug was not found, so file name was not created");
                                        return [];
                                    }
                                    const nixString = jsonToNix(json, 2);
                                    const builtCommand = `mkdir -p ${filePath}/${folderName} && echo '${nixString}' > ${filePath}/${folderName}/default.nix`;
                                    return ["sh", "-c", builtCommand];
                                }
                            }
                        }

                        // Visual divider
                        Rectangle {
                            width: 1
                            height: 30
                            color: Color.palette.base04
                            opacity: 0.3
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Grid {
                            columns: 8
                            rows: 2
                            spacing: 10
                            anchors.verticalCenter: parent.verticalCenter

                            Repeater {
                                id: coloredCircles
                                model: root.paletteData

                                Rectangle {
                                    id: colorRect
                                    width: 15
                                    height: 15
                                    color: modelData.color
                                    radius: AppearanceConfig.calculateRadius(width, height, 'round')
                                    border.width: 1
                                    border.color: Color.getBorderColor(colorRect.color)

                                    property bool hovered: false

                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onEntered: colorRect.hovered = true
                                        onExited: colorRect.hovered = false
                                    }

                                    // Tooltip
                                    Rectangle {
                                        id: tooltip
                                        width: tooltipText.width + 16
                                        height: tooltipText.height + 12
                                        color: Color.palette.base0E
                                        radius: 6

                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.bottom: parent.top
                                        anchors.bottomMargin: 8

                                        visible: colorRect.hovered
                                        opacity: colorRect.hovered ? 1.0 : 0.0

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.InOutQuad
                                            }
                                        }

                                        Text {
                                            id: tooltipText
                                            anchors.centerIn: parent
                                            text: modelData.name + "\n" + colorRect.color.toString().toUpperCase()
                                            color: Color.palette.base06
                                            font.pixelSize: 11
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        // Tooltip arrow
                                        Rectangle {
                                            width: 8
                                            height: 8
                                            color: tooltip.color
                                            rotation: 45
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.top: parent.bottom
                                            anchors.topMargin: -4
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Bottom row - dropdowns only
                    Row {
                        spacing: 16
                        anchors.horizontalCenter: parent.horizontalCenter

                        // Placeholder for your first dropdown
                        // ComboBox {
                        //     id: dropdown1
                        //     width: 120
                        //     // Add your dropdown configuration here
                        // }

                        // Placeholder for your second dropdown
                        // ComboBox {
                        //     id: dropdown2
                        //     width: 120
                        //     // Add your dropdown configuration here
                        // }
                    }
                }
            }

            ClippingRectangle {
                width: parent.width * 0.8
                height: parent.height * 0.5
                anchors.horizontalCenter: marginedArea.horizontalCenter
                y: widgetArea.y + widgetArea.height + 48
                visible: root.imagePath.toString().length > 0
                clip: true
                radius: 10
                color: Color.palette.base03
                Image {
                    id: backgroundImageFile
                    anchors.fill: parent
                    mipmap: true
                    fillMode: Image.PreserveAspectFit
                    source: root.imagePath
                    visible: source.toString().length > 0
                    onVisibleChanged: {}
                }
            }

            Rectangle {
                id: imageArea
            }

            Rectangle {
                id: colorWidgetArea
                color: 'transparent'
                width: parent.width
                height: parent.height * 0.3
                y: rootArea.y + rootArea.height - height
                border.color: root.isLayOutDebugEnabled ? 'red' : ''
                border.width: root.isLayOutDebugEnabled ? 1 : 0
            }
        }
    }
}
