import Quickshell
import Quickshell.Io

Process {
    id: processor
    command: ["sh", "../scripts/cava_startup.sh"]
    running: true
    property var lastValues: []
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

            const smoothed = processor.lastValues.length === 0 ? newValues : processor.lastValues.map((old, i) => 0.3 * old + 0.7 * (newValues[i] || 0));

            processor.lastValues = smoothed;
            processor.newData(smoothed);
        }
    }
}
