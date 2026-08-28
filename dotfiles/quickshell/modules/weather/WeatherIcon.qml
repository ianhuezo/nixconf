import QtQuick
import qs.services

Item {
    id: root

    property string kind: "clear"
    property bool isNight: false
    property real phase: 0

    readonly property color cloudColor: Color.palette.base05
    readonly property color sunColor: Color.palette.base09
    readonly property color moonColor: Color.palette.base0A
    readonly property color rainColor: Color.palette.base0C
    readonly property color snowColor: Color.palette.base07

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    function drawCircle(ctx, x, y, radius, color, alpha) {
        ctx.globalAlpha = alpha;
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, Math.PI * 2);
        ctx.fill();
        ctx.globalAlpha = 1;
    }

    function drawSun(ctx, x, y, scale) {
        const pulse = 1 + Math.sin(phase * Math.PI * 2) * 0.04;
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(phase * Math.PI * 0.4);
        ctx.strokeStyle = sunColor;
        ctx.lineWidth = 3 * scale;
        ctx.lineCap = "round";
        for (let i = 0; i < 8; i++) {
            ctx.rotate(Math.PI / 4);
            ctx.beginPath();
            ctx.moveTo(24 * scale, 0);
            ctx.lineTo(31 * scale, 0);
            ctx.stroke();
        }
        ctx.restore();
        drawCircle(ctx, x, y, 18 * scale * pulse, sunColor, 0.95);
    }

    function drawMoon(ctx, x, y, scale) {
        const bob = Math.sin(phase * Math.PI * 2) * 2;

        ctx.save();
        ctx.translate(x, y + bob);
        ctx.scale(scale, scale);

        ctx.fillStyle = moonColor;
        ctx.beginPath();
        ctx.arc(0, 0, 27, 0, Math.PI * 2);
        ctx.fill();

        ctx.globalCompositeOperation = "destination-out";
        ctx.beginPath();
        ctx.arc(11, -7, 25, 0, Math.PI * 2);
        ctx.fill();
        ctx.globalCompositeOperation = "source-over";
        ctx.restore();

        const stars = [
            { x: 27, y: -22, radius: 4.5 },
            { x: 38, y: -2, radius: 3 },
            { x: 28, y: 19, radius: 2.5 }
        ];
        for (let i = 0; i < stars.length; i++) {
            const star = stars[i];
            const twinkle = 0.4 + 0.6 * Math.abs(Math.sin(phase * Math.PI * 2 + i * 1.7));
            const radius = star.radius * scale * (0.88 + twinkle * 0.12);
            const starX = x + star.x * scale;
            const starY = y + bob * 0.35 + star.y * scale;

            ctx.globalAlpha = twinkle;
            ctx.fillStyle = Color.palette.base07;
            ctx.beginPath();
            ctx.moveTo(starX, starY - radius);
            ctx.lineTo(starX + radius * 0.28, starY - radius * 0.28);
            ctx.lineTo(starX + radius, starY);
            ctx.lineTo(starX + radius * 0.28, starY + radius * 0.28);
            ctx.lineTo(starX, starY + radius);
            ctx.lineTo(starX - radius * 0.28, starY + radius * 0.28);
            ctx.lineTo(starX - radius, starY);
            ctx.lineTo(starX - radius * 0.28, starY - radius * 0.28);
            ctx.closePath();
            ctx.fill();
        }
        ctx.globalAlpha = 1;
    }

    function drawCloud(ctx, x, y, alpha) {
        const drift = Math.sin(phase * Math.PI * 2) * 2.5;
        x += drift;

        drawCircle(ctx, x - 22, y - 8, 17, root.cloudColor, alpha);
        drawCircle(ctx, x, y - 14, 19, root.cloudColor, alpha);
        drawCircle(ctx, x + 22, y - 8, 16, root.cloudColor, alpha);
        drawCircle(ctx, x, y + 2, 12, root.cloudColor, alpha);
        drawCircle(ctx, x - 13, y + 4, 10, root.cloudColor, alpha);
        drawCircle(ctx, x + 13, y + 4, 10, root.cloudColor, alpha);
    }

    function drawRain(ctx, heavy) {
        const drops = heavy
            ? [
                { x: 38, offset: 0.04, length: 6 },
                { x: 46, offset: 0.61, length: 5 },
                { x: 54, offset: 0.26, length: 7 },
                { x: 78, offset: 0.84, length: 5 },
                { x: 86, offset: 0.43, length: 6 },
                { x: 92, offset: 0.72, length: 5 }
            ]
            : [
                { x: 38, offset: 0.04, length: 5 },
                { x: 45, offset: 0.57, length: 6 },
                { x: 52, offset: 0.22, length: 5 },
                { x: 59, offset: 0.82, length: 7 },
                { x: 66, offset: 0.41, length: 5 },
                { x: 73, offset: 0.68, length: 6 },
                { x: 80, offset: 0.12, length: 5 },
                { x: 86, offset: 0.93, length: 7 },
                { x: 92, offset: 0.35, length: 5 }
            ];
        const speed = heavy ? 2.25 : 1.8;
        const slant = heavy ? 2.2 : 1.6;

        ctx.strokeStyle = rainColor;
        ctx.lineWidth = heavy ? 2.2 : 2;
        ctx.lineCap = "round";
        for (let i = 0; i < drops.length; i++) {
            const drop = drops[i];
            const progress = (phase * speed + drop.offset) % 1;
            const x = drop.x + Math.sin(progress * Math.PI * 2 + i) * 0.6;
            const y = 83 + progress * 29;
            const fade = Math.sin(progress * Math.PI);

            ctx.globalAlpha = 0.18 + fade * 0.82;
            ctx.beginPath();
            ctx.moveTo(x + slant * 0.2, y);
            ctx.lineTo(x - slant, y + drop.length);
            ctx.stroke();
        }
        ctx.globalAlpha = 1;
    }

    function traceLightning(ctx) {
        ctx.beginPath();
        ctx.moveTo(66, 77);
        ctx.lineTo(60, 88);
        ctx.lineTo(64, 91);
        ctx.lineTo(56, 104);
        ctx.lineTo(59, 107);
        ctx.lineTo(50, 121);

        ctx.moveTo(60, 88);
        ctx.lineTo(50, 94);
        ctx.lineTo(45, 102);

        ctx.moveTo(56, 104);
        ctx.lineTo(69, 109);
        ctx.lineTo(75, 117);
    }

    function drawLightning(ctx) {
        const cycle = (phase * 2) % 1;
        if (cycle >= 0.24)
            return;

        const growth = Math.min(1, cycle / 0.035);
        let visibility;
        if (cycle < 0.035)
            visibility = cycle / 0.035;
        else if (cycle < 0.075)
            visibility = 1 - ((cycle - 0.035) / 0.04) * 0.72;
        else if (cycle < 0.105)
            visibility = 0.28 + ((cycle - 0.075) / 0.03) * 0.62;
        else
            visibility = 0.9 * (1 - (cycle - 0.105) / 0.135);

        drawCircle(ctx, 64, 82, 48, snowColor, visibility * 0.075);

        ctx.save();
        ctx.beginPath();
        ctx.rect(27, 75, 74, 47 * growth);
        ctx.clip();
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        ctx.globalAlpha = visibility * 0.2;
        ctx.strokeStyle = moonColor;
        ctx.lineWidth = 7;
        traceLightning(ctx);
        ctx.stroke();

        ctx.globalAlpha = visibility;
        ctx.strokeStyle = snowColor;
        ctx.lineWidth = 2.4;
        traceLightning(ctx);
        ctx.stroke();

        ctx.restore();
        ctx.globalAlpha = 1;
    }

    function drawSnow(ctx) {
        ctx.strokeStyle = snowColor;
        ctx.lineWidth = 1.5;
        ctx.lineCap = "round";
        for (let i = 0; i < 5; i++) {
            const progress = (phase * 0.8 + i * 0.2) % 1;
            const x = 39 + i * 13 + Math.sin(progress * Math.PI * 2 + i) * 4;
            const y = 83 + progress * 35;
            const radius = 3;
            ctx.globalAlpha = 0.35 + (1 - progress) * 0.65;
            for (let arm = 0; arm < 3; arm++) {
                const angle = arm * Math.PI / 3;
                ctx.beginPath();
                ctx.moveTo(x - Math.cos(angle) * radius, y - Math.sin(angle) * radius);
                ctx.lineTo(x + Math.cos(angle) * radius, y + Math.sin(angle) * radius);
                ctx.stroke();
            }
        }
        ctx.globalAlpha = 1;
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const sx = width / 128;
            const sy = height / 128;
            ctx.scale(sx, sy);

            if (root.kind === "clear") {
                if (root.isNight)
                    root.drawMoon(ctx, 64, 62, 1);
                else
                    root.drawSun(ctx, 64, 62, 1);
                return;
            }

            if (root.kind === "partlyCloudy") {
                if (root.isNight)
                    root.drawMoon(ctx, 42, 42, 0.72);
                else
                    root.drawSun(ctx, 42, 42, 0.72);
                root.drawCloud(ctx, 74, 68, 1);
                return;
            }

            if (root.kind === "fog") {
                root.drawCloud(ctx, 64, 63, 1);
                const drift = Math.sin(root.phase * Math.PI * 2) * 2;
                const wave = Math.sin(root.phase * Math.PI * 2) * 3;
                const mist = ctx.createLinearGradient(24, 0, 108, 0);
                mist.addColorStop(0, root.withAlpha(root.cloudColor, 0));
                mist.addColorStop(0.5, root.withAlpha(root.cloudColor, 0.4));
                mist.addColorStop(1, root.withAlpha(root.cloudColor, 0));
                ctx.fillStyle = mist;
                ctx.beginPath();
                ctx.moveTo(24 + drift, 98 + wave);
                ctx.bezierCurveTo(44 + drift, 82 + wave, 56 + drift, 100 + wave, 76 + drift, 86 + wave);
                ctx.bezierCurveTo(92 + drift, 78 + wave, 100 + drift, 84 + wave, 108 + drift, 92 + wave);
                ctx.lineTo(108 + drift, 122 + wave);
                ctx.bezierCurveTo(96 + drift, 130 + wave, 84 + drift, 112 + wave, 64 + drift, 122 + wave);
                ctx.bezierCurveTo(44 + drift, 130 + wave, 34 + drift, 124 + wave, 24 + drift, 114 + wave);
                ctx.closePath();
                ctx.fill();
                return;
            }

            if (root.kind === "cloudy") {
                root.drawCloud(ctx, 64, 63, 1);
                return;
            }

            root.drawCloud(ctx, 64, 63, 1);
            if (root.kind === "snow") {
                root.drawSnow(ctx);
            } else {
                root.drawRain(ctx, root.kind === "storm");
            }

            if (root.kind === "storm")
                root.drawLightning(ctx);
        }
    }

    Timer {
        interval: 80
        running: root.visible
        repeat: true
        onTriggered: {
            root.phase = (root.phase + 0.0128) % 1;
            canvas.requestPaint();
        }
    }

    onKindChanged: canvas.requestPaint()
    onIsNightChanged: canvas.requestPaint()
}
