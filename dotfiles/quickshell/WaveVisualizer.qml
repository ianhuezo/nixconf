import QtQuick

Canvas {
    id: wave
    property var cavaValues: []
    property color waveColor: 'white'
    property color strokeColor: 'yellow'
    property int lineWidth: 3

    onPaint: {
        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            if (cavaValues.length < 2)
                return;

            // 1. Define minimum vertical scale to ensure 2px height
            const minMaxValue = 30; // Adjust this to control sensitivity
            const rawMax = Math.max(...cavaValues);
            const maxValue = Math.max(minMaxValue, rawMax); // Enforce minimum scale

            // 2. Calculate dimensions
            const stepX = width / (cavaValues.length - 1);
            const baseY = height; // Bottom padding

            ctx.beginPath();
            ctx.strokeStyle = waveColor;
            ctx.lineWidth = lineWidth;
            ctx.fillStyle = waveColor;

            // 3. Draw filled path
            ctx.moveTo(0, baseY);

            for (let i = 0; i < cavaValues.length; i++) {
                const x = i * stepX;
                // 4. Ensure values scale to at least 2px height
                const y = baseY - (cavaValues[i] / maxValue * (baseY - 2));

                if (i === 0 || i === cavaValues.length - 1) {
                    continue;
                } else {
                    const prevY = baseY - (cavaValues[i - 1] / maxValue * (baseY - 2));
                    const cp1x = x - stepX / 2;
                    const cp1y = prevY;
                    const cp2x = x - stepX / 2;
                    const cp2y = y;
                    ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
                }
            }

            // 5. Close and render
            ctx.lineTo(width, baseY);
            ctx.closePath();
            ctx.fill();
            ctx.stroke();
        }
    }

    Timer {
        interval: 16
        running: true
        repeat: true
        onTriggered: wave.requestPaint()
    }
}
