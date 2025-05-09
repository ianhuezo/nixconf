if ! command -v ags &>/dev/null; then
  echo "Error: ags is not installed"
  exit 1
fi

while inotifywait -r -e close_write --include '\.(ts|tsx|scss|js|jsx)$' .; do
  echo "killing current ags session"
  pkill gjs
  echo "Launching App..."
  ags run --gtk4 &
  disown
  echo "Attempted to load config"
done
