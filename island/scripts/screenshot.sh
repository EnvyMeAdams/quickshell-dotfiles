#!/bin/sh
# Screenshot for the island, on any compositor.
#   screenshot.sh region|output|window
# Hyprland with hyprshot installed: hyprshot does it.
# Anything else: grim + slurp, saved to ~/Pictures/Screenshots and copied.
#   region  drag a box
#   output  the display you're on (MangoWM: the focused one; else all)
#   window  click a window (MangoWM); elsewhere it falls back to a box
# Folder: $SCREENSHOT_DIR, else $XDG_PICTURES_DIR/Screenshots.
mode=${1:-region}

if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ] && command -v hyprshot >/dev/null; then
    exec hyprshot -m "$mode"
fi

command -v grim >/dev/null || { notify-send "Screenshot" "Install grim (and slurp for regions)."; exit 2; }
dir="${SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}"
mkdir -p "$dir"
file="$dir/$(date +%Y-%m-%d_%H-%M-%S).png"

mango=""
[ -n "$MANGO_INSTANCE_SIGNATURE" ] && command -v mmsg >/dev/null && command -v python3 >/dev/null && mango=1

# mango's focused display name
mango_output() {
    mmsg get all-monitors 2>/dev/null | python3 -c '
import json, sys
for m in json.load(sys.stdin).get("monitors", []):
    if m.get("active"): print(m["name"]); break'
}
# every window you can see, as slurp boxes: "x,y wxh title"
mango_windows() {
    mmsg get all-clients 2>/dev/null | python3 -c '
import json, sys
for c in json.load(sys.stdin).get("clients", []):
    if c.get("is_visible") and not c.get("is_minimized") and c.get("width", 0) > 0:
        print("%d,%d %dx%d %s" % (c["x"], c["y"], c["width"], c["height"], (c.get("title") or "").replace("\n", " ")))'
}

need_slurp() { command -v slurp >/dev/null || { notify-send "Screenshot" "Install slurp to pick a region."; exit 2; }; }

case "$mode" in
output)
    out=""
    [ -n "$mango" ] && out=$(mango_output)
    if [ -n "$out" ]; then grim -o "$out" "$file"; else grim "$file"; fi
    ;;
window)
    need_slurp
    boxes=""
    [ -n "$mango" ] && boxes=$(mango_windows)
    if [ -n "$boxes" ]; then
        # -r: only the listed windows can be picked (click one)
        geo=$(printf '%s\n' "$boxes" | slurp -r -f '%x,%y %wx%h') || exit 1
    else
        geo=$(slurp) || exit 1
    fi
    grim -g "$geo" "$file"
    ;;
*)
    need_slurp
    geo=$(slurp) || exit 1
    grim -g "$geo" "$file"
    ;;
esac || exit 1

command -v wl-copy >/dev/null && wl-copy --type image/png < "$file"
command -v notify-send >/dev/null && notify-send -i "$file" "Screenshot saved" "${file#"$HOME"/}"
exit 0
