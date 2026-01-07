pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Configuration file path
    readonly property string configPath: "/etc/nixos/dotfiles/quickshell/config.yaml"

    // Signals emitted when config changes
    signal configUpdated()
    signal appearanceUpdated()
    signal assetsUpdated()

    // Flag to track if config is loaded
    property bool isLoaded: false

    // Configuration data structure
    property var config: ({})

    // Appearance overrides (extends AppearanceConfig)
    property QtObject appearance: QtObject {
        // Radius overrides
        property QtObject radius: QtObject {
            property real sm: 4
            property real md: 12
            property real lg: 20
        }

        // Font overrides
        property QtObject font: QtObject {
            property string mono: "JetBrains Mono Nerd Font"
            property string ui: "Inter"
            property string display: "Inter"

            property QtObject size: QtObject {
                property real xs: 11
                property real sm: 14
                property real md: 16
                property real lg: 20
                property real xl: 24
                property real xxl: 32
            }

            property QtObject weight: QtObject {
                property int light: 300
                property int regular: 400
                property int medium: 500
                property int semibold: 600
                property int bold: 700
            }
        }
    }

    // Update appearance properties when config loads
    function updateAppearanceProperties() {
        appearance.radius.sm = root.getValue("appearance.radius.sm", 4);
        appearance.radius.md = root.getValue("appearance.radius.md", 12);
        appearance.radius.lg = root.getValue("appearance.radius.lg", 20);

        appearance.font.mono = root.getValue("appearance.font.mono", "JetBrains Mono Nerd Font");
        appearance.font.ui = root.getValue("appearance.font.ui", "Inter");
        appearance.font.display = root.getValue("appearance.font.display", "Inter");

        appearance.font.size.xs = root.getValue("appearance.font.size.xs", 11);
        appearance.font.size.sm = root.getValue("appearance.font.size.sm", 14);
        appearance.font.size.md = root.getValue("appearance.font.size.md", 16);
        appearance.font.size.lg = root.getValue("appearance.font.size.lg", 20);
        appearance.font.size.xl = root.getValue("appearance.font.size.xl", 24);
        appearance.font.size.xxl = root.getValue("appearance.font.size.xxl", 32);

        appearance.font.weight.light = root.getValue("appearance.font.weight.light", 300);
        appearance.font.weight.regular = root.getValue("appearance.font.weight.regular", 400);
        appearance.font.weight.medium = root.getValue("appearance.font.weight.medium", 500);
        appearance.font.weight.semibold = root.getValue("appearance.font.weight.semibold", 600);
        appearance.font.weight.bold = root.getValue("appearance.font.weight.bold", 700);
    }

    // Asset path overrides (extends FileConfig)
    property QtObject assets: QtObject {
        property string splashArt: "frieren/camp-crop.jpg"
        property string dashboardAppLauncher: "frieren/mimic.png"
        property string youtubeConverter: "global/youtube.png"
        property string downloadingVideoMP3: "frieren/fern-pout.gif"
        property string themeChooser: "frieren/lookup.png"
    }

    // Update asset properties when config loads
    function updateAssetProperties() {
        assets.splashArt = root.getValue("assets.splashArt", "frieren/camp-crop.jpg");
        assets.dashboardAppLauncher = root.getValue("assets.dashboardAppLauncher", "frieren/mimic.png");
        assets.youtubeConverter = root.getValue("assets.youtubeConverter", "global/youtube.png");
        assets.downloadingVideoMP3 = root.getValue("assets.downloadingVideoMP3", "frieren/fern-pout.gif");
        assets.themeChooser = root.getValue("assets.themeChooser", "frieren/lookup.png");
    }

    // Initialize on component creation
    Component.onCompleted: {
        loadConfig();
    }

    // Get nested configuration value with dot notation (e.g., "appearance.radius.sm")
    function getValue(path, defaultValue) {
        if (!isLoaded) {
            return defaultValue;
        }

        var keys = path.split('.');
        var current = config;

        for (var i = 0; i < keys.length; i++) {
            if (current === undefined || current === null || !current.hasOwnProperty(keys[i])) {
                return defaultValue;
            }
            current = current[keys[i]];
        }

        return current !== undefined && current !== null ? current : defaultValue;
    }

    // Set a nested configuration value and persist to file
    function setValue(path, value) {
        console.log("ConfigManager: Setting value:", path, "=", value);

        var keys = path.split('.');
        var current = config;

        // Navigate to the parent object
        for (var i = 0; i < keys.length - 1; i++) {
            if (!current.hasOwnProperty(keys[i]) || typeof current[keys[i]] !== 'object') {
                current[keys[i]] = {};
            }
            current = current[keys[i]];
        }

        // Set the value
        var lastKey = keys[keys.length - 1];
        current[lastKey] = value;

        // Trigger property updates by reassigning the config object
        var tempConfig = config;
        config = {};
        config = tempConfig;

        // Persist to file
        saveConfig();

        // Emit change signals
        emitChangeSignals(path);
    }

    // Emit appropriate change signals based on the path
    function emitChangeSignals(path) {
        root.configUpdated();

        if (path.startsWith("appearance.")) {
            root.appearanceUpdated();
        } else if (path.startsWith("assets.")) {
            root.assetsUpdated();
        }
    }

    // Load configuration from YAML file
    function loadConfig() {
        yamlParser.running = true;
    }

    // Save configuration to YAML file
    function saveConfig() {

        // Convert config object to JSON
        var jsonString = JSON.stringify(config, null, 2);

        // Use yq to convert JSON to YAML and write to file
        yamlWriter.command = [
            "sh", "-c",
            `echo '${jsonString}' | yq eval -P - > ${configPath}`
        ];
        yamlWriter.running = true;
    }

    // Reload configuration (can be called via IPC)
    function reload() {
        loadConfig();
    }

    // Reset to empty configuration
    function reset() {
        config = {};
        isLoaded = false;
        saveConfig();
        root.configUpdated();
    }

    // Accumulator for parser output
    property string parserOutput: ""

    // YAML parser process - converts YAML to JSON
    Process {
        id: yamlParser
        command: ["yq", "eval", "-o=json", configPath]
        running: false

        stdout: SplitParser {
            onRead: data => {
                // Accumulate output (SplitParser gives us line by line)
                root.parserOutput += data;
            }
        }

        stderr: SplitParser {
            onRead: data => {
                var message = data.trim();
                if (message.length > 0) {
                    // Check if file doesn't exist (common on first run)
                    if (message.includes("no such file") || message.includes("cannot open")) {
                        console.warn("ConfigManager: Config file not found, creating default...");
                        root.config = {};
                        root.isLoaded = true;
                        root.saveConfig();
                    } else {
                        console.error("ConfigManager: Error loading config:", message);
                    }
                }
            }
        }

        onExited: (code, status) => {
            if (code === 0) {
                // Parse the accumulated output
                try {
                    var fullOutput = root.parserOutput.trim();
                    if (fullOutput.length > 0) {
                        root.config = JSON.parse(fullOutput);
                        root.isLoaded = true;

                        // Update properties from new config
                        root.updateAppearanceProperties();
                        root.updateAssetProperties();

                        // Emit update signals
                        root.configUpdated();
                        root.appearanceUpdated();
                        root.assetsUpdated();
                    } else {
                        console.warn("ConfigManager: Empty config file, using defaults");
                        root.config = {};
                        root.isLoaded = true;
                    }
                } catch (error) {
                    console.error("ConfigManager: Failed to parse config:", error.message);
                    root.config = {};
                    root.isLoaded = false;
                }
            } else {
                console.error("ConfigManager: yq exited with code:", code);
                root.config = {};
                root.isLoaded = false;
            }

            // Clear the accumulator for next run
            root.parserOutput = "";
        }
    }

    // YAML writer process - saves JSON as YAML
    Process {
        id: yamlWriter
        running: false

        stderr: SplitParser {
            onRead: data => {
                var message = data.trim();
                if (message.length > 0) {
                    console.error("ConfigManager: Save error:", message);
                }
            }
        }

        onExited: (code, status) => {
            if (code !== 0) {
                console.error("ConfigManager: Failed to save config, exit code:", code);
            }
        }
    }

    // File watcher using FileView with watchChanges
    FileView {
        id: configFileWatcher
        path: Qt.resolvedUrl(configPath)
        watchChanges: true
        preload: false

        onFileChanged: {
            Qt.callLater(() => {
                root.loadConfig();
            });
        }
    }

    // IPC Handler for external control
    IpcHandler {
        target: "config"

        // Reload configuration from file
        // Usage: qs ipc call config reload
        function reload() {
            root.reload();
        }

        // Set a configuration value
        // Usage: qs ipc call config set "appearance.radius.sm" 8
        function set(path: string, value: string) {
            // Try to parse value as number if possible
            var parsedValue = value;
            if (!isNaN(value) && value !== "") {
                parsedValue = parseFloat(value);
            } else if (value === "true") {
                parsedValue = true;
            } else if (value === "false") {
                parsedValue = false;
            }

            root.setValue(path, parsedValue);
            return "Set " + path + " = " + parsedValue;
        }

        // Get a configuration value
        // Usage: qs ipc call config get "appearance.radius.sm"
        function get(path: string) {
            var value = root.getValue(path, null);
            if (value === null) {
                return "Key not found: " + path;
            }
            return path + " = " + JSON.stringify(value);
        }

        // Reset configuration to empty
        // Usage: qs ipc call config reset
        function reset() {
            root.reset();
            return "Configuration reset";
        }

        // Show current configuration
        // Usage: qs ipc call config show
        function show() {
            return JSON.stringify(root.config, null, 2);
        }
    }
}
