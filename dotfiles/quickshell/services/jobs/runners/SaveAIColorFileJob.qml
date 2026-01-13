import QtQuick
import Quickshell.Io
import ".." as Jobs
import "../../../libs/nix/nix.js" as Nix

Jobs.BaseJob {
    id: job

    // Expected args: [colorData, filePath]
    // If dependencyResult exists, use it instead of args[0]
    property var colorData: {
        if (dependencyResult && dependencyResult.colorData) {
            return dependencyResult.colorData;
        }
        return args.length > 0 ? args[0] : null;
    }
    property string filePath: args.length > 1 ? args[1] : "/etc/nixos/nix/themes"
    property string wallpaperPath: {
        // Get from dependency result (from GenerateAIColorJob)
        if (dependencyResult && dependencyResult.wallpaperPath) {
            return dependencyResult.wallpaperPath;
        }
        // Or from args[2] if provided directly
        return args.length > 2 ? args[2] : "";
    }

    // Job metadata
    jobName: "Save AI Colors"
    notificationIcon: "document-save"

    function execute() {
        if (!colorData) {
            _setFailed("No color data provided");
            return;
        }

        if (!filePath || filePath.length === 0) {
            _setFailed("No file path provided");
            return;
        }

        _updateProgress(10, "Preparing to save colors...");

        // Get the folder name from slug
        const folderName = colorData["slug"];
        if (!folderName) {
            _setFailed("The slug was not found, so file name was not created");
            return;
        }

        // Add wallpaper path to colorData if provided
        let finalColorData = colorData;
        if (wallpaperPath && wallpaperPath.length > 0) {
            finalColorData = Object.assign({}, colorData);
            finalColorData.wallpaper = wallpaperPath;
        }

        // Convert JSON to Nix format
        const nixString = Nix.jsonToNix(finalColorData, 2);
        const targetPath = `${filePath}/${folderName}/default.nix`;

        _updateProgress(30, "Writing to file...");

        const builtCommand = `mkdir -p ${filePath}/${folderName} && echo '${nixString}' > ${targetPath}`;
        const writeProcess = _createProcess(
            ["sh", "-c", builtCommand],
            null, // no stdout handler
            (data) => {
                if (data && data.length > 0) {
                    console.error("Write error:", data);
                }
            },
            (exitCode, exitStatus) => {
                if (exitCode === 0) {
                    _updateProgress(100, "Colors saved successfully");

                    const result = {
                        success: true,
                        filePath: targetPath,
                        folderName: folderName,
                        colorData: colorData,
                        wallpaperPath: wallpaperPath
                    };

                    _setCompleted(result);
                } else {
                    _setFailed("Failed to write file (exit code: " + exitCode + ")");
                }
            }
        );

        if (!writeProcess) {
            _setFailed("Failed to create write process");
            return;
        }

        writeProcess.running = true;
    }
}
