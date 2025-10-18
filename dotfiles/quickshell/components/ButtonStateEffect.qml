import QtQuick
import QtQuick.Effects

Item {
    id: root

    // State
    property bool active: false

    // Effect type: "glow", "border", "pulse", "shimmer"
    property string effectType: "glow"

    // Colors
    property color activeColor: "orange"
    property color inactiveColor: "gray"

    // Glow-specific properties
    property real glowBlur: 0.8
    property real glowOpacity: 0.6

    // Border-specific properties
    property int borderWidth: 2

    // Pulse-specific properties
    property int pulseInterval: 1000
    property real pulseMinIntensity: 0.5
    property real pulseMaxIntensity: 1.0

    // Transition speed
    property int transitionDuration: 300

    readonly property color currentColor: active ? activeColor : inactiveColor

    anchors.fill: parent

    Loader {
        id: effectLoader
        anchors.fill: parent
        sourceComponent: {
            switch(root.effectType) {
                case "glow": return glowComponent;
                case "border": return borderComponent;
                case "pulse": return pulseComponent;
                case "shimmer": return shimmerComponent;
                default: return glowComponent;
            }
        }
    }

    // Glow effect using MultiEffect shadow
    Component {
        id: glowComponent
        Item {
            anchors.fill: parent

            Rectangle {
                id: glowSource
                anchors.fill: parent
                color: "transparent"
                border.color: root.currentColor
                border.width: 1
                radius: parent.radius || 0
                visible: false
            }

            MultiEffect {
                source: glowSource
                anchors.fill: parent
                shadowEnabled: true
                shadowColor: root.currentColor
                shadowBlur: root.glowBlur
                shadowOpacity: root.active ? root.glowOpacity : 0
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0

                Behavior on shadowOpacity {
                    NumberAnimation {
                        duration: root.transitionDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    // Border effect
    Component {
        id: borderComponent
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: root.currentColor
            border.width: root.active ? root.borderWidth : 0
            radius: parent.radius || 0

            Behavior on border.width {
                NumberAnimation {
                    duration: root.transitionDuration
                    easing.type: Easing.InOutQuad
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: root.transitionDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    // Pulse effect
    Component {
        id: pulseComponent
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: root.currentColor
            border.width: 2
            radius: parent.radius || 0
            opacity: root.active ? 1.0 : 0

            property real pulseIntensity: 1.0

            Behavior on opacity {
                NumberAnimation {
                    duration: root.transitionDuration
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation on pulseIntensity {
                running: root.active
                loops: Animation.Infinite

                NumberAnimation {
                    from: root.pulseMinIntensity
                    to: root.pulseMaxIntensity
                    duration: root.pulseInterval / 2
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    from: root.pulseMaxIntensity
                    to: root.pulseMinIntensity
                    duration: root.pulseInterval / 2
                    easing.type: Easing.InOutQuad
                }
            }

            MultiEffect {
                source: parent
                anchors.fill: parent
                shadowEnabled: true
                shadowColor: root.currentColor
                shadowBlur: 0.8
                shadowOpacity: parent.pulseIntensity * 0.8
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }
        }
    }

    // Shimmer effect for state transition
    Component {
        id: shimmerComponent
        Item {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: root.currentColor
                border.width: 1
                radius: parent.radius || 0

                Behavior on border.color {
                    ColorAnimation {
                        duration: root.transitionDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            Rectangle {
                id: shimmerBar
                width: parent.width * 0.3
                height: parent.height
                x: -width
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: root.activeColor }
                    GradientStop { position: 1.0; color: "transparent" }
                }
                opacity: 0.5

                SequentialAnimation on x {
                    running: root.active
                    NumberAnimation {
                        from: -shimmerBar.width
                        to: parent.width
                        duration: 1500
                        easing.type: Easing.InOutQuad
                    }
                    PauseAnimation { duration: 500 }
                    loops: Animation.Infinite
                }
            }
        }
    }
}
