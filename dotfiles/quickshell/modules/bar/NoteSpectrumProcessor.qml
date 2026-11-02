import Quickshell.Io
import QtQuick

Process {
    id: processor
    command: ["note-spectrum"]
    property var lastChroma: []
    property var lastNotes: []
    property real attack: 0.7
    property real release: 0.3
    property real perceptualWeighting: 0.5
    property real octaveBalance: 0.5
    property real octaveBalanceSeconds: 4
    property var octaveLevels: []
    readonly property int framesPerSecond: 30
    readonly property int lowestNote: 36 // C2, so note index % 12 is the pitch class
    readonly property var noteWeights: {
        const out = [];
        for (let i = 0; i < 60; i++) {
            const f2 = Math.pow(440 * Math.pow(2, (processor.lowestNote + i - 69) / 12), 2);
            const ra = Math.pow(12194, 2) * f2 * f2 / ((f2 + Math.pow(20.6, 2)) * Math.sqrt((f2 + Math.pow(107.7, 2)) * (f2 + Math.pow(737.9, 2))) * (f2 + Math.pow(12194, 2)));
            out.push(processor.perceptualWeighting * (20 * Math.log10(ra) + 2.0));
        }
        return out;
    }
    signal newData(var chroma, var notes)

    function smooth(previous, next) {
        if (previous.length !== next.length)
            return next;
        return next.map((v, i) => previous[i] + (v - previous[i]) * (v > previous[i] ? attack : release));
    }

    function powerDb(levels) {
        return 10 * Math.log10(levels.reduce((sum, db) => sum + Math.pow(10, db / 10), 0) + 1e-12);
    }

    function reweigh(notes) {
        const weighted = notes.map((db, i) => db + (processor.noteWeights[i] || 0));
        const octaves = Math.floor(weighted.length / 12);
        const current = [];
        for (let o = 0; o < octaves; o++)
            current.push(powerDb(weighted.slice(o * 12, o * 12 + 12)));

        const previous = processor.octaveLevels;
        const rate = 1 / (processor.octaveBalanceSeconds * processor.framesPerSecond);
        const tracked = previous.length !== octaves ? current : previous.map((t, o) => t + (current[o] - t) * rate);
        processor.octaveLevels = tracked;
        const mean = tracked.reduce((a, b) => a + b, 0) / octaves;
        return weighted.map((db, i) => db - processor.octaveBalance * (tracked[Math.floor(i / 12)] - mean));
    }

    function foldChroma(notes) {
        const chroma = [];
        for (let c = 0; c < 12; c++)
            chroma.push(powerDb(notes.filter((_, i) => i % 12 === c)));
        return chroma;
    }

    stdout: SplitParser {
        onRead: data => {
            const parts = data.trim().split('|');
            if (parts.length !== 2)
                return;
            const notes = processor.reweigh(parts[1].split(';').map(Number));
            processor.lastChroma = processor.smooth(processor.lastChroma, processor.foldChroma(notes));
            processor.lastNotes = processor.smooth(processor.lastNotes, notes);
            processor.newData(processor.lastChroma, processor.lastNotes);
        }
    }
}
