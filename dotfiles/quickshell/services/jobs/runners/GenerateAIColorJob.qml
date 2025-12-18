import QtQuick
import Quickshell.Io
import qs.config
import ".." as Jobs

Jobs.BaseJob {
    id: job

    // Expected args: [wallpaperPath, useClaude]
    property string wallpaperPath: args.length > 0 ? args[0] : ""
    property bool useClaude: args.length > 1 ? args[1] : true

    // Job metadata
    jobName: "Generate AI Colors"
    notificationIcon: "preferences-desktop-theme"
    enableProgressNotifications: true

    // Internal process holder
    property var generatorProcess: null

    function execute() {
        if (!wallpaperPath || wallpaperPath.length === 0) {
            _setFailed("No wallpaper path provided");
            return;
        }

        _updateProgress(10, "Preparing to generate colors...");

        const scriptPath = useClaude
            ? FileConfig.scripts.generateClaudeWallpaper
            : FileConfig.scripts.generateGeminiWallpaper;

        if (!scriptPath) {
            _setFailed("Script path not configured");
            return;
        }

        _updateProgress(20, "Starting AI color generation...");

        // Strip file:// prefix from script location for shell execution
        function getCleanPath(path) {
            return path.replace(/^file:\/\//, '');
        }

        const cleanScriptPath = getCleanPath(scriptPath);

        // Helper to process AI response through parsing stages
        function processAIResponse(data) {
            // Stage 1: Parse outer JSON
            let claudeResponse;
            try {
                claudeResponse = JSON.parse(data);
            } catch (e) {
                return { stage: "receiving", progress: 50, message: "Receiving AI response..." };
            }

            // Stage 2: Validate result field exists
            if (!claudeResponse.result) {
                return { stage: "error", message: "No result field in AI response" };
            }

            // Stage 3: Extract JSON from markdown if needed
            let resultText = claudeResponse.result.trim();
            const jsonBlockMatch = resultText.match(/```json\s*\n([\s\S]*?)\n```/);
            if (jsonBlockMatch) {
                resultText = jsonBlockMatch[1].trim();
            } else {
                const codeBlockMatch = resultText.match(/```\s*\n([\s\S]*?)\n```/);
                if (codeBlockMatch) {
                    resultText = codeBlockMatch[1].trim();
                }
            }

            // Stage 4: Parse color data JSON
            let jsonData;
            try {
                jsonData = JSON.parse(resultText);
            } catch (e) {
                return { stage: "error", message: "Failed to parse AI response: " + e.toString() };
            }

            // Stage 5: Success
            return {
                stage: "success",
                progress: 90,
                message: "Colors generated successfully",
                data: jsonData
            };
        }

        // Create the process
        generatorProcess = _createProcess(
            [cleanScriptPath, wallpaperPath],
            (data) => {
                // stdout handler
                _updateProgress(60, "Processing AI response...");

                const outcome = processAIResponse(data);

                switch (outcome.stage) {
                    case "receiving":
                        _updateProgress(outcome.progress, outcome.message);
                        break;
                    case "error":
                        _setFailed(outcome.message);
                        break;
                    case "success":
                        _updateProgress(outcome.progress, outcome.message);
                        _setCompleted({
                            success: true,
                            colorData: outcome.data,
                            wallpaperPath: wallpaperPath
                        });
                        break;
                }
            },
            (data) => {
                // stderr handler
                console.error("AI generation error:", data);
            },
            (exitCode, exitStatus) => {
                // exited handler
                if (exitCode !== 0 && status === "running") {
                    _setFailed("AI generation failed with exit code: " + exitCode);
                }

                if (generatorProcess) {
                    generatorProcess.destroy();
                    generatorProcess = null;
                }
            }
        );

        if (!generatorProcess) {
            _setFailed("Failed to create AI generation process");
            return;
        }

        generatorProcess.running = true;
    }

    // Cleanup on destroy
    Component.onDestruction: {
        if (generatorProcess) {
            generatorProcess.destroy();
        }
    }
}
