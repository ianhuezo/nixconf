import QtQuick 2.15
import QtQuick.Controls 2.15

Rectangle {
    width: 300
    height: 100
    color: "#2b2b2b"

    property real volume: 0.5 // 0.0 to 1.0

    Canvas {
        id: brushCanvas
        anchors.fill: parent
        anchors.margins: 20

        property real strokeWidth: 8
        property real roughness: 0.3 // Controls brush texture

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            // Background stroke (full length, muted)
            drawBrushStroke(ctx, 0, 1, "#404040", 0.6);

            // Active stroke (volume level)
            if (volume > 0) {
                drawBrushStroke(ctx, 0, volume, "#ff6b35", 1.0);
            }
        }

        function drawBrushStroke(ctx, startPos, endPos, color, opacity) {
            var startX = width * startPos;
            var endX = width * endPos;
            var centerY = height / 2;

            ctx.globalAlpha = opacity;
            ctx.strokeStyle = color;
            ctx.lineWidth = strokeWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            // Create brush texture with slight variations
            ctx.beginPath();
            ctx.moveTo(startX, centerY);

            var segments = Math.max(10, (endX - startX) / 5);
            for (var i = 1; i <= segments; i++) {
                var x = startX + (endX - startX) * (i / segments);
                var yOffset = (Math.random() - 0.5) * roughness * strokeWidth;
                var widthVariation = 1 + (Math.random() - 0.5) * 0.3;

                ctx.lineWidth = strokeWidth * widthVariation;
                ctx.lineTo(x, centerY + yOffset);
            }

            ctx.stroke();

            // Add some texture with multiple passes
            for (var pass = 0; pass < 2; pass++) {
                ctx.globalAlpha = opacity * 0.3;
                ctx.lineWidth = strokeWidth * (0.5 + pass * 0.3);
                ctx.beginPath();
                ctx.moveTo(startX, centerY + (Math.random() - 0.5) * 2);

                for (var j = 1; j <= segments; j++) {
                    var tx = startX + (endX - startX) * (j / segments);
                    var tyOffset = (Math.random() - 0.5) * roughness * strokeWidth * 0.8;
                    ctx.lineTo(tx, centerY + tyOffset);
                }
                ctx.stroke();
            }
        }

        // Repaint when volume changes
        Connections {
            target: parent
            function onVolumeChanged() {
                brushCanvas.requestPaint();
            }
        }
    }

    // Invisible slider for interaction
    Slider {
        id: volumeSlider
        anchors.fill: parent
        from: 0.0
        to: 1.0
        value: volume
        background: Item {} // Hide default background
        handle: Item {} // Hide default handle

        onValueChanged: {
            volume = value;
        }
    }

    // Volume level text
    Text {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 10
        text: Math.round(volume * 100) + "%"
        color: "#ffffff"
        font.pixelSize: 16
    }
}
