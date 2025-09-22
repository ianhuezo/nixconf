import Quickshell.Io
import qs.config

Process {
    id: root

    required property string wallpaperPath

    readonly property var scriptLocation: FileConfig.scripts.generateAIColor
    readonly property string promptPath: FileConfig.scripts.generateAIColorPrompt
    readonly property var geminiAPIKey: JSON.parse(jsonFile.text())['apiKey'] ?? ""
    //this is not in regular thunar, it's from the custom nix code patch
    command: [scriptLocation, wallpaperPath, promptPath, geminiAPIKey]

    signal closed(var jsonColors)
    signal error(string message)
    signal finished(int exitCode)

    FileView {
        id: jsonFile
        path: FileConfig.environment.geminiAPIKeyPath
        blockLoading: true
    }

    running: false
    stdout: SplitParser {
        onRead: data => {
            console.log(data);
            root.closed(JSON.parse(data));
        }
    }

    stderr: SplitParser {
        onRead: data => {
            return `Failed to parse thunar selected path with error: ${data.trim()}`;
        }
    }

    onFinished: {
        running = false;
    }
}
