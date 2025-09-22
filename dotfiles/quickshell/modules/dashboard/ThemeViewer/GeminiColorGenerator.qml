import Quickshell.Io
import qs.config

Process {
    id: root
    property string wallpaperPath: ""
    property var geminiAPIKey: ""
    readonly property var scriptLocation: FileConfig.scripts.generateAIColor
    readonly property string promptPath: FileConfig.scripts.generateAIColorPrompt
    //this is not in regular thunar, it's from the custom nix code patch
    command: [scriptLocation, wallpaperPath, promptPath, geminiAPIKey]
    signal closed(var jsonColors)
    signal error(string message)
    signal finished(int exitCode)
    running: false
    stdout: SplitParser {
        onRead: data => {
        console.log("Raw stdout data:", data);
        
        // Try to parse - only proceed if valid JSON
        try {
            const jsonData = JSON.parse(data);
            console.log("Valid JSON received:", jsonData);
            root.closed(jsonData);
        } catch (e) {
            console.log("Partial or invalid JSON, waiting for more data...");
            // Don't call closed() yet
        }
        }
    }
    onRunningChanged: {
        console.log(`Running with variables:\n${scriptLocation}\n${geminiAPIKey}\n${promptPath}\n${wallpaperPath}\nAnd running ${running}`);
    }
    stderr: SplitParser {
        onRead: data => {
            return console.log(`Failed to parse Gemini with error: ${data.trim()}`);
        }
    }
    onFinished: {
        running = false;
    }
}
