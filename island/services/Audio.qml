pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? false

    readonly property var nodes: Pipewire.nodes.values

    // Quickshell marks app PLAYBACK streams as isSink (they feed a sink) and
    // RECORDING streams as !isSink. media.class is checked too when present.
    function mclass(n) { return n?.properties?.["media.class"] ?? ""; }
    function ignored(n) {
        const p = n?.properties ?? {};
        const name = ((p["application.name"] ?? "") + " " + (p["node.name"] ?? "") + " " + (p["media.name"] ?? "")).toLowerCase();
        // visualizer, volume meters and the recorder's own loopbacks
        return /cava|peak detect|pavucontrol|island_rec|loopback/.test(name);
    }
    function isPlayback(n) {
        if (!n?.isStream || !n.audio || ignored(n)) return false;
        const c = mclass(n);
        return c ? c.startsWith("Stream/Output/Audio") : n.isSink;
    }
    function isCapture(n) {
        if (!n?.isStream || !n.audio || ignored(n)) return false;
        const c = mclass(n);
        return c ? c.startsWith("Stream/Input/Audio") : !n.isSink;
    }

    // apps making sound
    readonly property var streams: nodes.filter(n => root.isPlayback(n))
    // real output and input devices
    readonly property var sinks: nodes.filter(n => !n.isStream && n.isSink && n.audio)
    readonly property var sources: nodes.filter(n => !n.isStream && !n.isSink && n.audio && !root.mclass(n).includes("Monitor"))
    // apps recording (mic light)
    readonly property var captures: nodes.filter(n => root.isCapture(n))
    readonly property bool micInUse: captures.length > 0

    // bind everything so volumes and properties stay live
    PwObjectTracker { objects: root.nodes.filter(n => n.audio || n.isStream) }

    function clamp(v) { return Math.max(0, Math.min(1, v)); }
    function setVolume(v) {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = clamp(v);
    }
    function nudge(d) { setVolume(volume + d); }
    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted; }
    function setMic(v) { if (source?.audio) { source.audio.muted = false; source.audio.volume = clamp(v); } }
    function toggleMic() { if (source?.audio) source.audio.muted = !source.audio.muted; }
    function setDefault(node) { Pipewire.preferredDefaultAudioSink = node; }
    function setDefaultSource(node) { Pipewire.preferredDefaultAudioSource = node; }
    function setNode(n, v) { if (n?.audio) { n.audio.muted = false; n.audio.volume = Math.max(0, Math.min(1.5, v)); } }
    function muteNode(n) { if (n?.audio) n.audio.muted = !n.audio.muted; }
    function detail(n) {
        const p = n?.properties ?? {};
        const m = p["media.name"] ?? "";
        return m && m !== nodeName(n) ? m : "";
    }
    function nodeName(n) {
        if (!n) return "";
        const p = n.properties ?? {};
        return p["application.name"] || n.description || n.nickname || n.name || "Unknown";
    }
    function nodeIcon(n) {
        const p = n?.properties ?? {};
        return p["application.icon-name"] || (p["application.name"] ?? "").toLowerCase();
    }
    function icon(vol, mute) {
        if (mute || vol <= 0.001) return "volume_off";
        if (vol < 0.4) return "volume_down";
        return "volume_up";
    }

    // Volume popup — ignore the burst of changes at startup
    property bool armed: false
    Timer { running: true; interval: 1500; onTriggered: root.armed = true }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.osd(); }
        function onMutedChanged() { root.osd(); }
    }
    function osd() {
        if (armed && Config.s.osdVolume) Island.flash("volume", Config.s.osdTimeout);
    }
}
