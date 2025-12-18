import QtQuick
import Quickshell.Io
import qs.services
import ".." as Jobs

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
            _updateProgress(50, "Theme applied");

            // Apply wallpaper if provided
            if (wallpaperPath && wallpaperPath.length > 0) {
                _updateProgress(70, "Applying wallpaper...");
                Swww.updateWallpaper(wallpaperPath);
                _updateProgress(90, "Wallpaper applied");
            }

            _updateProgress(100, "Theme and wallpaper applied successfully");

            const result = {
                success: true,
                applied: true,
                themePath: themePath,
                wallpaperPath: wallpaperPath
            };

            _setCompleted(result);
        } catch (e) {
            _setFailed("Failed to apply theme: " + e.toString());
        }
    }
}
