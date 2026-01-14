import Quickshell.Io
import qs.config

Process {
    id: root
    property string imagePath: ""
    property int k: 10

    // Strip file:// prefix for shell execution
    function getCleanPath(path) {
        return path.replace(/^file:\/\//, '');
    }

    command: [getCleanPath(FileConfig.scripts.hybridColors), imagePath, k.toString()]
    signal closed(var colors)
    signal error(string message)
    running: false

    stdout: SplitParser {
        onRead: data => {
            console.debug("Raw quantette color output:", data);

            try {
                const colors = parseKmeansOutput(data.trim());
                if (colors && colors.length > 0) {
                    console.debug("Extracted", colors.length, "colors using quantette");
                    root.closed(colors);
                } else {
                    root.error("No colors extracted");
                }
            } catch (e) {
                console.error("Failed to parse color output:", e);
                root.error("Parse error: " + e.toString());
            }
        }
    }

    stderr: SplitParser {
        onRead: data => {
            console.error("Quantette color extraction error:", data.trim());
            root.error(data.trim());
        }
    }

    onExited: (exitCode, exitStatus) => {
        running = false;
        if (exitCode !== 0) {
            console.error("Quantette color extraction failed with exit code:", exitCode);
        }
    }

    function parseKmeansOutput(output) {
        // Parse: (#hex,pct),(#hex,pct),...
        const tuples = output.match(/\(#[0-9a-fA-F]+,[0-9.]+\)/g);
        if (!tuples) return [];

        return tuples.map(tuple => {
            const match = tuple.match(/\(#([0-9a-fA-F]+),([0-9.]+)\)/);
            if (match) {
                return {
                    hex: "#" + match[1],
                    percentage: parseFloat(match[2])
                };
            }
            return null;
        }).filter(c => c !== null);
    }
}
