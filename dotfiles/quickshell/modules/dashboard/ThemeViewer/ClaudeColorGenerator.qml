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
                        // Extract JSON from markdown code fences if present
                        let resultText = claudeResponse.result.trim();

                        // Look for JSON code block anywhere in the text (```json\n...\n```)
                        const jsonBlockMatch = resultText.match(/```json\s*\n([\s\S]*?)\n```/);
                        if (jsonBlockMatch) {
                            resultText = jsonBlockMatch[1].trim();
                        } else {
                            // Fallback: try generic code fences (```\n...\n```)
                            const codeBlockMatch = resultText.match(/```\s*\n([\s\S]*?)\n```/);
                            if (codeBlockMatch) {
                                resultText = codeBlockMatch[1].trim();
                            }
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
