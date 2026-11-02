import QtQuick

Canvas {
    id: root

    property var heights: []
    property string shape: "spline" // or "bells"
    property color color: 'white'
    property bool mirrored: true
    property int lineWidth: 1
    property real edgeGlow: 2
    property real edgeGlowOpacity: 0.45
    property real tension: 1.0
    property real bellWidth: 0.6

    function tracePath(ctx, baseY, amplitude, dir) {
        const n = heights.length;
        const stepX = width / (n - 1);
        const lo = dir < 0 ? baseY - amplitude : baseY;
        const hi = dir < 0 ? baseY : baseY + amplitude;

        const at = i => baseY + dir * amplitude * heights[Math.max(0, Math.min(n - 1, i))];
        const clamp = v => Math.max(lo, Math.min(hi, v));
        const t = root.tension / 6;

        ctx.beginPath();
        ctx.moveTo(0, baseY);
        ctx.lineTo(0, at(0));

        for (let i = 0; i < n - 1; i++) {
            const x0 = i * stepX;
            const x1 = x0 + stepX;
            const y0 = at(i);
            const y1 = at(i + 1);
            ctx.bezierCurveTo(x0 + 2 * stepX * t, clamp(y0 + (y1 - at(i - 1)) * t), x1 - 2 * stepX * t, clamp(y1 - (at(i + 2) - y0) * t), x1, y1);
        }

        ctx.lineTo(width, baseY);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
    }

    function traceBells(ctx, baseY, amplitude, dir) {
        const n = heights.length;
        const cell = width / n;
        const sigma = root.bellWidth * cell;
        const reach = Math.ceil(3 * root.bellWidth) + 1;

        ctx.beginPath();
        ctx.moveTo(0, baseY);
        for (let x = 0; x <= width; x++) {
            const nearest = Math.floor(x / cell);
            let sum = 0;
            for (let k = nearest - reach; k <= nearest + reach; k++) {
                const d = (x - (k + 0.5) * cell) / sigma;
                const v = heights[((k % n) + n) % n] * Math.exp(-0.5 * d * d);
                sum += v * v;
            }
            ctx.lineTo(x, baseY + dir * amplitude * Math.min(1, Math.sqrt(sum)));
        }
        ctx.lineTo(width, baseY);
        ctx.closePath();
        ctx.fill();
        ctx.stroke();
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        if (heights.length < 2)
            return;

        const c = root.color;
        ctx.strokeStyle = c;
        ctx.lineWidth = root.lineWidth;
        ctx.fillStyle = c;
        ctx.lineCap = 'round';
        ctx.lineJoin = 'round';
        ctx.shadowColor = Qt.rgba(c.r, c.g, c.b, root.edgeGlowOpacity);
        ctx.shadowBlur = root.edgeGlow;

        const trace = root.shape === "bells" ? traceBells : tracePath;
        const baseY = root.mirrored ? height / 2 : height;
        trace(ctx, baseY, baseY - 2, -1);
        if (root.mirrored)
            trace(ctx, baseY, baseY - 2, 1);
    }

    onHeightsChanged: requestPaint()
    onShapeChanged: requestPaint()
    onColorChanged: requestPaint()
    onMirroredChanged: requestPaint()
}
