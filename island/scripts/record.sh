#!/bin/sh
# Screen recording for the island.
#   record.sh start <mic 0|1> <desktop 0|1> <screen|region> <folder> <output> <fps>
#   record.sh stop        prints the saved file
#   record.sh status      exit 0 while recording
#
# Mic + desktop together: a temporary PipeWire mix sink ("Island Recording")
# gets both your mic and your speakers' monitor looped into it, and that mix is
# recorded. It's removed again when recording stops.

state="${XDG_RUNTIME_DIR:-/tmp}/island-record"

unload() {
    [ -f "$state/modules" ] || return
    while read -r m; do [ -n "$m" ] && pactl unload-module "$m" 2>/dev/null; done < "$state/modules"
}

case "$1" in
status)
    [ -f "$state/pid" ] && kill -0 "$(cat "$state/pid")" 2>/dev/null
    exit $?
    ;;
stop)
    [ -f "$state/pid" ] || exit 1
    pid=$(cat "$state/pid")
    kill -INT "$pid" 2>/dev/null
    i=0
    while kill -0 "$pid" 2>/dev/null && [ $i -lt 30 ]; do sleep 0.2; i=$((i + 1)); done
    unload
    cat "$state/file" 2>/dev/null
    rm -rf "$state"
    exit 0
    ;;
start)
    mic=$2; desk=$3; mode=$4; dir=$5; out=$6; fps=${7:-60}
    command -v wf-recorder >/dev/null || { echo "wf-recorder is not installed" >&2; exit 2; }
    [ -f "$state/pid" ] && kill -0 "$(cat "$state/pid")" 2>/dev/null && exit 0
    rm -rf "$state"; mkdir -p "$state" "$dir"; : > "$state/modules"

    geo=""
    if [ "$mode" = region ]; then
        command -v slurp >/dev/null || { echo "slurp is not installed" >&2; rm -rf "$state"; exit 2; }
        geo=$(slurp) || { rm -rf "$state"; exit 1; }
    fi

    audio=""
    if [ "$mic" = 1 ] || [ "$desk" = 1 ]; then
        command -v pactl >/dev/null || { echo "pactl is not installed (pipewire-pulse)" >&2; rm -rf "$state"; exit 2; }
        sink=$(pactl get-default-sink); src=$(pactl get-default-source)
        if [ "$mic" = 1 ] && [ "$desk" = 1 ]; then
            pactl load-module module-null-sink sink_name=island_rec sink_properties=device.description=Island-Recording >> "$state/modules"
            pactl load-module module-loopback source="$sink.monitor" sink=island_rec latency_msec=20 >> "$state/modules"
            pactl load-module module-loopback source="$src" sink=island_rec latency_msec=20 >> "$state/modules"
            audio="island_rec.monitor"
        elif [ "$desk" = 1 ]; then
            audio="$sink.monitor"
        else
            audio="$src"
        fi
    fi

    file="$dir/Recording $(date '+%Y-%m-%d %H-%M-%S').mp4"
    set -- -f "$file" -r "$fps"
    if [ -n "$geo" ]; then set -- "$@" -g "$geo"
    elif [ -n "$out" ]; then set -- "$@" -o "$out"; fi
    [ -n "$audio" ] && set -- "$@" --audio="$audio"

    echo "$file" > "$state/file"
    nohup wf-recorder "$@" > "$state/log" 2>&1 &
    echo $! > "$state/pid"
    sleep 0.6
    if ! kill -0 "$(cat "$state/pid")" 2>/dev/null; then
        unload; tail -n 3 "$state/log" >&2; rm -rf "$state"; exit 3
    fi
    exit 0
    ;;
esac
exit 1
