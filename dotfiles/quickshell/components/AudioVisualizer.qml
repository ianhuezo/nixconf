import QtQuick
import Quickshell.Io
import qs.services
import qs.config

Item {
    id: root

    // Common properties
    property var cavaValues: []
    property color visualizerColor: 'white'
    property bool mirrored: true
    property real sensitivity: 1.0

    // Mode selection: "wave", "bars", or "title"
    property string mode: "wave"
    property var modes: ["wave", "bars", "title"]

    // Wave-specific properties
    property int lineWidth: 1
    // Catmull-Rom tension. 1.0 is the standard spline; lower tightens the curve
    // toward straight segments.
    property real waveTension: 1.0
    // Blend of each bin with its two neighbours before drawing, 0 = raw bins.
    property real waveSmoothing: 0.1
    // The reference level the wave is normalized against, tracked with a fast
    // attack and slow release. Normalizing against the current frame's max
    // rescales the whole wave every frame, which reads as breathing rather
    // than as the music getting louder and quieter.
    property real waveLevelAttack: 0.1
    property real waveLevelRelease: 0.02
    property real waveMinLevel: 15
    // Headroom above the tracked level before a sample reaches full height, so
    // topping out stays an event rather than the steady state.
    property real waveHeadroom: 1.45
    // How hard the frame's overall loudness is compressed, below 1. This lifts
    // quiet passages and damps loud ones over time.
    property real waveGamma: 0.42
    // How hard the shape across frequency is compressed, kept much closer to 1
    // than waveGamma. Compressing the spectrum as hard as the loudness levels
    // the bands against each other and the bass, mids and treble stop being
    // tellable apart; lower this to lift quiet bands at the cost of that.
    property real waveSpectralExponent: 0.85
    // Subtracted from every bin before scaling, so the noise that cava reports
    // during silence stays on the baseline instead of being amplified by the
    // exponents along with everything else.
    property real waveNoiseFloor: 1.0
    // Emphasis on the vocal band, applied before the wave is normalized so the
    // boost changes what dominates rather than just scaling everything. Centre
    // and width are fractions across the spectrum; cava's bins are log-spaced,
    // so with its 50Hz-10kHz default range 0.58 sits around 1kHz and the width
    // covers roughly 300Hz-3.5kHz, where voices carry.
    property real waveVoiceGain: 1.8
    property real waveVoiceCenter: 0.58
    property real waveVoiceWidth: 0.22

    // Bar-specific properties
    property int barWidth: 6
    property int barSpacing: 2
    property int barRadius: 2

    // Title-specific properties
    property string title: ""
    property int titlePauseDuration: 1500
    property real titleScrollPixelsPerSecond: 18
    property int titleScrollMinDuration: 4500
    // Symmetric ease with cp1y/cp2y pulled inward from {0,1}. Pure {0,1} on the
    // y-axis pins the velocity to 0 at the endpoints, which produces a long
    // crawl into the stop and forces the middle to peak high (1.82x avg) to
    // make up the area. Pulling to {0.1, 0.9} drops the middle peak to ~1.5x
    // and roughly doubles the velocity near t=1, so the text stops decisively.
    readonly property var titleScrollCurve: [0.4, 0.1, 0.6, 0.9, 1, 1]

    Loader {
        id: visualizerLoader
        anchors.fill: parent
        sourceComponent: {
            switch (root.mode) {
            case "wave":
                return waveComponent;
            case "bars":
                return barsComponent;
            case "title":
                return titleComponent;
            }
        }
    }

    Component {
        id: titleComponent
        Item {
            id: scrollingTitle
            anchors.fill: parent
            clip: true

            // text x = start - delta; increasing delta scrolls left, revealing
            // the right side of the text. Capped at maxDelta so the right side
            // never retracts past `end`.
            property real start: 0
            property real end: width
            property real delta: 0
            property real maxDelta: Math.max(0, titleText.implicitWidth - (end - start))
            property bool needsScroll: titleText.implicitWidth > (end - start) && root.title.length > 0
            // Constant px/sec keeps long titles from feeling rushed; min duration
            // prevents flashes for tiny overflows.
            property int scrollDuration: Math.max(root.titleScrollMinDuration, Math.round(maxDelta / root.titleScrollPixelsPerSecond * 1000))

            Text {
                id: titleText
                text: root.title
                color: root.visualizerColor
                font.family: AppearanceConfig.font.mono
                font.pixelSize: AppearanceConfig.font.size.sm
                font.weight: AppearanceConfig.font.weight.medium
                x: scrollingTitle.start - scrollingTitle.delta
                anchors.verticalCenter: parent.verticalCenter
            }

            Connections {
                target: root
                function onTitleChanged() {
                    scrollingTitle.delta = 0;
                }
            }

            onNeedsScrollChanged: if (!needsScroll) delta = 0

            SequentialAnimation on delta {
                running: scrollingTitle.needsScroll
                loops: Animation.Infinite
                alwaysRunToEnd: false

                PauseAnimation {
                    duration: root.titlePauseDuration
                }
                NumberAnimation {
                    from: 0
                    to: scrollingTitle.maxDelta
                    duration: scrollingTitle.scrollDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.titleScrollCurve
                }
                PauseAnimation {
                    duration: root.titlePauseDuration
                }
                NumberAnimation {
                    from: scrollingTitle.maxDelta
                    to: 0
                    duration: scrollingTitle.scrollDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.titleScrollCurve
                }
            }
        }
    }

    Component {
        id: waveComponent
        Canvas {
            id: wave
            anchors.fill: parent

            property real level: root.waveMinLevel

            // Blends each bin with its neighbours so the curve follows the
            // spectrum envelope rather than the per-bin noise.
            function envelope(values) {
                const n = values.length;
                const k = root.waveSmoothing;
                const out = new Array(n);
                for (let i = 0; i < n; i++) {
                    const prev = values[Math.max(0, i - 1)];
                    const next = values[Math.min(n - 1, i + 1)];
                    out[i] = (1 - k) * values[i] + k * 0.5 * (prev + next);
                }
                return out;
            }

            // Traces a closed shape from the baseline through the samples as a
            // Catmull-Rom spline. Tangents follow the neighbouring samples, so
            // peaks stay pointed and the curve flows between them instead of
            // flattening out at every data point.
            function tracePath(ctx, heights, baseY, amplitude, dir) {
                const n = heights.length;
                const stepX = width / (n - 1);
                const lo = dir < 0 ? baseY - amplitude : baseY;
                const hi = dir < 0 ? baseY : baseY + amplitude;

                const at = i => baseY + dir * amplitude * heights[Math.max(0, Math.min(n - 1, i))];
                const clamp = v => Math.max(lo, Math.min(hi, v));
                const t = root.waveTension / 6;

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

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (root.cavaValues.length < 2)
                    return;

                const points = envelope(root.cavaValues);
                const n = points.length;
                const attack = root.waveLevelAttack;
                const release = root.waveLevelRelease;

                const signal = new Array(n);
                const boost = root.waveVoiceGain - 1;
                let peak = 0;
                for (let i = 0; i < n; i++) {
                    const offset = (n > 1 ? i / (n - 1) : 0) - root.waveVoiceCenter;
                    const emphasis = 1 + boost * Math.exp(-0.5 * Math.pow(offset / root.waveVoiceWidth, 2));
                    signal[i] = Math.max(0, points[i] * root.sensitivity - root.waveNoiseFloor) * emphasis;
                    peak = Math.max(peak, signal[i]);
                }

                wave.level = Math.max(root.waveMinLevel, wave.level + (peak - wave.level) * (peak > wave.level ? attack : release));

                // How tall the frame gets is a question about loudness; how the
                // wave is shaped across it is a question about the spectrum.
                // Compressing them separately keeps quiet passages visible
                // without levelling the bands into one flat slab.
                const loudness = Math.pow(Math.min(1, peak / (wave.level * root.waveHeadroom)), root.waveGamma);
                const heights = new Array(n);
                for (let i = 0; i < n; i++)
                    heights[i] = peak > 0 ? loudness * Math.pow(signal[i] / peak, root.waveSpectralExponent) : 0;

                const baseY = root.mirrored ? height / 2 : height;

                ctx.strokeStyle = root.visualizerColor;
                ctx.lineWidth = root.lineWidth;
                ctx.fillStyle = root.visualizerColor;
                ctx.lineCap = 'round';
                ctx.lineJoin = 'round';

                tracePath(ctx, heights, baseY, baseY - 2, -1);
                if (root.mirrored)
                    tracePath(ctx, heights, baseY, baseY - 2, 1);
            }

            Component.onCompleted: requestPaint()

            Connections {
                target: root
                function onCavaValuesChanged() {
                    wave.requestPaint();
                }
            }
        }
    }

    Component {
        id: barsComponent
        Item {
            id: bars
            anchors.fill: parent

            // The bar count follows cava's, so size the bars to the pane rather
            // than to a fixed width that only fits one particular count.
            readonly property int count: root.cavaValues.length
            readonly property real slotWidth: count > 0 ? Math.max(1, Math.min(root.barWidth, (width - (count - 1) * root.barSpacing) / count)) : root.barWidth

            Row {
                id: topRow
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: root.mirrored ? parent.verticalCenter : parent.bottom
                spacing: root.barSpacing

                Repeater {
                    model: root.cavaValues
                    delegate: Rectangle {
                        width: bars.slotWidth
                        height: Math.min(root.mirrored ? bars.height / 2 : bars.height, Math.max(2, modelData * root.sensitivity))
                        color: root.visualizerColor
                        radius: root.barRadius
                        topLeftRadius: root.barRadius
                        topRightRadius: root.barRadius
                        bottomLeftRadius: root.mirrored ? 0 : root.barRadius
                        bottomRightRadius: root.mirrored ? 0 : root.barRadius
                        anchors.bottom: parent.bottom

                        Behavior on height {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }

            Row {
                id: bottomRow
                visible: root.mirrored
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.verticalCenter
                spacing: root.barSpacing

                Repeater {
                    model: root.cavaValues
                    delegate: Rectangle {
                        width: bars.slotWidth
                        height: Math.min(bars.height / 2, Math.max(2, modelData * root.sensitivity))
                        color: root.visualizerColor
                        radius: root.barRadius
                        topLeftRadius: root.mirrored ? 0 : root.barRadius
                        topRightRadius: root.mirrored ? 0 : root.barRadius
                        bottomLeftRadius: root.barRadius
                        bottomRightRadius: root.barRadius
                        anchors.top: parent.top

                        Behavior on height {
                            NumberAnimation {
                                duration: 100
                                easing.type: Easing.OutQuad
                            }
                        }
                    }
                }
            }
        }
    }
}
