#!/bin/sh
# Screenshot for the island, on any compositor.
#   screenshot.sh region|output|window
# Hyprland with hyprshot installed: hyprshot does it.
# Anything else: grim + slurp, saved to ~/Pictures/Screenshots and copied.
mode=${1:-region}

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && command -v hyprshot >/dev/null; then
    exec hyprshot -m "$mode"
fi

command -v grim >/dev/null || { notify-send "Screenshot" "Install grim (and slurp for regions)."; exit 2; }
dir="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

case "$mode" in
output)
    # the display with the mouse on it, if the compositor can tell us
    out=""
    command -v mmsg >/dev/null && out=$(mmsg -g -o 2>/dev/null | awk '$2=="selmon" && $3=="1" {print $1; exit}')
    if [ -n "$out" ]; then grim -o "$out" "$file"; else grim "$file"; fi
    ;;
*)
    # window mode has no standard way outside Hyprland: pick a region instead
    command -v slurp >/dev/null || { notify-send "Screenshot" "Install slurp to pick a region."; exit 2; }
    geo=$(slurp) || exit 1
    grim -g "$geo" "$file"
    ;;
esac || exit 1

command -v wl-copy >/dev/null && wl-copy < "$file"
command -v notify-send >/dev/null && notify-send -i "$file" "Screenshot saved" "$file"
