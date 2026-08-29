import QtQuick
import qs.services

// Hand-drawn weather line-art on Canvas. Everything is painted from
// qs.services palette colors (alpha overlays derived from palette values
// only); `phase` (0..1, advanced by the internal Timer) drives all motion.
Item {
    id: root

    property string kind: "clear"
    property bool isNight: false
    property real phase: 0
    // Unbounded loop counter; `phase` is cycles % 1. Continuous motions
    // (drift, rotation, twinkle) key off `cycles` so nothing jumps when the
    // fall-cycle loop wraps.
    property real cycles: 0

    readonly property color cloudColor: Color.palette.base05
    readonly property color sunColor: Color.palette.base09
    readonly property color moonColor: Color.palette.base0A
    readonly property color rainColor: Color.palette.base0C
    readonly property color snowColor: Color.palette.base07

    // Cloud lobes relative to the cloud anchor, in 128-unit icon space.
    // The five crown lobes are traced as one continuous outline (see
    // traceCloudSilhouette); overlap radii keep the crown seamlessly merged.
    readonly property var cloudPuffs: [
        { x: -30, y: 2, r: 14 },
        { x: -15, y: -9, r: 18 },
        { x: 5, y: -15, r: 20 },
        { x: 24, y: -7, r: 16 },
        { x: 37, y: 3, r: 11 }
    ]

    // Per-drop: x position, cycle offset, streak length, speed multiplier, peak alpha.
    readonly property var rainLight: [
        { x: 36, o: 0.02, l: 6, v: 1.05, a: 0.85 },
        { x: 44, o: 0.57, l: 5, v: 0.85, a: 0.65 },
        { x: 52, o: 0.22, l: 7, v: 1.20, a: 0.90 },
        { x: 61, o: 0.82, l: 5, v: 0.80, a: 0.60 },
        { x: 69, o: 0.41, l: 8, v: 1.10, a: 0.90 },
        { x: 77, o: 0.68, l: 5, v: 0.90, a: 0.65 },
        { x: 85, o: 0.12, l: 7, v: 1.00, a: 0.85 },
        { x: 93, o: 0.93, l: 6, v: 1.25, a: 0.90 }
    ]

    readonly property var rainHeavy: [
        { x: 38, o: 0.04, l: 7, v: 1.50, a: 0.95 },
        { x: 47, o: 0.61, l: 6, v: 1.20, a: 0.80 },
        { x: 56, o: 0.26, l: 9, v: 1.60, a: 0.95 },
        { x: 65, o: 0.84, l: 6, v: 1.30, a: 0.80 },
        { x: 74, o: 0.43, l: 8, v: 1.50, a: 0.90 },
        { x: 83, o: 0.72, l: 6, v: 1.25, a: 0.80 },
        { x: 91, o: 0.35, l: 9, v: 1.70, a: 0.95 }
    ]

    // Per-flake: x, offset, radius, speed, alpha, horizontal wobble amplitude.
    readonly property var snowFlakes: [
        { x: 40, o: 0.05, r: 2.6, v: 1.00, a: 0.90, w: 4.5 },
        { x: 50, o: 0.45, r: 1.8, v: 0.75, a: 0.65, w: 5.5 },
        { x: 61, o: 0.22, r: 3.1, v: 1.15, a: 0.95, w: 3.5 },
        { x: 71, o: 0.68, r: 2.2, v: 0.90, a: 0.80, w: 6.0 },
        { x: 81, o: 0.34, r: 1.5, v: 0.65, a: 0.55, w: 4.0 },
        { x: 89, o: 0.80, r: 2.8, v: 1.25, a: 0.85, w: 5.0 },
        { x: 46, o: 0.58, r: 1.3, v: 0.80, a: 0.45, w: 6.5 },
        { x: 77, o: 0.92, r: 2.0, v: 1.05, a: 0.75, w: 4.8 }
    ]

    // Fog bands: y, half-width, thickness, drift speed, drift amplitude,
    // phase offset, peak alpha.
    readonly property var fogBands: [
        { y: 80, w: 30, h: 9, speed: 0.50, amp: 5, off: 0.0, a: 0.34 },
        { y: 93, w: 24, h: 8, speed: 0.85, amp: 7, off: 2.1, a: 0.27 },
        { y: 105, w: 18, h: 7, speed: 1.20, amp: 6, off: 4.4, a: 0.21 }
    ]

    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    // Soft radial halo; caller owns globalAlpha (alpha lives in the gradient).
    function drawGlow(ctx, x, y, radius, color, alpha) {
        const g = ctx.createRadialGradient(x, y, 0, x, y, radius);
        g.addColorStop(0, root.withAlpha(color, alpha));
        g.addColorStop(1, root.withAlpha(color, 0));
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.arc(x, y, radius, 0, Math.PI * 2);
        ctx.fill();
    }

    // Four-point sparkle with concave sides; saves/restores its own state.
    function drawSparkle(ctx, x, y, radius, alpha, rotation) {
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(rotation);
        ctx.globalAlpha = alpha;
        ctx.fillStyle = Color.palette.base07;
        const k = radius * 0.16;
        ctx.beginPath();
        ctx.moveTo(0, -radius);
        ctx.quadraticCurveTo(k, -k, radius, 0);
        ctx.quadraticCurveTo(k, k, 0, radius);
        ctx.quadraticCurveTo(-k, k, -radius, 0);
        ctx.quadraticCurveTo(-k, -k, 0, -radius);
        ctx.closePath();
        ctx.fill();
        ctx.restore();
    }

    // --- clouds ---------------------------------------------------------------

    // Angle of the upper circle-circle intersection, as seen from each
    // circle. Used to hop from one crown lobe to the next without lifting
    // the pen, keeping the silhouette one continuous closed curve.
    function crownJoint(a, b) {
        const dx = b.x - a.x, dy = b.y - a.y;
        const d = Math.sqrt(dx * dx + dy * dy);
        const l = (a.r * a.r - b.r * b.r + d * d) / (2 * d);
        const h = Math.sqrt(Math.max(0, a.r * a.r - l * l));
        const ux = dx / d, uy = dy / d;
        const y1 = a.y + l * uy + h * ux;
        const y2 = a.y + l * uy - h * ux;
        const jx = y1 <= y2 ? a.x + l * ux - h * uy : a.x + l * ux + h * uy;
        const jy = Math.min(y1, y2);
        return {
            a1: Math.atan2(jy - a.y, jx - a.x),
            a2: Math.atan2(jy - b.y, jx - b.x)
        };
    }

    // The cloud silhouette as ONE closed path: up the left flank, arcs over
    // the five crown lobes, down the right tail, then a single sagging belly
    // curve back to the start. No separate subpaths and no flat rect band,
    // so the bottom edge is one smooth curve - nothing can seam or notch.
    function traceCloudSilhouette(ctx, x0, cy, s) {
        const p = root.cloudPuffs;
        const first = p[0];
        const last = p[p.length - 1];
        ctx.beginPath();
        ctx.moveTo(x0 + first.x * s, cy + (first.y + first.r) * s);
        ctx.arc(x0 + first.x * s, cy + first.y * s, first.r * s, Math.PI / 2, Math.PI);
        let from = Math.PI;
        for (let i = 1; i < p.length; i++) {
            const j = root.crownJoint(p[i - 1], p[i]);
            ctx.arc(x0 + p[i - 1].x * s, cy + p[i - 1].y * s, p[i - 1].r * s, from, j.a1);
            from = j.a2;
        }
        ctx.arc(x0 + last.x * s, cy + last.y * s, last.r * s, from, Math.PI / 2);
        ctx.bezierCurveTo(
            x0 + 20 * s, cy + 20 * s,
            x0 - 12 * s, cy + 21 * s,
            x0 + first.x * s, cy + (first.y + first.r) * s);
        ctx.closePath();
    }

    // One cloud layer: the continuous silhouette is clipped first, then a
    // SOLID body is painted inside it (a shading gradient alone would let
    // the sky show through the middle), followed by lit crown, clamped
    // underbelly, key light and rim light - all confined to the shape.
    // shade: 0 (airy) .. 0.6 (storm-dark). Drift speed/offset differ per
    // layer so stacked clouds never move in lockstep.
    function drawCloudLayer(ctx, cx, cy, s, alpha, driftSpeed, driftOffset, shade) {
        const drift = Math.sin(root.cycles * Math.PI * 2 * driftSpeed + driftOffset) * 2.6;
        const x0 = cx + drift;

        // Halo behind night or storm-dark clouds so they separate from the
        // sky by glow instead of dissolving into it.
        const halo = (root.isNight ? 0.08 : 0) + Math.max(0, shade - 0.4) * 0.45;
        if (halo > 0) {
            ctx.globalAlpha = 1;
            ctx.save();
            ctx.translate(x0, cy + 2 * s);
            ctx.scale(2.1, 1);
            root.drawGlow(ctx, 0, 0, 26 * s, Color.palette.base07, halo * alpha);
            ctx.restore();
        }

        ctx.save();
        ctx.globalAlpha = alpha;
        root.traceCloudSilhouette(ctx, x0, cy, s);
        ctx.clip();

        // Solid body, clearly lighter than the night sky.
        ctx.fillStyle = root.withAlpha(root.cloudColor, 0.93);
        ctx.fillRect(x0 - 50 * s, cy - 40 * s, 104 * s, 64 * s);

        // Lit crown falling off toward the middle.
        const crown = ctx.createLinearGradient(0, cy - 36 * s, 0, cy + 2 * s);
        crown.addColorStop(0, root.withAlpha(Color.palette.base07, 0.40));
        crown.addColorStop(1, root.withAlpha(Color.palette.base07, 0));
        ctx.fillStyle = crown;
        ctx.fillRect(x0 - 50 * s, cy - 40 * s, 104 * s, 64 * s);

        // Weighted underbelly toward base00, clamped so the cloud base
        // never sinks to sky value.
        const belly = ctx.createLinearGradient(0, cy - 4 * s, 0, cy + 19 * s);
        belly.addColorStop(0, root.withAlpha(Color.palette.base00, 0));
        belly.addColorStop(1, root.withAlpha(Color.palette.base00, Math.min(0.45, shade)));
        ctx.fillStyle = belly;
        ctx.fillRect(x0 - 50 * s, cy - 40 * s, 104 * s, 64 * s);

        // Soft key light from the upper left.
        const key = ctx.createRadialGradient(
            x0 - 12 * s, cy - 20 * s, 2,
            x0 - 12 * s, cy - 20 * s, 52 * s);
        key.addColorStop(0, root.withAlpha(Color.palette.base07, 0.18));
        key.addColorStop(1, root.withAlpha(Color.palette.base07, 0));
        ctx.fillStyle = key;
        ctx.fillRect(x0 - 50 * s, cy - 40 * s, 104 * s, 64 * s);

        // Faint definition rim all around; the clip keeps only its inner
        // half, so no light spills onto the sky.
        root.traceCloudSilhouette(ctx, x0, cy, s);
        ctx.strokeStyle = root.withAlpha(Color.palette.base07, 0.30);
        ctx.lineWidth = 1.8 * s;
        ctx.stroke();

        // Crisper crown rim: the same stroke again, brighter, confined to
        // the upper band of the cloud.
        ctx.save();
        ctx.beginPath();
        ctx.rect(x0 - 50 * s, cy - 40 * s, 104 * s, 38 * s);
        ctx.clip();
        root.traceCloudSilhouette(ctx, x0, cy, s);
        ctx.strokeStyle = root.withAlpha(Color.palette.base07, 0.55);
        ctx.lineWidth = 2.2 * s;
        ctx.stroke();
        ctx.restore();

        ctx.restore();
        ctx.globalAlpha = 1;
    }

    // --- sun ------------------------------------------------------------------

    function drawSun(ctx, x, y, s) {
        // Wide ambient halo so the sun melts into the sky instead of
        // floating as a stamped disc.
        root.drawGlow(ctx, x, y, 40 * s, root.sunColor, 0.22);

        // Slowly rotating crown; each ray breathes on its own frequency.
        ctx.save();
        ctx.translate(x, y);
        ctx.rotate(root.cycles * Math.PI * 2 * 0.06);
        ctx.strokeStyle = root.sunColor;
        ctx.lineCap = "round";
        ctx.lineWidth = 2.6 * s;
        for (let i = 0; i < 8; i++) {
            const angle = i * Math.PI / 4;
            const beat = Math.sin(root.cycles * Math.PI * 2 * (0.8 + i * 0.17) + i * 2.3);
            const inner = (21 + beat * 1.4) * s;
            const outer = (29 + beat * 3.4) * s;
            ctx.globalAlpha = 0.55 + 0.35 * (beat * 0.5 + 0.5);
            ctx.beginPath();
            ctx.moveTo(Math.cos(angle) * inner, Math.sin(angle) * inner);
            ctx.lineTo(Math.cos(angle) * outer, Math.sin(angle) * outer);
            ctx.stroke();
        }
        ctx.restore();

        ctx.globalAlpha = 1;

        // Softly glowing core: hot center falling off smoothly to nothing,
        // so there is no hard disc edge anywhere.
        const core = ctx.createRadialGradient(x, y, 0, x, y, 17 * s);
        core.addColorStop(0, root.withAlpha(root.sunColor, 0.95));
        core.addColorStop(0.4, root.withAlpha(root.sunColor, 0.70));
        core.addColorStop(0.75, root.withAlpha(root.sunColor, 0.25));
        core.addColorStop(1, root.withAlpha(root.sunColor, 0));
        ctx.fillStyle = core;
        ctx.beginPath();
        ctx.arc(x, y, 17 * s, 0, Math.PI * 2);
        ctx.fill();

        // Thin deliberate ring floating inside the glow, echoing the cloud's
        // rim light so the core reads drawn, not stamped.
        ctx.strokeStyle = root.withAlpha(root.sunColor, 0.55);
        ctx.lineWidth = 1.6 * s;
        ctx.beginPath();
        ctx.arc(x, y, 10.5 * s, 0, Math.PI * 2);
        ctx.stroke();

        // Whisper of key light from the upper left, inside the ring.
        root.drawGlow(ctx, x - 4 * s, y - 4 * s, 6 * s, Color.palette.base07, 0.35);
        ctx.globalAlpha = 1;
    }

    // --- moon -----------------------------------------------------------------

    // starSide: +1 places companion stars right of the crescent (clear sky),
    // -1 mirrors them left so they stay clear of the foreground cloud in
    // partly-cloudy nights.
    function drawMoon(ctx, x, y, s, starSide) {
        const side = starSide === undefined ? 1 : starSide;
        const bob = Math.sin(root.cycles * Math.PI * 2) * 2;

        // Twinkling stars first; they sit behind the halo wash and any cloud.
        const stars = [
            { x: 30, y: -24, r: 4.2, freq: 0.8, off: 0.0 },
            { x: 40, y: -3, r: 3.0, freq: 1.35, off: 2.1 },
            { x: 30, y: 19, r: 2.4, freq: 1.1, off: 4.2 }
        ];
        ctx.save();
        ctx.translate(x, y + bob * 0.35);
        ctx.scale(s, s);
        for (let i = 0; i < stars.length; i++) {
            const st = stars[i];
            const twinkle = 0.35 + 0.65 * (0.5 + 0.5 * Math.sin(root.cycles * Math.PI * 2 * st.freq + st.off));
            root.drawSparkle(ctx, side * st.x, st.y, st.r, twinkle, root.cycles * Math.PI * 0.25 * (i + 1));
        }
        ctx.restore();

        // Crescent with a soft halo. The bite is carved with destination-out
        // (safe: nothing else is painted here yet); a whisper of halo is then
        // laid back under the bite with destination-over so the glow never
        // shows a hard inner edge.
        ctx.save();
        ctx.translate(x, y + bob);
        ctx.scale(s, s);

        root.drawGlow(ctx, 0, 0, 38, root.moonColor, 0.16);
        ctx.fillStyle = root.moonColor;
        ctx.beginPath();
        ctx.arc(0, 0, 26, 0, Math.PI * 2);
        ctx.fill();

        ctx.globalCompositeOperation = "destination-out";
        ctx.beginPath();
        ctx.arc(10, -6, 24, 0, Math.PI * 2);
        ctx.fill();

        ctx.globalCompositeOperation = "destination-over";
        root.drawGlow(ctx, 0, 0, 36, root.moonColor, 0.07);
        ctx.globalCompositeOperation = "source-over";

        // Subtle crater shading on the crescent body (clear of the bite).
        ctx.fillStyle = root.withAlpha(Color.palette.base00, 0.20);
        const craters = [
            { x: -14, y: 8, r: 3.2 },
            { x: -7, y: 15, r: 2.1 },
            { x: -19, y: -2, r: 1.8 }
        ];
        for (let i = 0; i < craters.length; i++) {
            ctx.beginPath();
            ctx.arc(craters[i].x, craters[i].y, craters[i].r, 0, Math.PI * 2);
            ctx.fill();
        }
        ctx.restore();
        ctx.globalAlpha = 1;
    }

    // --- precipitation --------------------------------------------------------

    // count: optional cap on particles, so layered kinds (sleet) can thin
    // each contributor instead of stacking full-density bands.
    function drawRain(ctx, heavy, count) {
        const drops = heavy ? root.rainHeavy : root.rainLight;
        const n = count === undefined ? drops.length : Math.min(count, drops.length);
        ctx.strokeStyle = root.rainColor;
        ctx.lineCap = "round";
        ctx.lineWidth = heavy ? 2.3 : 2;
        for (let i = 0; i < n; i++) {
            const d = drops[i];
            const p = (root.phase * d.v + d.o) % 1;
            const y = 73 + p * 26;
            const x = d.x + Math.sin(p * Math.PI * 2 + d.o * 9) * 0.8;
            const slant = d.l * 0.34;
            ctx.globalAlpha = d.a * (0.15 + 0.85 * Math.sin(p * Math.PI));
            ctx.moveTo(x + slant * 0.35, y);
            ctx.lineTo(x - slant * 0.65, y + d.l);
            ctx.stroke();
        }
        ctx.globalAlpha = 1;
    }

    function drawSnow(ctx, count) {
        const n = count === undefined ? root.snowFlakes.length : Math.min(count, root.snowFlakes.length);
        for (let i = 0; i < n; i++) {
            const f = root.snowFlakes[i];
            const p = (root.phase * f.v + f.o) % 1;
            const x = f.x + Math.sin(p * Math.PI * 2 * 1.3 + f.o * 7) * f.w;
            const y = 76 + p * 26;
            const a = f.a * (0.3 + 0.7 * Math.sin(p * Math.PI));

            if (i === 2) {
                ctx.globalAlpha = 1;
                root.drawGlow(ctx, x, y, f.r * 2.4, root.snowColor, a * 0.2);
                root.drawSparkle(ctx, x, y, f.r * 2.1, a * 0.9, root.cycles * Math.PI * 2 * 0.2);
            } else {
                ctx.globalAlpha = 1;
                root.drawGlow(ctx, x, y, f.r * 2.2, root.snowColor, a * 0.16);
                ctx.globalAlpha = a;
                ctx.fillStyle = root.snowColor;
                ctx.beginPath();
                ctx.arc(x, y, f.r, 0, Math.PI * 2);
                ctx.fill();
            }
        }
        ctx.globalAlpha = 1;
    }

    // Ice pellets for freezing rain: small glinting beads falling with the
    // rain, tinted by the rain color so they read as frozen, not snowy.
    readonly property var icePellets: [
        { x: 45, o: 0.15, r: 2.2, v: 1.10 },
        { x: 63, o: 0.55, r: 2.6, v: 0.90 },
        { x: 81, o: 0.35, r: 2.0, v: 1.25 },
        { x: 93, o: 0.75, r: 2.4, v: 0.80 }
    ]

    function drawIce(ctx) {
        for (let i = 0; i < root.icePellets.length; i++) {
            const f = root.icePellets[i];
            const p = (root.phase * f.v + f.o) % 1;
            const x = f.x + Math.sin(p * Math.PI * 2 + f.o * 5) * 1.5;
            const y = 76 + p * 26;
            const a = 0.9 * (0.3 + 0.7 * Math.sin(p * Math.PI));
            root.drawGlow(ctx, x, y, f.r * 2.2, root.rainColor, a * 0.25);
            ctx.globalAlpha = a;
            ctx.fillStyle = root.rainColor;
            ctx.beginPath();
            ctx.arc(x, y, f.r, 0, Math.PI * 2);
            ctx.fill();
        }
        ctx.globalAlpha = 1;
    }

    // --- storm ----------------------------------------------------------------

    // Irregular-ish strike schedule: the phase loop is split into three
    // slots; each slot gets a deterministic pseudo-random start, width and
    // intensity, so strikes land at uneven times with restrike flicker.
    function flashState() {
        const idx = Math.floor(root.cycles * 3);
        const local = root.cycles * 3 - idx;
        const seed = Math.abs(Math.sin(idx * 91.7 + 3.7));
        if (seed < 0.3)
            return { v: 0, t: 0 };
        const start = 0.12 + seed * 0.6;
        const w = 0.09 + seed * 0.05;
        if (local < start || local > start + w)
            return { v: 0, t: 0 };
        const t = (local - start) / w;
        let v;
        if (t < 0.18)
            v = t / 0.18;
        else if (t < 0.45)
            v = 1 - ((t - 0.18) / 0.27) * 0.65;
        else if (t < 0.60)
            v = 0.35 + ((t - 0.45) / 0.15) * 0.55;
        else
            v = 0.9 * (1 - (t - 0.60) / 0.40);
        return { v: v * (0.75 + 0.25 * seed), t: t };
    }

    function traceBolt(ctx) {
        ctx.beginPath();
        ctx.moveTo(58, 70);
        ctx.lineTo(67, 80);
        ctx.lineTo(61, 82);
        ctx.lineTo(70, 92);
        ctx.lineTo(64, 94);
        ctx.lineTo(71, 104);
        ctx.moveTo(61, 82);
        ctx.lineTo(52, 88);
        ctx.moveTo(70, 92);
        ctx.lineTo(79, 98);
    }

    function drawLightning(ctx) {
        const flash = root.flashState();
        if (flash.v <= 0.01)
            return;

        // Faint scene flash around the bolt.
        ctx.globalAlpha = 1;
        root.drawGlow(ctx, 64, 87, 46, Color.palette.base07, flash.v * 0.07);
        // Bolt grows top-down through the first part of the strike.
        ctx.save();
        ctx.beginPath();
        ctx.rect(40, 66, 50, 40 * Math.min(1, flash.t / 0.38));
        ctx.lineCap = "round";
        ctx.lineJoin = "round";

        ctx.globalAlpha = flash.v * 0.35;
        ctx.strokeStyle = root.moonColor;
        ctx.lineWidth = 7;
        root.traceBolt(ctx);
        ctx.stroke();

        ctx.globalAlpha = flash.v;
        ctx.strokeStyle = Color.palette.base07;
        ctx.lineWidth = 2.4;
        root.traceBolt(ctx);
        ctx.stroke();

        ctx.restore();
        ctx.globalAlpha = 1;
    }

    // --- fog ------------------------------------------------------------------

    function drawFog(ctx) {
        for (let i = 0; i < root.fogBands.length; i++) {
            const b = root.fogBands[i];
            const drift = Math.sin(root.cycles * Math.PI * 2 * b.speed + b.off) * b.amp;
            const breathe = b.a * (0.85 + 0.15 * Math.sin(root.cycles * Math.PI * 2 * b.speed * 1.3 + b.off));
            const x0 = 64 - b.w + drift;
            const x1 = 64 + b.w + drift;
            const g = ctx.createLinearGradient(x0, 0, x1, 0);
            g.addColorStop(0, root.withAlpha(root.cloudColor, 0));
            g.addColorStop(0.5, root.withAlpha(root.cloudColor, breathe));
            g.addColorStop(1, root.withAlpha(root.cloudColor, 0));
            ctx.globalAlpha = 1;
            ctx.strokeStyle = g;
            ctx.lineWidth = b.h;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.moveTo(x0, b.y);
            ctx.lineTo(x1, b.y);
            ctx.stroke();
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
                // Sun and moon are scaled up to match the visual mass of
                // the cloud compositions (~92 units wide), so every kind
                // fills the icon box uniformly.
                if (root.isNight)
                    root.drawMoon(ctx, 64, 62, 1.35);
                else
                    root.drawSun(ctx, 64, 62, 1.35);
                return;
            }

            if (root.kind === "partlyCloudy") {
                if (root.isNight)
                    root.drawMoon(ctx, 40, 48, 0.9, -1);
                else
                    root.drawSun(ctx, 40, 48, 0.9);
                root.drawCloudLayer(ctx, 80, 76, 0.78, 1, 0.5, 1.2, 0.35);
                return;
            }

            if (root.kind === "fog") {
                root.drawCloudLayer(ctx, 64, 52, 0.95, 0.9, 0.4, 0, 0.35);
                root.drawFog(ctx);
                return;
            }

            if (root.kind === "cloudy") {
                root.drawCloudLayer(ctx, 40, 46, 0.55, 0.55, 0.45, 2.6, 0.30);
                root.drawCloudLayer(ctx, 64, 68, 1, 1, 0.3, 0, 0.38);
                return;
            }

            // rain / snow / storm / sleet / freezingRain / thunderSnow all
            // share the stacked cloud base; precipitation layers on top.
            const dark = root.kind === "storm" || root.kind === "thunderSnow";
            root.drawCloudLayer(ctx, 38, 34, 0.5, 0.5, 0.5, 2.2, 0.30);
            root.drawCloudLayer(ctx, 64, 52, 1, 1, 0.32, 0, dark ? 0.55 : 0.40);

            if (root.kind === "storm") {
                root.drawCloudLayer(ctx, 66, 62, 0.8, 0.9, 0.22, 3.3, 0.50);
                root.drawRain(ctx, true);
                root.drawLightning(ctx);
            } else if (root.kind === "thunderSnow") {
                root.drawCloudLayer(ctx, 66, 62, 0.8, 0.9, 0.22, 3.3, 0.50);
                root.drawSnow(ctx, 5);
                root.drawLightning(ctx);
            } else if (root.kind === "snow") {
                root.drawSnow(ctx);
            } else if (root.kind === "sleet") {
                // Mixed wintry precipitation: thinned rain and snow bands
                // interleaved under one cloud.
                root.drawRain(ctx, false, 5);
                root.drawSnow(ctx, 5);
            } else if (root.kind === "freezingRain") {
                root.drawRain(ctx, false, 6);
                root.drawIce(ctx);
            } else {
                root.drawRain(ctx, false);
            }
        }
    }

    Timer {
        interval: 80
        running: root.visible
        repeat: true
        onTriggered: {
            root.cycles += 0.0128;
            root.phase = root.cycles % 1;
            canvas.requestPaint();
        }
    }

    onKindChanged: canvas.requestPaint()
    onIsNightChanged: canvas.requestPaint()
}
