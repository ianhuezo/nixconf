pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool updatingWallpaper: false
    property string currentWallpaperPath: ""

    // Update wallpaper using swww
    function updateWallpaper(wallpaperPath) {
        if (!wallpaperPath || wallpaperPath.length === 0) {
            console.warn("No wallpaper path provided");
            return;
        }

        if (updatingWallpaper) {
            return;
        }

        updatingWallpaper = true;
        currentWallpaperPath = wallpaperPath;

        // Use swww img to set wallpaper
        swwwUpdater.command = ["swww", "img", wallpaperPath];
        swwwUpdater.running = true;
    }

    Process {
        id: swwwUpdater
        running: false

        onExited: (code, status) => {
            if (code !== 0) {
                console.error("Failed to update wallpaper. Exit code:", code);
            }
            root.updatingWallpaper = false;
        }
    }
}
