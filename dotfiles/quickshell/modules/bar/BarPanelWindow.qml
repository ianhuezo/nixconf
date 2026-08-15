import Quickshell
import QtQuick
import QtQuick.Effects
import qs.config
import qs.services
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: panel

    // Required properties
    required property var modelData
    required property var cavaValues
    required property string visualizerMode
    required property var barOffsetY
    required property var barOffsetX
    required property var verticalPadding
    required property bool isActive

    // Panel configuration
    property real panelHeight: 36
    property real panelRadius: 8
    property bool isSectionedBar: false
    property bool isBarBordered: false
    property color barBorderColor: Color.palette.base09
    property color widgetMainColor: Color.palette.base0C

    // Master switch for the frosted look. Off gives back the flat coloured bar.
    // The other half of the toggle lives in the Hyprland config: the
    // quickshell-bar layerrules there are what actually blur the wallpaper, and
    // they are commented out to match this being false.
    property bool isGlassBar: false

    // Glass tuning. Both opacities are *final* on-screen values, so the bar
    // reads as one material: sections are denser glass, never a solid slab
    // sitting on top of glass.
    property real fillerOpacity: 0.45   // filler between sections — most glass
    property real sectionOpacity: 0.72  // sections holding content — denser glass
    property real glassRimOpacity: 0.1  // hairline highlight along the bar edge
    property real glassSheenOpacity: 0.07 // top-down specular gradient

    // Sections are sized to their content, then the glass is padded out around
    // it and dissolved over `sectionFade`. Keeping the outer gap equal to the
    // whole bleed means the end panes finish dissolving exactly at the bar's
    // rounded edge — no pane ever runs off it.
    property real sectionPadding: 12
    property real sectionFade: 26

    // Everything below collapses to the flat bar when the glass is off, so the
    // switch is the only thing that needs touching.
    readonly property bool glassActive: isGlassBar && !isSectionedBar
    readonly property real fillerAlpha: glassActive ? fillerOpacity : 1
    readonly property real paneFade: glassActive ? sectionFade : 0
    readonly property real paneBleed: glassActive ? -(sectionPadding + sectionFade) : 0
    readonly property real sectionEdgeGap: glassActive ? sectionPadding + sectionFade : sectionPadding

    // What sits under a section: the filler, unless the bar is in sectioned mode.
    readonly property real sectionUnderlay: isSectionedBar ? 0 : fillerAlpha

    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // Computed properties
    property real animatedHeight: isActive ? 54 : 0
    property real duration: isActive ? 300 : 1

    screen: modelData
    implicitHeight: animatedHeight
    color: '#00000000'

    // Distinct namespace so the compositor can blur the bar without blurring
    // every other quickshell surface.
    WlrLayershell.namespace: "quickshell-bar"

    anchors {
        top: true
        left: true
        right: true
    }

    Behavior on animatedHeight {
        NumberAnimation {
            duration: panel.duration
            easing.type: Easing.OutCubic
        }
    }

    // Main container with offset margins
    Item {
        id: container
        anchors {
            fill: parent
            topMargin: verticalPadding
            bottomMargin: verticalPadding
            leftMargin: barOffsetX
            rightMargin: barOffsetX
        }

        // Animated scale transform
        property real targetScale: panel.isActive ? 1.0 : 0.0

        // Use opacity to prevent artifacts while preserving the animation
        opacity: panel.isActive ? 1.0 : 0.0

        transform: Scale {
            xScale: container.targetScale
            yScale: container.targetScale
            origin.x: container.width / 2
            origin.y: container.height / 2
        }

        Behavior on targetScale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        // Main bar with blur effect
        Item {
            id: bar
            anchors.fill: parent

            // Outer rectangle acts as border for unified bar
            Rectangle {
                anchors.fill: parent
                color: barBorderColor
                radius: panelRadius
                visible: isBarBordered && !isSectionedBar
                z: 0
            }

            // Inner background rectangle — the glassy filler
            Rectangle {
                id: fillerBackground
                anchors.fill: parent
                anchors.margins: (isBarBordered && !isSectionedBar) ? 1 : 0
                color: isSectionedBar ? "transparent" : panel.withAlpha(Color.palette.base01, panel.fillerAlpha)
                radius: (isBarBordered && !isSectionedBar) ? panelRadius - 1 : panelRadius
                z: 1

                border.width: panel.glassActive ? 1 : 0
                border.color: panel.withAlpha(Color.palette.base05, panel.glassRimOpacity)

                layer.enabled: true

                // Specular sheen so the transparent stretch still reads as a surface
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: parent.border.width
                    radius: parent.radius
                    visible: panel.glassActive
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: panel.withAlpha(Color.palette.base07, panel.glassSheenOpacity)
                        }
                        GradientStop {
                            position: 0.55
                            color: "transparent"
                        }
                    }
                }
            }
        }

        // Three-section layout using anchors for better positioning
        Item {
            anchors.fill: parent
            anchors.margins: (isBarBordered && !isSectionedBar) ? 1 : 0
            z: 2

            // LEFT SECTION
            Item {
                id: leftSection
                anchors {
                    left: parent.left
                    leftMargin: panel.sectionEdgeGap
                    top: parent.top
                    bottom: parent.bottom
                }
                width: leftContent.implicitWidth

                Rectangle {
                    anchors.fill: parent
                    color: barBorderColor
                    radius: panelRadius
                    visible: isBarBordered && isSectionedBar
                    z: 0
                }

                GlassPane {
                    anchors.fill: parent
                    anchors.margins: (isBarBordered && isSectionedBar) ? 1 : 0
                    anchors.leftMargin: panel.paneBleed
                    anchors.rightMargin: panel.paneBleed
                    fillOpacity: panel.sectionOpacity
                    underlayOpacity: panel.sectionUnderlay
                    fadeWidth: panel.paneFade
                    cornerRadius: panel.glassActive ? 0 : panelRadius
                    z: 1
                }

                Left {
                    id: leftContent
                    anchors.fill: parent
                    z: 2
                }
            }

            // CENTER SECTION
            Item {
                id: centerSection
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    bottom: parent.bottom
                }
                width: centerContent.implicitWidth

                Rectangle {
                    anchors.fill: parent
                    color: barBorderColor
                    radius: panelRadius
                    visible: isBarBordered && isSectionedBar
                    z: 0
                }

                GlassPane {
                    anchors.fill: parent
                    anchors.margins: (isBarBordered && isSectionedBar) ? 1 : 0
                    anchors.leftMargin: panel.paneBleed
                    anchors.rightMargin: panel.paneBleed
                    fillOpacity: panel.sectionOpacity
                    underlayOpacity: panel.sectionUnderlay
                    fadeWidth: panel.paneFade
                    cornerRadius: panel.glassActive ? 0 : panelRadius
                    z: 1
                }

                Center {
                    id: centerContent
                    anchors.fill: parent
                    z: 2
                    cavaValues: panel.cavaValues
                    visualizerMode: panel.visualizerMode
                    waveColor: panel.widgetMainColor
                    isSectionedBar: panel.isSectionedBar
                    onToggleVisualization: {
                        const modes = ["wave", "bars", "title"];
                        const idx = modes.indexOf(panel.visualizerMode);
                        panel.visualizerMode = modes[(idx + 1) % modes.length];
                    }
                }
            }

            // RIGHT SECTION
            Item {
                id: rightSection
                anchors {
                    right: parent.right
                    rightMargin: panel.sectionEdgeGap
                    top: parent.top
                    bottom: parent.bottom
                }
                width: rightContent.implicitWidth

                Rectangle {
                    anchors.fill: parent
                    color: barBorderColor
                    radius: panelRadius
                    visible: isBarBordered && isSectionedBar
                    z: 0
                }

                GlassPane {
                    anchors.fill: parent
                    anchors.margins: (isBarBordered && isSectionedBar) ? 1 : 0
                    anchors.leftMargin: panel.paneBleed
                    anchors.rightMargin: panel.paneBleed
                    fillOpacity: panel.sectionOpacity
                    underlayOpacity: panel.sectionUnderlay
                    fadeWidth: panel.paneFade
                    cornerRadius: panel.glassActive ? 0 : panelRadius
                    z: 1
                }

                Right {
                    id: rightContent
                    anchors.fill: parent
                    z: 2
                    widgetColor: panel.widgetMainColor
                    clockColor: Color.palette.base0F
                }
            }
        }
    }
}
