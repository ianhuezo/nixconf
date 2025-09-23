import Quickshell.Io
import qs.config

Process {
    id: root
    property string wallpaperPath: ""
    property var geminiAPIKey: ""
    property string scriptLocation: FileConfig.scripts.generateWallpaper
    property string promptPath: FileConfig.scripts.generateAIColorPrompt
    //this is not in regular thunar, it's from the custom nix code patch
    command: [scriptLocation, wallpaperPath, promptPath, geminiAPIKey]
    signal closed(var jsonColors)
    signal error(string message)
    signal finished(int exitCode)
    running: false
    stdout: SplitParser {
        onRead: data => {
            console.debug("Raw stdout data:", data);

            // Try to parse - only proceed if valid JSON
            try {
                const jsonData = JSON.parse(data);
                console.debug("Valid JSON received:", data);
                root.closed(jsonData);
            } catch (e) {
                console.debug("Partial or invalid JSON, waiting for more data...");
            }
        }
        splitMarker: ""
    }
    stderr: SplitParser {
        onRead: data => {
            return console.error(`Failed to parse Gemini with error: ${data.trim()}`);
        }
    }
    onFinished: {
        running = false;
    }
}
