import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// MangoWM side of services/Compositor.qml. Only loaded on MangoWM.
//
// Follows `mmsg watch all-monitors` (mango 0.18+). It prints the full state
// once on connect and again on every change, one JSON object per line:
//   {"monitors":[{"name":"eDP-1","active":true,
//                 "tags":[{"index":1,"is_active":true,"client_count":2,...},...],
//                 "active_tags":[1], ...}]}
// active = the focused display, active_tags = tags shown on it ([0] while the
// overview is open), client_count > 0 = the tag has windows.
Scope {
    id: root

    property string focused: ""
    property var active: ({})
    property var occupied: ({})
    property int failures: 0

    readonly property bool hasSocket: (Quickshell.env("MANGO_INSTANCE_SIGNATURE") || "") !== ""

    Process {
        id: watch
        running: root.hasSocket
        command: ["mmsg", "watch", "all-monitors"]
        stdout: SplitParser { onRead: line => root.parse(line) }
        onExited: {
            // mango restarted, or mmsg is missing: try a few times, then say so
            if (++root.failures < 5) retry.restart();
            else Compositor.backendError = "mmsg watch isn't working, so tags aren't shown";
        }
    }
    Timer { id: retry; interval: 3000; onTriggered: watch.running = true }

    Component.onCompleted: {
        if (!hasSocket) Compositor.backendError = "MANGO_INSTANCE_SIGNATURE isn't set (start Quickshell from mango)";
    }

    function parse(line) {
        let j;
        try { j = JSON.parse(line); } catch (e) { return; }
        if (!j || !Array.isArray(j.monitors)) return;
        failures = 0;
        Compositor.backendError = "";

        const a = {}, o = {};
        let f = "";
        for (const m of j.monitors) {
            if (!m || !m.name) continue;
            if (m.active) f = m.name;
            const tags = Array.isArray(m.tags) ? m.tags : [];
            const shown = (m.active_tags || []).filter(t => t > 0);
            // overview open ([0]): keep showing the tag you came from
            a[m.name] = shown.length ? shown[0] : (active[m.name] ?? 0);
            const list = [];
            for (const t of tags)
                if (t.client_count > 0 || t.is_active) list.push(t.index);
            for (const t of shown) if (!list.includes(t)) list.push(t);
            list.sort((x, y) => x - y);
            o[m.name] = list;
        }
        if (f) focused = f;
        active = a;
        occupied = o;
    }

    // Same idea as Hypr.qml's helpers, for anything that wants to switch tags
    function view(tag) { Quickshell.execDetached(["mmsg", "dispatch", "view," + tag]); }
}
