import Quickshell.Io
import qs.config

Process {
    id: root
    property string wallpaperPath: ""
    property string scriptLocation: FileConfig.scripts.generateClaudeWallpaper

    // Strip file:// prefix from script location for shell execution
    function getCleanPath(path) {
        return path.replace(/^file:\/\//, '');
    }

    command: [getCleanPath(scriptLocation), wallpaperPath]
    signal closed(var jsonColors)
    signal error(string message)
    signal finished(int exitCode)
    running: false

    stdout: SplitParser {
        onRead: data => {
            console.debug("Raw stdout data:", data);

            // Try to parse - only proceed if valid JSON
            try {
                const claudeResponse = JSON.parse(data);
                console.debug("Valid Claude JSON received:", data);

                // Extract the actual result from Claude's response structure
                if (claudeResponse.result) {
                    // Parse the nested JSON string in the result field
                    try {
                        // Strip markdown code fences if present (```json\n...\n```)
                        let resultText = claudeResponse.result.trim();

                        // Remove leading ```json or ``` and trailing ```
                        if (resultText.startsWith('```')) {
                            // Find the first newline after the opening fence
                            const firstNewline = resultText.indexOf('\n');
                            if (firstNewline !== -1) {
                                resultText = resultText.substring(firstNewline + 1);
                            }

                            // Remove trailing ```
                            if (resultText.endsWith('```')) {
                                resultText = resultText.substring(0, resultText.length - 3);
                            }

                            resultText = resultText.trim();
                        }

                        const jsonData = JSON.parse(resultText);
                        console.debug("Parsed color data:", jsonData);
                        root.closed(jsonData);
                    } catch (e) {
                        console.error("Failed to parse result field as JSON:", e);
                        console.error("Result content:", claudeResponse.result);
                        root.error("Invalid JSON in Claude result field");
                    }
                } else {
                    console.error("No 'result' field in Claude response");
                    root.error("Missing result field in Claude response");
                }
            } catch (e) {
                console.debug("Partial or invalid JSON, waiting for more data...");
            }
        }
        splitMarker: ""
    }

    stderr: SplitParser {
        onRead: data => {
            return console.error(`Failed to parse Claude with error: ${data.trim()}`);
        }
    }

    onFinished: {
        running = false;
    }
}
