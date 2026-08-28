import Quickshell
import QtQuick
import Quickshell.Wayland
import qs.config
import qs.services

PanelWindow {
    id: root

    required property var weather

    implicitWidth: 452
    implicitHeight: 220
    color: "transparent"
    visible: false

    anchors {
        top: true
        right: true
    }

    margins {
        top: 84
        right: 36
    }

    WlrLayershell.namespace: "quickshell-weather"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: 0

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: AppearanceConfig.radius.lg
        color: root.withAlpha(Color.palette.base00, 0.82)
        border.width: 1
        border.color: root.withAlpha(Color.palette.base09, 0.72)
        clip: true

        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Color.palette.base09 }
                GradientStop { position: 0.52; color: Color.palette.base0C }
                GradientStop { position: 1; color: root.withAlpha(Color.palette.base0E, 0.18) }
            }
        }

        Text {
            id: locationText
            x: 22
            y: 17
            width: parent.width - 150
            text: root.weather.location
            color: Color.palette.base05
            font.family: AppearanceConfig.font.ui
            font.pixelSize: AppearanceConfig.font.size.sm
            font.weight: AppearanceConfig.font.weight.semibold
            elide: Text.ElideRight
        }

        Row {
            anchors {
                right: parent.right
                rightMargin: 21
                verticalCenter: locationText.verticalCenter
            }
            spacing: 7

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 6
                height: 6
                radius: 3
                color: root.weather.errorMessage.length > 0
                    ? Color.palette.base09
                    : Color.palette.base0B
                opacity: root.weather.loading ? 0.35 : 0.9

                SequentialAnimation on opacity {
                    running: root.weather.loading
                    loops: Animation.Infinite
                    NumberAnimation { to: 1; duration: 650; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.25; duration: 650; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: root.weather.errorMessage.length > 0
                    ? root.weather.errorMessage
                    : (root.weather.updatedLabel.length > 0 ? root.weather.updatedLabel : "wttr.in")
                color: Color.palette.base04
                font.family: AppearanceConfig.font.mono
                font.pixelSize: AppearanceConfig.font.size.xs
            }
        }

        WeatherIcon {
            id: weatherIcon
            x: 18
            y: 51
            width: 132
            height: 132
            kind: root.weather.weatherKind
            isNight: root.weather.isNight
            opacity: root.weather.hasData ? 1 : 0.45

            Behavior on opacity {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.InOutCubic
                }
            }
        }

        Rectangle {
            x: 153
            y: 56
            width: 1
            height: 139
            color: root.withAlpha(Color.palette.base03, 0.72)
        }

        Text {
            id: temperatureText
            x: 174
            y: 48
            text: root.weather.temperature + "°"
            color: Color.palette.base07
            font.family: AppearanceConfig.font.display
            font.pixelSize: 54
            font.weight: AppearanceConfig.font.weight.light
        }

        Text {
            x: temperatureText.x + temperatureText.width + 10
            y: 63
            width: parent.width - x - 22
            text: root.weather.description
            color: Color.palette.base0C
            font.family: AppearanceConfig.font.ui
            font.pixelSize: AppearanceConfig.font.size.md
            font.weight: AppearanceConfig.font.weight.medium
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Row {
            id: metrics
            x: 174
            y: 143
            width: parent.width - x - 22
            height: 55
            spacing: 8

            Repeater {
                model: [
                    {
                        label: "FEELS",
                        value: root.weather.feelsLike + "°F",
                        accent: Color.palette.base09
                    },
                    {
                        label: "WIND",
                        value: (root.weather.windDirection.length > 0 ? root.weather.windDirection + " " : "")
                            + root.weather.windSpeed + " km/h",
                        accent: Color.palette.base0C
                    },
                    {
                        label: "HUMIDITY",
                        value: root.weather.humidity + "%",
                        accent: Color.palette.base0E
                    }
                ]

                delegate: Rectangle {
                    required property var modelData

                    width: (metrics.width - metrics.spacing * 2) / 3
                    height: metrics.height
                    radius: AppearanceConfig.radius.md
                    color: root.withAlpha(Color.palette.base01, 0.9)
                    border.width: 1
                    border.color: root.withAlpha(modelData.accent, 0.28)

                    Rectangle {
                        x: 9
                        y: 10
                        width: 5
                        height: 5
                        radius: 3
                        color: modelData.accent
                    }

                    Text {
                        x: 19
                        y: 6
                        text: modelData.label
                        color: Color.palette.base04
                        font.family: AppearanceConfig.font.mono
                        font.pixelSize: 9
                        font.weight: AppearanceConfig.font.weight.medium
                    }

                    Text {
                        x: 9
                        y: 25
                        width: parent.width - 18
                        text: modelData.value
                        color: Color.palette.base05
                        font.family: AppearanceConfig.font.mono
                        font.pixelSize: modelData.label === "WIND" ? 10 : AppearanceConfig.font.size.xs
                        font.weight: AppearanceConfig.font.weight.semibold
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
