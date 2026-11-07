pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property MprisPlayer manual: null
    readonly property MprisPlayer player: (manual && players.includes(manual)) ? manual
        : (players.find(p => p.isPlaying) ?? players[0] ?? null)
    readonly property bool active: player !== null && (player.trackTitle ?? "") !== ""
    readonly property bool playing: player?.isPlaying ?? false
    readonly property real progress: (player && player.length > 0) ? Math.min(1, player.position / player.length) : 0

    // Mpris only reports position on demand
    Timer {
        running: root.playing
        interval: 1000
        repeat: true
        onTriggered: root.player?.positionChanged()
    }

    // ── buttons ──
    readonly property bool canNext: player?.canGoNext ?? false
    readonly property bool canPrev: player?.canGoPrevious ?? false
    readonly property bool canSeekNow: (player?.canSeek ?? false) && (player?.positionSupported ?? true)

    function toggle() {
        if (!player) return;
        if (player.canTogglePlaying) player.togglePlaying();
        else if (player.isPlaying) player.pause(); else player.play();
    }
    function next() {
        if (!player) return;
        if (canNext) player.next();
        else if (canSeekNow) skip(10);
    }
    // like a phone: past 5 s, Previous restarts the track first
    function prev() {
        if (!player) return;
        if (canSeekNow && player.position > 5) { player.position = 0; return; }
        if (canPrev) player.previous();
        else if (canSeekNow) skip(-10);
    }
    function skip(sec) {
        if (!canSeekNow) return;
        const len = player.length > 0 ? player.length : Infinity;
        player.position = Math.max(0, Math.min(len - 1, player.position + sec));
        player.positionChanged();
    }

    function fmt(sec) {
        if (!isFinite(sec) || sec < 0) sec = 0;
        const m = Math.floor(sec / 60), s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
    function seek(ratio) {
        if (player?.canSeek && player.length > 0) player.position = ratio * player.length;
    }
}
