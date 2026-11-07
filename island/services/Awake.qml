pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

// Decides when the screensaver and auto-lock must wait.
//   saverBlocked: anything playing, a call, fullscreen, recording, an app rule, Keep Awake
//   lockBlocked:  the same, except music alone still lets the screen lock
// When the reason goes away, it keeps waiting for a short grace period, so a
// video that pauses for a second (buffering, next episode, an ad) doesn't let
// the saver jump in.
Singleton {
    id: root

    property bool keepAwake: false

    // ANY player playing, not just the one shown in the island
    readonly property bool anyPlaying: Media.players.some(p => p.isPlaying)
    readonly property bool media: Config.s.pauseForMedia && anyPlaying
    readonly property bool call: Config.s.pauseForCalls && (Privacy.mic || Privacy.camera)
    readonly property bool full: Config.s.pauseForFullscreen && Compositor.fullscreen
    readonly property bool rec: Recorder.recording

    // ── app rules: Settings → Lock & Saver → Apps ──
    //   { app: "firefox", when: "sound" | "open" | "focused" }
    function norm(s) { return String(s ?? "").toLowerCase(); }
    function streamMatches(n, app) {
        const p = n?.properties ?? {};
        return [p["application.process.binary"], p["application.name"], p["application.id"], p["node.name"]]
            .some(v => norm(v).includes(app));
    }
    function windowMatches(t, app) { return norm(t?.appId).includes(app) || norm(t?.title).includes(app); }

    readonly property var matchedRule: {
        const rules = Config.s.awakeApps ?? [];
        for (const r of rules) {
            const app = norm(r.app).trim();
            if (!app) continue;
            if (r.when === "sound" && Audio.streams.some(n => root.streamMatches(n, app))) return r;
            if (r.when === "open" && ToplevelManager.toplevels.values.some(t => root.windowMatches(t, app))) return r;
            if (r.when === "focused" && root.windowMatches(ToplevelManager.activeToplevel, app)) return r;
        }
        return null;
    }
    readonly property bool appRule: matchedRule !== null

    readonly property bool saverRaw: keepAwake || media || call || full || rec || appRule
    readonly property bool lockRaw: keepAwake || call || full || rec || appRule || (media && Config.s.lockWaitsForMusic)

    // grace period after the reason ends
    onSaverRawChanged: {
        if (!saverRaw) saverGrace.restart();
        else if (LockState.saver) LockState.stopSaver();   // a video or call starting ends the saver
    }
    onLockRawChanged: if (!lockRaw) lockGrace.restart()
    Timer { id: saverGrace; interval: Config.s.awakeGrace * 1000 }
    Timer { id: lockGrace; interval: Config.s.awakeGrace * 1000 }

    readonly property bool saverBlocked: saverRaw || saverGrace.running
    readonly property bool lockBlocked: lockRaw || lockGrace.running

    readonly property string reason: keepAwake ? "Keep Awake" : rec ? "Recording" : call ? "Call"
        : appRule ? (matchedRule.app + (matchedRule.when === "sound" ? " playing" : matchedRule.when === "open" ? " open" : " focused"))
        : full ? "Fullscreen" : media ? "Playing"
        : (saverGrace.running ? "Just finished" : "")

    // suggestions for the app list: what's open and what's making sound right now
    readonly property var openApps: {
        const s = new Set();
        ToplevelManager.toplevels.values.forEach(t => { if (t.appId) s.add(norm(t.appId)); });
        return Array.from(s).sort();
    }
    readonly property var soundApps: {
        const s = new Set();
        Audio.streams.forEach(n => {
            const p = n.properties ?? {};
            const v = p["application.process.binary"] || p["application.name"];
            if (v) s.add(norm(v));
        });
        return Array.from(s).sort();
    }

    function addApp(app, when) {
        const a = norm(app).trim();
        if (!a) return;
        const list = (Config.s.awakeApps ?? []).filter(r => !(norm(r.app) === a));
        list.push({ app: a, when: when || "sound" });
        Config.s.awakeApps = list;
    }
    function setWhen(i, when) {
        const list = (Config.s.awakeApps ?? []).slice();
        if (!list[i]) return;
        list[i] = { app: list[i].app, when: when };
        Config.s.awakeApps = list;
    }
    function removeApp(i) {
        const list = (Config.s.awakeApps ?? []).slice();
        list.splice(i, 1);
        Config.s.awakeApps = list;
    }
}
