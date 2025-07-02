#!/bin/sh
show_user_apps_by_usage() {
    declare -A app_times
    
    # Use find to get all .desktop files
    while IFS= read -r -d '' desktop; do
        # Skip system/background applications
        if grep -q "^NoDisplay=true" "$desktop" 2>/dev/null; then
            continue
        fi
        
        # Skip terminal applications
        if grep -q "^Terminal=true" "$desktop" 2>/dev/null; then
            continue
        fi
        
        # Only include actual applications
        if ! grep -q "^Type=Application" "$desktop" 2>/dev/null; then
            continue
        fi
        
        # Get app info
        name=$(grep "^Name=" "$desktop" 2>/dev/null | head -1 | cut -d'=' -f2-)
        icon=$(grep "^Icon=" "$desktop" 2>/dev/null | head -1 | cut -d'=' -f2-)
        exec_line=$(grep "^Exec=" "$desktop" 2>/dev/null | head -1 | cut -d'=' -f2-)
        app_name=$(echo "$exec_line" | awk '{print $1}' | xargs basename 2>/dev/null)
        
        # Skip if we couldn't get basic info
        [[ -z "$name" || -z "$app_name" ]] && continue
        
        # Skip common system/auto-launched apps
        case "$app_name" in
            *daemon*|*service*|*helper*|*agent*|*notify*|*update*|*sync*|polkit*|gvfs*|dbus*|systemd*)
                continue
                ;;
        esac
        
        # Get usage time
        latest_time=0
        for dir in ~/.config ~/.cache ~/.local/share; do
            if [[ -d "$dir" ]]; then
                app_dir=$(find "$dir" -maxdepth 2 -iname "*$app_name*" -type d 2>/dev/null | head -1)
                if [[ -n "$app_dir" ]]; then
                    dir_time=$(stat -c %Y "$app_dir" 2>/dev/null || echo 0)
                    [[ $dir_time -gt $latest_time ]] && latest_time=$dir_time
                fi
            fi
        done
        
        # Only include apps that have been used
        if [[ $latest_time -gt 0 ]]; then
            app_times["$latest_time|$name|$icon|$desktop"]="$latest_time"
        fi
        
    done < <(find /run/current-system/sw/share/applications ~/.nix-profile/share/applications ~/.local/share/applications -name "*.desktop" -print0 2>/dev/null)
    
    # Sort and display
    for entry in "${!app_times[@]}"; do
        echo "$entry"
    done | sort -t'|' -k1,1nr | while IFS='|' read timestamp name icon desktop; do
        date=$(date -d "@$timestamp" "+%Y-%m-%d %H:%M:%S")
        echo "[$date] $name"
        
        # Find and display icon
        icon_file=""
        for dir in /run/current-system/sw/share/icons/hicolor/*/apps \
                   ~/.nix-profile/share/icons/hicolor/*/apps \
                   /run/current-system/sw/share/pixmaps \
                   ~/.nix-profile/share/pixmaps; do
            for ext in png svg xpm; do
                if [[ -f "$dir/$icon.$ext" ]]; then
                    icon_file="$dir/$icon.$ext"
                    break 2
                fi
            done
        done
        
        [[ -n "$icon_file" ]] && kitten icat "$icon_file"
        echo "---"
    done
}

show_user_apps_by_usage
