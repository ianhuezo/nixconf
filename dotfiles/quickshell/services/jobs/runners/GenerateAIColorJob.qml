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

        // Create the process
        generatorProcess = _createProcess(
            [cleanScriptPath, wallpaperPath],
            (data) => {
                // stdout handler
                _updateProgress(60, "Processing AI response...");

                try {
                    const claudeResponse = JSON.parse(data);

                    if (claudeResponse.result) {
                        // Parse the nested JSON string in the result field
                        try {
                            // Extract JSON from markdown code fences if present
                            let resultText = claudeResponse.result.trim();

                            // Look for JSON code block
                            const jsonBlockMatch = resultText.match(/```json\s*\n([\s\S]*?)\n```/);
                            if (jsonBlockMatch) {
                                resultText = jsonBlockMatch[1].trim();
                            } else {
                                const codeBlockMatch = resultText.match(/```\s*\n([\s\S]*?)\n```/);
                                if (codeBlockMatch) {
                                    resultText = codeBlockMatch[1].trim();
                                }
                            }

                            const jsonData = JSON.parse(resultText);
                            _updateProgress(90, "Colors generated successfully");

                            const result = {
                                success: true,
                                colorData: jsonData,
                                wallpaperPath: wallpaperPath
                            };

                            _setCompleted(result);
                        } catch (e) {
                            _setFailed("Failed to parse AI response: " + e.toString());
                        }
                    } else {
                        _setFailed("No result field in AI response");
                    }
                } catch (e) {
                    // Partial JSON, wait for more data
                    _updateProgress(50, "Receiving AI response...");
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
