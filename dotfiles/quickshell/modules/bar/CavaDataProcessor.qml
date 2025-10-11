import Quickshell.Io
import QtQuick
import qs.config

Process {
    id: processor
    property string scriptLocation: FileConfig.scripts.cava
    command: [scriptLocation]
    running: true
    property var lastValues: []
    property string smoothingMode: "normal" // "adaptive", "responsive", "fluid", "normal"
    signal newData(var processedValues)

    stdout: SplitParser {
        onRead: data => {
            const rawValues = data.trim().split(';').filter(v => v !== '');
            const newValues = rawValues.map(v => {
                const num = parseInt(v, 10);
                return Math.min(40, Math.max(0, isNaN(num) ? 0 : num));
            });

            const targetLength = processor.lastValues.length || newValues.length;
            while (newValues.length < targetLength)
                newValues.push(0);
            if (newValues.length > targetLength)
                newValues.length = targetLength;

            // Adaptive smoothing based on mode
            const smoothed = processor.lastValues.length === 0 ? newValues : processor.lastValues.map((old, i) => {
                const newVal = newValues[i] || 0;

                switch (processor.smoothingMode) {
                case "adaptive":
                    // Quick rise, gradual fall
                    if (newVal > old) {
                        return 0.2 * old + 0.8 * newVal;
                    } else {
                        return 0.6 * old + 0.4 * newVal;
                    }
                case "responsive":
                    // More responsive, less smoothing (80% new)
                    return 0.2 * old + 0.8 * newVal;
                case "fluid":
                    // More smoothing, slower response (50% new)
                    return 0.5 * old + 0.5 * newVal;
                case "normal":
                default:
                    // Original smoothing (70% new)
                    return 0.3 * old + 0.7 * newVal;
                }
            });

            processor.lastValues = smoothed;
            processor.newData(smoothed);
        }
    }
}
