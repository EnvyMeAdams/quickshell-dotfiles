pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

// ALT+TAB. Each press moves the pick; stop pressing for a moment (Switch
// Delay in Settings → Pill) and the picked window is focused.
// Uses the standard Wayland window list, so it works on any compositor.
Singleton {
    id: root

    property int index: 0
    property var list: []
    property int presses: 0
    property var recent: []             // most recently focused first

    // remember focus order (the window list itself has none)
    function noteActive() {
        const all = ToplevelManager.toplevels.values;
        const a = all.find(t => t.activated);
        const r = recent.filter(t => t !== a && all.includes(t));
        if (a) r.unshift(a);
        recent = r;
    }
    Connections {
        target: ToplevelManager
        ignoreUnknownSignals: true
        function onActiveToplevelChanged() { root.noteActive(); }
    }
    // backup for Quickshell versions without activeToplevel
    Timer { interval: 1000; repeat: true; running: Island.mode !== "windows"; onTriggered: root.noteActive() }

    function order() {
        root.noteActive();
        const all = ToplevelManager.toplevels.values.slice();
        const rank = t => { const i = recent.indexOf(t); return i < 0 ? 999 : i; };
        return all.sort((a, b) => rank(a) - rank(b));
    }

    function step(dir) {
        if (Island.mode !== "windows") {
            list = order();
            if (list.length === 0) return;
            index = list.length > 1 ? (dir > 0 ? 1 : list.length - 1) : 0;
            presses = 1;
            Island.mode = "windows";
        } else if (list.length > 0) {
            index = (index + dir + list.length) % list.length;
            presses++;
        }
        commit.interval = Config.s.switchDelay;
        commit.restart();
    }

    function pick(i) { index = i; finish(); }

    function finish() {
        commit.stop();
        const t = list[index];
        Island.close();
        if (t) t.activate();
    }

    Timer { id: commit; onTriggered: root.finish() }

    function appId(t) { return t?.appId || ""; }
    function title(t) { return t?.title || appId(t); }
    // Hyprland workspace / Mango tag isn't part of the standard window list
    function where(t) { return ""; }
}
