while inotifywait -r -e close_write --include '\.js$' .; do
    echo "killing current ags session"
    pkill ags
    echo "Using Calendar App..."
    ags --config "$(pwd)/config.js" & disown
    echo "Attempted to load config"
done
