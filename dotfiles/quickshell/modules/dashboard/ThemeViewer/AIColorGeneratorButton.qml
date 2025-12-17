import qs.components
import QtQuick
import qs.config
import qs.services
import qs.services.jobs as Jobs
import Quickshell.Io

IconButton {
    id: root
    iconText: "✨"

    tooltip: "Click: Generate Now" + "\n" + "Hold: Queue Generation"
    property string wallpaperPath: ""
    property bool useClaude: true
    property var apiKey: JSON.parse(jsonFile.text())['apiKey'] ?? ""
    loading: geminiGenerator.running || claudeGenerator.running || queuedJob !== null
    disabled: geminiGenerator.running || claudeGenerator.running
    signal colorsGenerated(var json)

    // Job queueing support
    pressHoldEnabled: true
    pressHoldDuration: 800
    property var queuedJob: null  // Store the queued job ID
    property string lastJobId: ""  // Last completed job ID for chaining

    // Use gradient loading effect with gold/orange colors
    loadingEffectType: "gradient"
    loadingPrimaryColor: Color.palette.base09
    loadingSecondaryColor: Qt.rgba(Color.palette.base09.r, Color.palette.base09.g, Color.palette.base09.b, 0.1)

    // Add active state glow when ready
    active: wallpaperPath.length > 0 && !geminiGenerator.running && !claudeGenerator.running
    stateEffectType: "glow"
    stateActiveColor: Color.palette.base09

    onClicked: {
        if (wallpaperPath.length == 0) {
            console.error("A path must be provided to generate a wallpaper color configuration");
            return;
        }

        // Immediate execution (old behavior)
        if (useClaude) {
            console.log("starting Claude color generation (immediate)");
            claudeGenerator.wallpaperPath = wallpaperPath;
            claudeGenerator.running = true;
        } else {
            if (apiKey.length == 0) {
                console.error("API Key could not be read");
                return;
            }
            console.log("starting Gemini color generation (immediate)");
            geminiGenerator.wallpaperPath = wallpaperPath;
            geminiGenerator.geminiAPIKey = apiKey;
            geminiGenerator.running = true;
        }
    }

    onPressHeld: {
        if (wallpaperPath.length == 0) {
            console.error("A path must be provided to generate a wallpaper color configuration");
            return;
        }

        // Queue the job
        console.log("Queueing AI color generation job");
        const jobId = Jobs.JobManager.enqueueJob(
            "GenerateAIColor",
            [wallpaperPath, useClaude],
            "ai-color-gen",
            (result) => {
                if (result && result.success) {
                    root.colorsGenerated(result.colorData);
                }
                root.queuedJob = null;
            }
        );

        if (jobId !== -1) {
            root.queuedJob = jobId;
            root.lastJobId = jobId;
            console.log("AI generation job queued:", jobId);
        }
    }

    onWallpaperPathChanged: data => {
        console.log(`Wallpaper path changed to ${wallpaperPath}`);
    }

    FileView {
        id: jsonFile
        path: FileConfig.environment.geminiAPIKeyPath
        blockLoading: true
    }

    GeminiColorGenerator {
        id: geminiGenerator
        onClosed: jsonColors => {
            root.colorsGenerated(jsonColors);
            geminiGenerator.running = false;
        }
        wallpaperPath: root.wallpaperPath
        onError: error => {
            console.debug(`${error}`);
            geminiGenerator.running = false;
        }
    }

    ClaudeColorGenerator {
        id: claudeGenerator
        onClosed: jsonColors => {
            root.colorsGenerated(jsonColors);
            claudeGenerator.running = false;
        }
        wallpaperPath: root.wallpaperPath
        onError: error => {
            console.debug(`${error}`);
            claudeGenerator.running = false;
        }
    }
}
