#!/bin/sh
# Night light for the island. One run at a time (the island queues them).
#   night.sh on <kelvin> <hyprland|mango|other>
#   night.sh off <...>
# Changing the warmth while it's on talks to the running hyprsunset over IPC
# instead of restarting it, because a hyprsunset that's quitting resets the
# screen to cool and can undo the new colour.

mode=$1; k=$2; wm=$3

wait_gone() {   # wait (up to 2 s) until the old process has really exited
    i=0
    while pgrep -x "$1" >/dev/null 2>&1 && [ $i -lt 40 ]; do sleep 0.05; i=$((i + 1)); done
}

if [ "$wm" = hyprland ] && command -v hyprsunset >/dev/null 2>&1; then
    if [ "$mode" = off ]; then
        pkill -x hyprsunset; wait_gone hyprsunset; exit 0
    fi
    if pgrep -x hyprsunset >/dev/null 2>&1; then
        hyprctl hyprsunset temperature "$k" >/dev/null 2>&1
        sleep 0.1
        # did it take? (older hyprsunset has no IPC: fall through and restart)
        now=$(hyprctl hyprsunset temperature 2>/dev/null | tr -dc '0-9')
        [ "$now" = "$k" ] && exit 0
        pkill -x hyprsunset; wait_gone hyprsunset
    fi
    setsid hyprsunset -t "$k" >/dev/null 2>&1 &
    exit 0
fi

# wlsunset (MangoWM and others): no IPC, so stop it fully, then start again
pkill -x wlsunset; wait_gone wlsunset
[ "$mode" = on ] && command -v wlsunset >/dev/null 2>&1 && setsid wlsunset -T $((k + 1)) -t "$k" >/dev/null 2>&1 &
exit 0
