#!/bin/sh
# greetd runs this when the login screen uses MangoWM.
# Builds a config from the base + this machine's synced rules, then starts mango.
base=/etc/greetd/island
user=$base/user
cfg="${XDG_RUNTIME_DIR:-/tmp}/island-greeter-xdg"
mkdir -p "$cfg/mango"
cat "$base/mango.conf" "$user/mango.conf" > "$cfg/mango/config.conf" 2>/dev/null
[ -f "$user/cursor.env" ] && . "$user/cursor.env"
export XCURSOR_THEME XCURSOR_SIZE
XDG_CONFIG_HOME="$cfg" exec mango
