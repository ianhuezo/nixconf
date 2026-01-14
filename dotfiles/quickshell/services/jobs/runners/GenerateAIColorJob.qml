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
    property var kmeansColors: null

    // Function to extract colors using quantette (Wu's algorithm for optimal color quantization)
    function extractKmeansColors(imagePath, k, callback) {
        const colorProcess = _createProcess(
            [FileConfig.scripts.hybridColors, imagePath, k.toString()],
            (data) => {
                // Parse output: (#hex,pct),(#hex,pct),...
                const colors = parseKmeansOutput(data.trim());
                if (callback) callback(colors);
            },
            (data) => {
                if (data && !data.includes("Error:")) {
                    console.error("Quantette color extraction stderr:", data);
                }
            },
            (exitCode, exitStatus) => {
                if (exitCode !== 0) {
                    console.error("Quantette color extraction failed with exit code:", exitCode);
                    if (callback) callback(null);
                }
            }
        );

        if (colorProcess) {
            colorProcess.running = true;
        } else {
            console.error("Failed to create quantette color extraction process");
            if (callback) callback(null);
        }
    }

    function parseKmeansOutput(output) {
        // Parse: (#hex,pct),(#hex,pct),...
        const tuples = output.match(/\(#[0-9a-fA-F]+,[0-9.]+\)/g);
        if (!tuples) return [];

        return tuples.map(tuple => {
            const match = tuple.match(/\(#([0-9a-fA-F]+),([0-9.]+)\)/);
            if (match) {
                return {
                    hex: "#" + match[1],
                    percentage: parseFloat(match[2])
                };
            }
            return null;
        }).filter(c => c !== null);
    }

    function formatKmeansColors(colors) {
        // Format as: color1%pct1,color2%pct2,...
        return colors.map(c => `${c.hex}%${c.percentage.toFixed(2)}`).join(',');
    }

    function execute() {
        if (!wallpaperPath || wallpaperPath.length === 0) {
            _setFailed("No wallpaper path provided");
            return;
        }

        _updateProgress(10, "Extracting colors with quantette...");

        // First extract colors using quantette (Wu's algorithm), then generate AI colors
        // Extract 32 colors for optimal color diversity
        extractKmeansColors(wallpaperPath, 32, (colors) => {
            if (colors && colors.length > 0) {
                kmeansColors = colors;
                console.log("Extracted", colors.length, "colors using quantette");
                _updateProgress(20, "Starting AI color generation...");
                startAIGeneration();
            } else {
                console.warn("Failed to extract colors, proceeding without them");
                _updateProgress(20, "Starting AI color generation...");
                startAIGeneration();
            }
        });
    }

    function startAIGeneration() {
        const scriptPath = useClaude
            ? FileConfig.scripts.generateClaudeWallpaper
            : FileConfig.scripts.generateGeminiWallpaper;

        if (!scriptPath) {
            _setFailed("Script path not configured");
            return;
        }

        // Strip file:// prefix from script location for shell execution
        function getCleanPath(path) {
            return path.replace(/^file:\/\//, '');
        }

        const cleanScriptPath = getCleanPath(scriptPath);

        // Format kmeans colors for passing to script
        const kmeansColorString = kmeansColors ? formatKmeansColors(kmeansColors) : "";

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

        // Create the process (pass wallpaperPath and kmeans colors)
        generatorProcess = _createProcess(
            [cleanScriptPath, wallpaperPath, kmeansColorString],
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
