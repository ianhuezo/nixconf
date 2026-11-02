import QtQuick
import Quickshell.Io
import qs.services
import qs.config

Item {
    id: root

    property var cavaValues: []
    property color visualizerColor: 'white'
    property bool mirrored: true
    property real sensitivity: 1.0

    property string mode: AppearanceConfig.defaultVisualizerMode
    property var modes: ["chroma", "piano", "synth", "wave", "bars", "title"]

    property real waveSmoothing: 0.1
    property real waveLevelAttack: 0.1
    property real waveLevelRelease: 0.02
    property real waveMinLevel: 15
    property real waveHeadroom: 1.45
    property real waveGamma: 0.42
    property real waveSpectralExponent: 0.85
    property real waveNoiseFloor: 1.0
    property real waveVoiceGain: 1.8
    property real waveVoiceCenter: 0.58
    property real waveVoiceWidth: 0.22

    property var chromaValues: []
    property var noteValues: []
    property real noteLevelAttack: 0.3
    property real noteLevelRelease: 0.01
    property real noteMinLevelDb: -50
    property real noteHeadroomDb: 6
    property real noteLoudnessRangeDb: 30
    property real noteFloorQuantile: 0.3
    property real noteMinSpanDb: 6
    property real noteShapeExponent: 1.5
    property real noteRise: 0.42
    property real noteFall: 0.18

    property int synthVoices: 4
    property real synthBaseCycles: 2
    property real synthScrollSpeed: 0.12 // widths per second
    property real synthLineWidth: 1.5
    property real synthFillOpacity: 0.3
    property real synthAttack: 0.5
    property real synthRelease: 0.15
    property real synthVoiceHold: 0.5
    property real synthVoiceCurve: 0.5
    property real synthPeakAttack: 0.15
    property real synthPeakRelease: 0.03
    property real synthHeadroomDb: 0

    property int barWidth: 6
    property int barSpacing: 2
    property int barRadius: 2

    property string title: ""
    property int titlePauseDuration: 1500
    property real titleScrollPixelsPerSecond: 18
    property int titleScrollMinDuration: 4500
    readonly property var titleScrollCurve: [0.4, 0.1, 0.6, 0.9, 1, 1]

    function waveHeights(values, trackedLevel) {
        const n = values.length;
        if (n < 2)
            return {
                heights: [],
                level: trackedLevel
            };

        const k = root.waveSmoothing;
        const boost = root.waveVoiceGain - 1;
        const signal = new Array(n);
        let peak = 0;
        for (let i = 0; i < n; i++) {
            const point = (1 - k) * values[i] + k * 0.5 * (values[Math.max(0, i - 1)] + values[Math.min(n - 1, i + 1)]);
            const offset = i / (n - 1) - root.waveVoiceCenter;
            const emphasis = 1 + boost * Math.exp(-0.5 * Math.pow(offset / root.waveVoiceWidth, 2));
            signal[i] = Math.max(0, point * root.sensitivity - root.waveNoiseFloor) * emphasis;
            peak = Math.max(peak, signal[i]);
        }

        const rate = peak > trackedLevel ? root.waveLevelAttack : root.waveLevelRelease;
        const level = Math.max(root.waveMinLevel, trackedLevel + (peak - trackedLevel) * rate);

        const loudness = Math.pow(Math.min(1, peak / (level * root.waveHeadroom)), root.waveGamma);
        return {
            heights: signal.map(v => peak > 0 ? loudness * Math.pow(v / peak, root.waveSpectralExponent) : 0),
            level: level
        };
    }

    function noteHeights(levels, trackedLevel, headroomDb = root.noteHeadroomDb) {
        if (levels.length < 2)
            return {
                heights: [],
                level: trackedLevel
            };

        const peak = Math.max(...levels);
        const rate = peak > trackedLevel ? root.noteLevelAttack : root.noteLevelRelease;
        const level = Math.max(root.noteMinLevelDb, trackedLevel + (peak - trackedLevel) * rate);
        const unit = v => Math.max(0, Math.min(1, v));
        const loudness = unit((peak - level - headroomDb) / root.noteLoudnessRangeDb + 1);
        const sorted = levels.slice().sort((a, b) => a - b);
        const floor = Math.min(sorted[Math.round(root.noteFloorQuantile * (sorted.length - 1))], peak - root.noteMinSpanDb);
        const heights = levels.map(db => loudness * Math.pow(unit((db - floor) / (peak - floor)), root.noteShapeExponent));
        return {
            heights: heights,
            level: level
        };
    }

    function easeHeights(previous, next) {
        if (previous.length !== next.length)
            return next;
        return next.map((h, i) => previous[i] + (h - previous[i]) * (h > previous[i] ? root.noteRise : root.noteFall));
    }

    Loader {
        id: visualizerLoader
        anchors.fill: parent
        sourceComponent: {
            switch (root.mode) {
            case "chroma":
            case "piano":
                return noteWaveComponent;
            case "synth":
                return synthComponent;
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

            property real start: 0
            property real end: width
            property real delta: 0
            property real maxDelta: Math.max(0, titleText.implicitWidth - (end - start))
            property bool needsScroll: titleText.implicitWidth > (end - start) && root.title.length > 0
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
        id: noteWaveComponent
        WaveCanvas {
            id: noteWave
            anchors.fill: parent
            color: root.visualizerColor
            mirrored: root.mirrored
            shape: root.mode === "chroma" ? "bells" : "spline"

            property real level: root.noteMinLevelDb
            readonly property var levels: root.mode === "chroma" ? root.chromaValues : root.noteValues

            onLevelsChanged: {
                const frame = root.noteHeights(noteWave.levels, noteWave.level);
                noteWave.level = frame.level;
                noteWave.heights = root.easeHeights(noteWave.heights, frame.heights);
            }
        }
    }

    Component {
        id: synthComponent
        Canvas {
            id: synth
            anchors.fill: parent

            readonly property int foldedNotes: 24
            property real level: root.noteMinLevelDb
            property var amplitudes: new Array(foldedNotes).fill(0)
            property real drawnPeak: 0
            property var shown: []
            property var held: []
            property real startTime: Date.now()
            property var points: []

            function voices(heights, held) {
                const peaks = [];
                for (let i = 0; i < heights.length; i++) {
                    const h = heights[i];
                    if (h > 0 && h >= (heights[i - 1] || 0) && h >= (heights[i + 1] || 0))
                        peaks.push(i);
                }
                peaks.sort((a, b) => heights[b] - heights[a]);

                const picked = peaks.filter(i => held.includes(i)).slice(0, root.synthVoices);
                for (const i of peaks) {
                    if (picked.includes(i))
                        continue;
                    if (picked.length < root.synthVoices) {
                        picked.push(i);
                        continue;
                    }
                    const weakest = picked.reduce((w, j) => heights[j] < heights[w] ? j : w);
                    if (heights[i] > heights[weakest] * (1 + root.synthVoiceHold))
                        picked[picked.indexOf(weakest)] = i;
                }
                return picked;
            }

            function refresh() {
                if (root.noteValues.length < 2) {
                    synth.points = [];
                    return;
                }

                const frame = root.noteHeights(root.noteValues, synth.level, root.synthHeadroomDb);
                synth.level = frame.level;
                const heights = root.easeHeights(synth.shown, frame.heights);
                synth.shown = heights;
                synth.held = synth.voices(heights, synth.held);

                const targets = new Array(synth.foldedNotes).fill(0);
                for (const i of synth.held) {
                    const k = i % synth.foldedNotes;
                    targets[k] = Math.max(targets[k], Math.pow(heights[i], root.synthVoiceCurve));
                }

                const amps = synth.amplitudes.map((a, k) => a + (targets[k] - a) * (targets[k] > a ? root.synthAttack : root.synthRelease));
                synth.amplitudes = amps;

                const active = [];
                let loudest = 0;
                for (let k = 0; k < synth.foldedNotes; k++) {
                    loudest = Math.max(loudest, amps[k]);
                    if (amps[k] > 0.001)
                        active.push({
                            amp: amps[k],
                            cycles: root.synthBaseCycles * Math.pow(2, k / 12)
                        });
                }

                const shift = root.synthScrollSpeed * (Date.now() - synth.startTime) / 1000;
                const raw = [];
                let peak = 0;
                for (let x = 0; x <= width; x++) {
                    const u = x / width - shift;
                    let y = 0;
                    for (const v of active)
                        y += v.amp * Math.sin(2 * Math.PI * v.cycles * u);
                    raw.push(y);
                    peak = Math.max(peak, Math.abs(y));
                }

                const tracked = synth.drawnPeak + (peak - synth.drawnPeak) * (peak > synth.drawnPeak ? root.synthPeakAttack : root.synthPeakRelease);
                synth.drawnPeak = tracked;
                const gain = peak > 0.001 ? Math.min(loudest / tracked, 1 / peak) : 0;
                synth.points = raw.map(y => y * gain);
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                if (synth.points.length < 2)
                    return;

                const baseY = height / 2;
                const amplitude = baseY - 2;
                ctx.beginPath();
                ctx.moveTo(0, baseY);
                synth.points.forEach((y, x) => ctx.lineTo(x, baseY - amplitude * y));

                ctx.lineWidth = root.synthLineWidth;
                ctx.strokeStyle = root.visualizerColor;
                ctx.lineCap = 'round';
                ctx.lineJoin = 'round';
                ctx.stroke();

                ctx.lineTo(width, baseY);
                ctx.closePath();
                ctx.globalAlpha = root.synthFillOpacity;
                ctx.fillStyle = root.visualizerColor;
                ctx.fill();
                ctx.globalAlpha = 1;
            }

            onPointsChanged: requestPaint()

            Connections {
                target: root
                function onNoteValuesChanged() {
                    synth.refresh();
                }
            }
        }
    }

    Component {
        id: waveComponent
        WaveCanvas {
            id: wave
            anchors.fill: parent
            color: root.visualizerColor
            mirrored: root.mirrored

            property real level: root.waveMinLevel

            function refresh() {
                const frame = root.waveHeights(root.cavaValues, wave.level);
                wave.level = frame.level;
                wave.heights = frame.heights;
            }

            Component.onCompleted: refresh()

            Connections {
                target: root
                function onCavaValuesChanged() {
                    wave.refresh();
                }
            }
        }
    }

    Component {
        id: barsComponent
        Item {
            id: bars
            anchors.fill: parent

            readonly property int count: root.cavaValues.length
            readonly property real slotWidth: count > 0 ? Math.max(1, Math.min(root.barWidth, (width - (count - 1) * root.barSpacing) / count)) : root.barWidth

            Row {
                id: topRow
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: root.mirrored ? parent.verticalCenter : parent.bottom
                spacing: root.barSpacing

                Repeater {
                    model: root.cavaValues.length // a count, so delegates persist across frames
                    delegate: Rectangle {
                        required property int index
                        width: bars.slotWidth
                        height: Math.min(root.mirrored ? bars.height / 2 : bars.height, Math.max(2, (root.cavaValues[index] || 0) * root.sensitivity))
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
                    model: root.cavaValues.length
                    delegate: Rectangle {
                        required property int index
                        width: bars.slotWidth
                        height: Math.min(bars.height / 2, Math.max(2, (root.cavaValues[index] || 0) * root.sensitivity))
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
