import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.services

// Hyprland side of services/Compositor.qml. Only loaded on Hyprland.
Scope {
    id: root

    readonly property string focused: Hyprland.focusedMonitor?.name ?? ""

    readonly property var active: {
        const r = {};
        for (const m of Hyprland.monitors.values) r[m.name] = m.activeWorkspace?.id ?? 0;
        return r;
    }
    readonly property var occupied: {
        const r = {};
        for (const w of Hyprland.workspaces.values) {
            const n = w.monitor?.name;
            if (w.id <= 0 || !n) continue;
            if (!r[n]) r[n] = [];
            r[n].push(w.id);
        }
        for (const k in r) r[k].sort((a, b) => a - b);
        return r;
    }

    // Same actions as Hyprland global shortcuts:  island:launcher, island:lock, ...
    GlobalShortcut { appid: "island"; name: "launcher"; onPressed: Island.toggle("launcher") }
    GlobalShortcut { appid: "island"; name: "sound"; onPressed: Island.toggleHub("sound") }
    GlobalShortcut { appid: "island"; name: "control"; onPressed: Island.toggleHub("control") }
    GlobalShortcut { appid: "island"; name: "wallpaper"; onPressed: Island.toggleHub("wallpaper") }
    GlobalShortcut { appid: "island"; name: "settings"; onPressed: Island.toggleHub("settings") }
    GlobalShortcut { appid: "island"; name: "lock"; onPressed: LockState.lock() }
    GlobalShortcut { appid: "island"; name: "windows"; onPressed: Windows.step(1) }
    GlobalShortcut { appid: "island"; name: "saver"; onPressed: LockState.startSaver() }
    GlobalShortcut { appid: "island"; name: "record"; onPressed: Recorder.toggle() }
}
