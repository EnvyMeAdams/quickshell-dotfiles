import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// MangoWM side of services/Compositor.qml. Only loaded on MangoWM.
// Follows `mmsg -w`, which prints lines like:
//   eDP-1 selmon 1
//   eDP-1 tags 7 1 0                 occupied, selected, urgent (bitmasks)
//   eDP-1 tags 000000111 000000001 000000000   (same, in binary: skipped)
Scope {
    id: root

    property string focused: ""
    property var active: ({})
    property var occupied: ({})
    property int failures: 0

    Process {
        id: watch
        running: true
        command: ["mmsg", "-w"]
        stdout: SplitParser { onRead: line => root.parse(line) }
        onExited: {
            // mmsg missing or a version that doesn't know -w: give up after a few tries
            if (++root.failures < 5) retry.restart();
            else Compositor.backendError = "mmsg -w isn't working, so tags aren't shown";
        }
    }
    Timer { id: retry; interval: 3000; onTriggered: watch.running = true }

    function bits(n) {
        const r = [];
        for (let i = 0; i < 31; i++) if (n & (1 << i)) r.push(i + 1);
        return r;
    }

    function parse(line) {
        const p = line.trim().split(/\s+/);
        if (p.length < 3) return;
        failures = 0;
        const mon = p[0], key = p[1];
        if (key === "selmon") {
            if (p[2] === "1") focused = mon;
        } else if (key === "tags" && p.length >= 4) {
            if (/^[01]{6,}$/.test(p[2])) return;
            const occ = parseInt(p[2]), sel = parseInt(p[3]);
            if (isNaN(occ) || isNaN(sel)) return;
            const a = Object.assign({}, active);
            a[mon] = bits(sel)[0] ?? 0;
            active = a;
            const o = Object.assign({}, occupied);
            o[mon] = bits(occ | sel);
            occupied = o;
        }
    }
}
