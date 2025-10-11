import QtQuick

Canvas {
    id: wave
    property var cavaValues: []
    property color waveColor: 'white'
    property color strokeColor: 'yellow'
    property int lineWidth: 1
    property bool mirrored: true
    property real sensitivity: 1  // Adjust to control wave amplitude (0.1 = less sensitive, 2.0 = more sensitive)

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (cavaValues.length < 2)
            return;
        // 1. Define minimum vertical scale to ensure 2px height
        const minMaxValue = 15;
        const rawMax = Math.max(...cavaValues);
        const maxValue = Math.max(minMaxValue, rawMax);
        // 2. Calculate dimensions
        const drawHeight = mirrored ? height / 2 : height;
        const stepX = width / (cavaValues.length - 1);
        const baseY = mirrored ? drawHeight : height;
        ctx.strokeStyle = waveColor;
        ctx.lineWidth = lineWidth;
        ctx.fillStyle = waveColor;
        ctx.lineCap = 'round';  // Smooth line endings
        ctx.lineJoin = 'round'; // Smooth corners

        // 3. Draw top wave (or full wave if not mirrored)
        ctx.beginPath();
        ctx.moveTo(0, baseY);

        // Smooth transition at the start
        const firstScaledValue = cavaValues[0] * sensitivity;
        const firstY = baseY - (firstScaledValue / maxValue * (baseY - 2));
        ctx.quadraticCurveTo(0, firstY, stepX * 0.5, baseY - ((cavaValues[0] * sensitivity + (cavaValues.length > 1 ? cavaValues[1] * sensitivity : cavaValues[0] * sensitivity)) / 2 / maxValue * (baseY - 2)));

        for (let i = 0; i < cavaValues.length; i++) {
            const x = i * stepX;
            const scaledValue = cavaValues[i] * sensitivity;
            const y = baseY - (scaledValue / maxValue * (baseY - 2));
            if (i === 0) {
                continue; // Already handled above
            } else {
                const prevScaledValue = cavaValues[i - 1] * sensitivity;
                const prevY = baseY - (prevScaledValue / maxValue * (baseY - 2));
                const cp1x = x - stepX / 2;
                const cp1y = prevY;
                const cp2x = x - stepX / 2;
                const cp2y = y;
                ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
            }
        }

        // Smooth transition at the end
        const lastScaledValue = cavaValues[cavaValues.length - 1] * sensitivity;
        const lastY = baseY - (lastScaledValue / maxValue * (baseY - 2));
        ctx.quadraticCurveTo(width, lastY, width, baseY);

        ctx.closePath();
        ctx.fill();
        ctx.stroke();

        // 4. Draw mirrored bottom wave if enabled
        if (mirrored) {
            ctx.beginPath();
            ctx.moveTo(0, drawHeight);

            // Smooth transition at the start
            const firstScaledValueBottom = cavaValues[0] * sensitivity;
            const firstYBottom = drawHeight + (firstScaledValueBottom / maxValue * (drawHeight - 2));
            ctx.quadraticCurveTo(0, firstYBottom, stepX * 0.5, drawHeight + ((cavaValues[0] * sensitivity + (cavaValues.length > 1 ? cavaValues[1] * sensitivity : cavaValues[0] * sensitivity)) / 2 / maxValue * (drawHeight - 2)));

            for (let i = 0; i < cavaValues.length; i++) {
                const x = i * stepX;
                const scaledValue = cavaValues[i] * sensitivity;
                const y = drawHeight + (scaledValue / maxValue * (drawHeight - 2));
                if (i === 0) {
                    continue; // Already handled above
                } else {
                    const prevScaledValue = cavaValues[i - 1] * sensitivity;
                    const prevY = drawHeight + (prevScaledValue / maxValue * (drawHeight - 2));
                    const cp1x = x - stepX / 2;
                    const cp1y = prevY;
                    const cp2x = x - stepX / 2;
                    const cp2y = y;
                    ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x, y);
                }
            }

            // Smooth transition at the end
            const lastScaledValueBottom = cavaValues[cavaValues.length - 1] * sensitivity;
            const lastYBottom = drawHeight + (lastScaledValueBottom / maxValue * (drawHeight - 2));
            ctx.quadraticCurveTo(width, lastYBottom, width, drawHeight);

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
