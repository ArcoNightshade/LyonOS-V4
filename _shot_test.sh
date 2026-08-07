dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/Screenshot from $(date '+%Y-%m-%d %H-%M-%S').png"
mode="${1:-area}"

if [ "$mode" = "screen" ]; then
  grim - | tee "$file" | wl-copy -t image/png
else
  # Freeze the display so the selection happens over a static image.
  wayfreeze --hide-cursor &
  freeze_pid=$!
  # Give the freeze layer a moment to map before selecting.
  sleep 0.2
  if geom=$(slurp); then
    grim -g "$geom" - | tee "$file" | wl-copy -t image/png
    kill "$freeze_pid" 2>/dev/null || true
  else
    # User pressed Esc / made no selection: unfreeze and bail quietly.
    kill "$freeze_pid" 2>/dev/null || true
    exit 0
  fi
fi

notify-send "Screenshot" "Saved to $file and copied to clipboard" 2>/dev/null || true
