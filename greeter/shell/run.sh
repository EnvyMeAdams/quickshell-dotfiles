#!/bin/sh
# Started by the login screen's compositor (Hyprland or MangoWM). Shows the
# login screen, then closes that compositor so greetd can start your session.
dir=$(dirname "$(readlink -f "$0")")
log="${XDG_RUNTIME_DIR:-/tmp}/island-greeter.log"

quickshell -p "$dir" >"$log" 2>&1

# Quickshell has exited (you signed in, or it crashed): leave the compositor.
if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
    if command -v hyprshutdown >/dev/null 2>&1; then hyprshutdown
    else hyprctl dispatch 'hl.dsp.exit()' >/dev/null 2>&1 || hyprctl dispatch exit >/dev/null 2>&1
    fi
elif command -v mmsg >/dev/null 2>&1; then
    mmsg dispatch quit >/dev/null 2>&1
fi
sleep 2
# helpers the compositor or Quickshell started for this account (portals,
# a D-Bus they autolaunched) would otherwise outlive the login screen
pkill -U "$(id -u)" -f '/usr/libexec/xdg-desktop-portal' 2>/dev/null
pkill -U "$(id -u)" -x dbus-daemon 2>/dev/null
# last resort: only this account's own compositor
pkill -U "$(id -u)" -x Hyprland 2>/dev/null
pkill -U "$(id -u)" -x mango 2>/dev/null
exit 0
