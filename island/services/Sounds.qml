pragma Singleton
import QtQuick
import Quickshell

// Your own sound files for island events. Every event starts with no sound,
// so nothing plays until you pick a file in Settings → Sounds.
// Plays through Qt Multimedia (mp3, ogg, wav, flac, m4a); without it, falls
// back to PipeWire's pw-play (wav/ogg/flac, mp3 if libsndfile supports it).
Singleton {
    id: root

    // every event the island can make a sound for, in Settings order
    readonly property var events: [
        { k: "notification", l: "Notification",      i: "notifications",       h: "Not during Do Not Disturb" },
        { k: "lock",         l: "Lock",              i: "lock",                h: "" },
        { k: "unlock",       l: "Unlock",            i: "lock_open",           h: "" },
        { k: "wrongPassword", l: "Wrong Password",   i: "password",            h: "" },
        { k: "fpMatch",      l: "Fingerprint Match", i: "fingerprint",         h: "Plays as the lock opens", fp: true },
        { k: "fpMiss",       l: "Fingerprint Miss",  i: "do_not_touch",        h: "", fp: true },
        { k: "screenshot",   l: "Screenshot",        i: "screenshot_region",   h: "Not when you cancel" },
        { k: "recordStart",  l: "Recording Start",   i: "radio_button_checked", h: "Desktop Sound may record it" },
        { k: "recordStop",   l: "Recording Stop",    i: "stop_circle",         h: "" },
        { k: "charger",      l: "Charger Plugged In", i: "power",              h: "Laptops", battery: true },
        { k: "lowBattery",   l: "Low Battery",       i: "battery_alert",       h: "Once, at 15%", battery: true }
    ]
    readonly property var formats: ["*.mp3", "*.ogg", "*.oga", "*.wav", "*.flac", "*.m4a", "*.opus"]

    property bool qtOk: false           // Qt Multimedia available
    property var players: []
    property int next: 0

    function fileFor(k) { return ((Config.s.sounds ?? {})[k]) || ""; }
    function nameFor(k) { const f = fileFor(k); return f ? f.replace(/^.*\//, "") : ""; }
    function setFile(k, path) {
        const m = Object.assign({}, Config.s.sounds ?? {});
        if (path) m[k] = path.replace(Config.home, "~"); else delete m[k];
        Config.s.sounds = m;
    }

    // play the sound picked for an event (if any)
    function play(k) {
        if (!Config.s.soundsOn) return;
        const f = fileFor(k);
        if (f) playFile(Config.expand(f));
    }
    // play any file (Settings preview)
    function playFile(path) {
        if (!path) return;
        const vol = Config.s.soundVolume;
        if (qtOk && players.length) {
            // a free player, else the oldest one
            let p = players.find(x => !x.busy);
            if (!p) { p = players[next % players.length]; next++; }
            p.play("file://" + path.split("/").map(encodeURIComponent).join("/"), vol);
        } else {
            Quickshell.execDetached(["pw-play", "--volume", String(vol), path]);
        }
    }
    function stopAll() { players.forEach(p => p.stop()); }

    Component.onCompleted: {
        const c = Qt.createComponent(Qt.resolvedUrl("../media/SoundPlayer.qml"));
        qtOk = c.status === Component.Ready;
        if (!qtOk) { console.warn("island: sounds use pw-play:", c.errorString()); return; }
        const list = [];
        for (let i = 0; i < 3; i++) list.push(c.createObject(root));
        players = list;
    }
}
