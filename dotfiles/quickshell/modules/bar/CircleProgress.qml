// CircleProgress.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Effects

Rectangle {
    id: circleProgressRoot
    width: 70 // As per your original oneStatContainer width
    height: parent.height // Or define a fixed height if not used in a Row with parent.height
    color: parent.color // Assuming parent.color is available or set directly

    // Properties to make the component dynamic
    property real percentage: 0
    property string statText: "0%"
    property url iconSource: ""
    property color progressColor: "#FF9E64" // base09 orange
    property color backgroundColor: "#111A2C" // base01 background color
    property color textColor: "#FF9E64" // base09

    Rectangle {
        id: statTextContainer
        width: 32
        height: parent.height
        x: 34
        color: 'transparent'

        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 5
            text: circleProgressRoot.statText
            color: circleProgressRoot.textColor
            font.pointSize: 10
        }
    }

    Item {
        id: circleDrawingArea
        width: 30
        height: 30
        anchors.verticalCenter: parent.verticalCenter

        Canvas {
            id: progressCanvas
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                var centerX = width / 2;
                var centerY = height / 2;
                var radius = (width - 4) / 2;

                // Draw background circle (unfilled portion)
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                ctx.strokeStyle = circleProgressRoot.backgroundColor;
                ctx.lineWidth = 2;
                ctx.stroke();

                // Draw progress arc (filled portion)
                if (circleProgressRoot.percentage > 0) {
                    ctx.beginPath();
                    var startAngle = -Math.PI / 2;
                    var endAngle = startAngle + (2 * Math.PI * circleProgressRoot.percentage / 100);
                    ctx.arc(centerX, centerY, radius, startAngle, endAngle);
                    ctx.strokeStyle = circleProgressRoot.progressColor;
                    ctx.lineWidth = 2;
                    ctx.stroke();
                }
            }
        }

        Connections {
            target: circleProgressRoot
            function onPercentageChanged() {
                progressCanvas.requestPaint();
            }
        }

        Image {
            source: circleProgressRoot.iconSource
            width: 15
            height: 15
            antialiasing: true
            layer.enabled: true
            anchors.centerIn: parent
            layer.effect: MultiEffect {
                brightness: 1.0
                colorization: 1.0
                colorizationColor: circleProgressRoot.textColor // Use textColor for icon colorization
            }
        }
    }
}
