import QtQuick
import QtQuick.Effects

Item {
    id: root

    // Effect type: "gradient", "spinner", "pulse", "shimmer"
    property string effectType: "gradient"

    // Whether the effect is active
    property bool active: false

    // Colors for the effect
    property color primaryColor: "white"
    property color secondaryColor: "transparent"

    // Speed control (milliseconds for one cycle)
    property int duration: 2000

    // Gradient-specific properties
    property real gradientWidth: 0.3 // Width of the gradient sweep (0.0-1.0)
    property real gradientAngle: 0 // Angle in degrees (0 = horizontal)

    // Spinner-specific properties
    property real spinnerArcLength: 1.5 // Length of arc in PI units
    property int spinnerWidth: 2

    // Pulse-specific properties
    property real pulseMinOpacity: 0.3
    property real pulseMaxOpacity: 1.0

    // Shimmer-specific properties
    property real shimmerWidth: 0.2
    property int shimmerCount: 3

    anchors.fill: parent
    visible: active

    Loader {
        id: effectLoader
        anchors.fill: parent
        sourceComponent: {
            switch(root.effectType) {
                case "gradient": return gradientComponent;
                case "spinner": return spinnerComponent;
                case "pulse": return pulseComponent;
                case "shimmer": return shimmerComponent;
                default: return gradientComponent;
            }
        }
    }

    // Gradient sweep effect
    Component {
        id: gradientComponent
        Item {
            anchors.fill: parent

            Canvas {
                id: gradientCanvas
                anchors.fill: parent
                property real offset: 0

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);

                    // Convert angle to radians
                    var angleRad = root.gradientAngle * Math.PI / 180;

                    // Calculate gradient direction
                    var dx = Math.cos(angleRad);
                    var dy = Math.sin(angleRad);

                    // Gradient moves from -1 to 2 (to fully sweep across)
                    var progress = offset * 3 - 1;

                    // Calculate gradient start and end points
                    var gradientSize = Math.max(width, height) * 2;
                    var centerX = width / 2 + progress * gradientSize * dx;
                    var centerY = height / 2 + progress * gradientSize * dy;

                    var x1 = centerX - gradientSize * root.gradientWidth * dx;
                    var y1 = centerY - gradientSize * root.gradientWidth * dy;
                    var x2 = centerX + gradientSize * root.gradientWidth * dx;
                    var y2 = centerY + gradientSize * root.gradientWidth * dy;

                    var gradient = ctx.createLinearGradient(x1, y1, x2, y2);
                    gradient.addColorStop(0, root.secondaryColor.toString());
                    gradient.addColorStop(0.5, root.primaryColor.toString());
                    gradient.addColorStop(1, root.secondaryColor.toString());

                    ctx.fillStyle = gradient;
                    ctx.fillRect(0, 0, width, height);
                }

                NumberAnimation on offset {
                    running: root.active
                    from: 0
                    to: 1
                    duration: root.duration
                    loops: Animation.Infinite
                    onRunningChanged: gradientCanvas.requestPaint()
                }

                onOffsetChanged: requestPaint()
            }
        }
    }

    // Spinner effect
    Component {
        id: spinnerComponent
        Item {
            anchors.fill: parent

            Canvas {
                id: spinnerCanvas
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                rotation: 0

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();

                    var centerX = width / 2;
                    var centerY = height / 2;
                    var radius = Math.min(width, height) / 2 - root.spinnerWidth;

                    ctx.strokeStyle = root.primaryColor.toString();
                    ctx.lineWidth = root.spinnerWidth;
                    ctx.lineCap = "round";
                    ctx.beginPath();
                    ctx.arc(centerX, centerY, radius, 0, Math.PI * root.spinnerArcLength);
                    ctx.stroke();
                }

                RotationAnimator on rotation {
                    running: root.active
                    from: 0
                    to: 360
                    duration: root.duration
                    loops: Animation.Infinite
                }

                onVisibleChanged: {
                    if (visible) requestPaint();
                }
            }

            Connections {
                target: root
                function onPrimaryColorChanged() { spinnerCanvas.requestPaint(); }
            }
        }
    }

    // Pulse effect
    Component {
        id: pulseComponent
        Rectangle {
            anchors.fill: parent
            color: root.primaryColor
            opacity: root.pulseMinOpacity

            SequentialAnimation on opacity {
                running: root.active
                loops: Animation.Infinite

                NumberAnimation {
                    from: root.pulseMinOpacity
                    to: root.pulseMaxOpacity
                    duration: root.duration / 2
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    from: root.pulseMaxOpacity
                    to: root.pulseMinOpacity
                    duration: root.duration / 2
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }

    // Shimmer effect
    Component {
        id: shimmerComponent
        Item {
            anchors.fill: parent

            Repeater {
                model: root.shimmerCount

                Rectangle {
                    width: parent.width * root.shimmerWidth
                    height: parent.height * 2
                    rotation: 20

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: root.secondaryColor }
                        GradientStop { position: 0.5; color: root.primaryColor }
                        GradientStop { position: 1.0; color: root.secondaryColor }
                    }

                    property real progress: 0
                    x: -width + (parent.width + width * 2) * progress
                    y: -height / 4

                    SequentialAnimation on progress {
                        running: root.active
                        loops: Animation.Infinite

                        PauseAnimation {
                            duration: index * (root.duration / root.shimmerCount)
                        }

                        NumberAnimation {
                            from: 0
                            to: 1
                            duration: root.duration
                            easing.type: Easing.InOutQuad
                        }
                    }
                }
            }
        }
    }
}
