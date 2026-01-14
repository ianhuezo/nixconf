import QtQuick
import Quickshell.Io
import qs.services
import ".." as Jobs
import "root:/libs/nix/nix.js" as NixUtil
import "root:/config" as Config

Jobs.BaseJob {
    id: job

    // Expected args: [themePath, wallpaperPath]
    // If dependencyResult exists, use the saved theme path from it
    property string themePath: {
        if (dependencyResult && dependencyResult.filePath) {
            return dependencyResult.filePath;
        }
        return args.length > 0 ? args[0] : "";
    }
    property string wallpaperPath: args.length > 1 ? args[1] : ""
    property string resolvedWallpaperPath: ""

    // Job metadata
    jobName: "Apply AI Colors"
    notificationIcon: "preferences-desktop-theme"

    function execute() {
        if (!themePath || themePath.length === 0) {
            _setFailed("No theme path provided");
            return;
        }

        _updateProgress(10, "Loading theme...");

        try {
            // Apply the theme
            Color.loadTheme(themePath);
            _updateProgress(40, "Theme applied");

            // Determine which wallpaper to use
            resolvedWallpaperPath = resolveWallpaperPath();

            if (resolvedWallpaperPath && resolvedWallpaperPath.length > 0) {
                _updateProgress(70, "Applying wallpaper...");
                Swww.updateWallpaper(resolvedWallpaperPath);
                _updateProgress(90, "Wallpaper applied");
            } else {
                _updateProgress(90, "No wallpaper to apply");
            }

            _updateProgress(100, "Theme and wallpaper applied successfully");

            const result = {
                success: true,
                applied: true,
                themePath: themePath,
                wallpaperPath: resolvedWallpaperPath
            };

            _setCompleted(result);
        } catch (e) {
            _setFailed("Failed to apply theme: " + e.toString());
        }
    }

    // Resolve wallpaper with priority:
    // 1. User-provided wallpaperPath (from args)
    // 2. Wallpaper from theme Nix file (if exists and valid)
    // 3. Default wallpaper from hyprland nix config
    function resolveWallpaperPath() {
        // Priority 1: User explicitly provided wallpaper
        if (wallpaperPath && wallpaperPath.length > 0) {
            console.log("Using user-provided wallpaper:", wallpaperPath);
            return wallpaperPath;
        }

        // Priority 2: Try to read wallpaper from theme file
        const themeWallpaper = readWallpaperFromTheme(themePath);
        if (themeWallpaper && themeWallpaper.length > 0) {
            console.log("Using wallpaper from theme:", themeWallpaper);
            return themeWallpaper;
        }

        // Priority 3: Use default wallpaper from hyprland nix config
        const defaultWallpaper = readHyprlandWallpaper();
        console.log("Using default wallpaper from hyprland config:", defaultWallpaper);
        return defaultWallpaper;
    }

    // Read current wallpaper from hyprland nix file
    function readHyprlandWallpaper() {
        try {
            const hyprlandNixPath = "/etc/nixos/nix/home-manager/modules/window-managers/hyprland/default.nix";

            const fileView = Qt.createQmlObject(
                'import Quickshell.Io; FileView { blockAllReads: true }',
                job,
                "hyprlandFileView"
            );

            fileView.path = Qt.resolvedUrl(hyprlandNixPath);
            fileView.reload();
            const fileContent = fileView.text();

            if (!fileContent || fileContent.length === 0) {
                console.warn("Could not read hyprland nix file");
                return "";
            }

            // Parse the swww img line
            // Pattern: swww img ${config.home.homeDirectory}/Pictures/frieren.png
            const swwwMatch = fileContent.match(/swww\s+img\s+([^\s]+)/);
            if (swwwMatch && swwwMatch[1]) {
                let wallpaperPath = swwwMatch[1];

                // Resolve ${config.home.homeDirectory} to actual home directory
                const homeDir = Quickshell.env("HOME");
                wallpaperPath = wallpaperPath.replace(/\$\{config\.home\.homeDirectory\}/, homeDir);

                console.log("Extracted hyprland wallpaper:", wallpaperPath);
                return wallpaperPath;
            }

            console.warn("Could not find swww img line in hyprland config");
            return "";

        } catch (error) {
            console.error("Error reading hyprland wallpaper:", error);
            return "";
        }
    }

    // Read wallpaper field from theme Nix file
    function readWallpaperFromTheme(nixFilePath) {
        try {
            // Use FileView to read theme file (similar to Color.qml)
            const fileView = Qt.createQmlObject(
                'import Quickshell.Io; FileView { blockAllReads: true }',
                job,
                "themeFileView"
            );

            fileView.path = Qt.resolvedUrl(nixFilePath);
            fileView.reload();
            const fileContent = fileView.text();

            if (!fileContent || fileContent.length === 0) {
                console.warn("Could not read theme file:", nixFilePath);
                return "";
            }

            // Parse Nix to JSON
            const themeData = NixUtil.nixToJson(fileContent);

            // Check if wallpaper field exists
            if (themeData.wallpaper && themeData.wallpaper.length > 0) {
                return themeData.wallpaper;
            }

            return "";

        } catch (error) {
            console.error("Error reading wallpaper from theme:", error);
            return "";
        }
    }
}
