#!/bin/sh
# Starts your session after you sign in. greetd joins the launch command into
# one line, so anything with quotes or spaces lives here instead of in QML.
#   session.sh <the session's Exec line...>
export XDG_SESSION_TYPE=wayland
log="${XDG_CACHE_HOME:-$HOME/.cache}/island-session.log"
mkdir -p "$(dirname "$log")" 2>/dev/null
echo "$(date '+%F %T') starting: $*" > "$log" 2>/dev/null

# Without systemd there's no user D-Bus, so give the session its own
# (like "dbus-run-session start-hyprland" from a tty).
if [ -d /run/systemd/system ] || [ "$1" = dbus-run-session ] || [ "$1" = uwsm ]; then
    exec "$@" >>"$log" 2>&1
fi
exec dbus-run-session "$@" >>"$log" 2>&1
