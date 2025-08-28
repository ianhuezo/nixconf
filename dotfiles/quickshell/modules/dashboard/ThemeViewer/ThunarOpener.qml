import Quickshell.Io

Process {
    id: root
    //this is not in regular thunar, it's from the custom nix code patch
    command: ["thunar", "--pipe-mode"]

    signal closed(string filePath)
    signal error(string message)
    signal finished(int exitCode)

    running: false
    stdout: SplitParser {
        onRead: data => {
            console.log("");
            root.closed(data);
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
