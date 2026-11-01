pragma Singleton
import QtQuick
import Quickshell

// The island draws the desktop wallpaper itself (desktop/DesktopWindow.qml),
// photos and videos, per display. No swww or mpvpaper needed.
// Config.s.desktop is { "*": {path, kind} } for every display,
// or one entry per display name, e.g. { "DP-1": {...}, "eDP-1": {...} }.
Singleton {
    id: root

    readonly property var displays: Quickshell.screens.map(s => s.name)

    // can this Quickshell play video? (needs Qt Multimedia)
    property bool videoOk: false
    property string videoError: ""
    Component.onCompleted: {
        const c = Qt.createComponent(Qt.resolvedUrl("../media/VideoBg.qml"));
        videoOk = c.status === Component.Ready;
        videoError = videoOk ? "" : c.errorString();
        if (!videoOk) console.warn("island: video wallpapers off:", videoError);
    }

    function current(output) {
        const d = Config.s.desktop ?? {};
        return d[output] ?? d["*"] ?? null;
    }

    function apply(path, kind, output) {
        output = output || "*";
        const old = Config.s.desktop ?? {};
        const d = {};
        if (output === "*") {
            d["*"] = { path: path, kind: kind };
        } else {
            // split "every display" into one entry per display first
            displays.forEach(n => { const e = old[n] ?? old["*"]; if (e) d[n] = e; });
            d[output] = { path: path, kind: kind };
        }
        Config.s.desktop = d;
    }

    // empty list = every display
    function onDisplay(list, name) { return !list || list.length === 0 || list.includes(name); }

    function setLock(path, kind) { Config.s.lockBg = path; Config.s.lockBgKind = kind; }
    function setSaver(path) { Config.s.saverVideo = path; }
}
