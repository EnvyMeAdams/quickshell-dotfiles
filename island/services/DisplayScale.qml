pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Display scaling (how big everything is drawn), per display.
//
// Your pick is saved in settings (displayScales: { "eDP-1": 1.5 }) and put back
// after a login or restart, because the compositor forgets runtime changes.
//   Hyprland  hyprctl keyword monitor NAME,preferred,auto,SCALE
//   others    wlr-randr --output NAME --scale SCALE (MangoWM, sway, river…)
Singleton {
    id: root

    readonly property var options: [1, 1.25, 1.5, 1.75, 2]

    // the scale a display uses now: your saved pick, else what it reports
    function current(name) {
        const saved = (Config.s.displayScales ?? {})[name];
        if (saved) return saved;
        const s = Quickshell.screens.find(x => x.name === name);
        return s ? Math.round(s.devicePixelRatio * 100) / 100 : 1;
    }

    function label(v) { return Math.round(v * 100) + "%"; }

    function set(name, v) {
        const d = Object.assign({}, Config.s.displayScales ?? {});
        d[name] = v;
        Config.s.displayScales = d;     // new object, so settings.json is saved
        apply(name, v);
    }

    function command(name, v) {
        if (Compositor.kind === "hyprland")
            return ["hyprctl", "keyword", "monitor", name + ",preferred,auto," + v];
        return ["wlr-randr", "--output", name, "--scale", String(v)];
    }

    // one change at a time; a newer pick replaces one still waiting
    property var waiting: []
    function apply(name, v) {
        waiting = waiting.filter(w => w.name !== name).concat([{ name: name, v: v }]);
        next();
    }
    function next() {
        if (worker.running || !waiting.length) return;
        const w = waiting[0];
        waiting = waiting.slice(1);
        worker.target = w;
        worker.command = command(w.name, w.v);
        worker.running = true;
    }
    Process {
        id: worker
        property var target: null
        stderr: StdioCollector { id: err }
        onExited: code => {
            if (code !== 0) {
                const why = err.text.trim().split("\n").slice(-1)[0]
                    || (code === 127 ? "wlr-randr isn't installed (gui-apps/wlr-randr)" : "exit code " + code);
                console.warn("island: scaling", target?.name, "failed:", why);
                Quickshell.execDetached(["notify-send", "-a", "Island",
                    "Couldn't change scaling on " + (target?.name ?? "the display"), why]);
            }
            root.next();
        }
    }

    // put saved scales back after login (give the compositor a moment first)
    Timer {
        interval: 1500
        running: true
        onTriggered: {
            const d = Config.s.displayScales ?? {};
            for (const n in d) {
                const s = Quickshell.screens.find(x => x.name === n);
                // skip displays that aren't plugged in, or already at that scale
                if (s && Math.abs(s.devicePixelRatio - d[n]) > 0.01) root.apply(n, d[n]);
            }
        }
    }
}
