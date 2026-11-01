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

    function fmt(sec) {
        if (!isFinite(sec) || sec < 0) sec = 0;
        const m = Math.floor(sec / 60), s = Math.floor(sec % 60);
        return m + ":" + (s < 10 ? "0" : "") + s;
    }
    function seek(ratio) {
        if (player?.canSeek && player.length > 0) player.position = ratio * player.length;
    }
}
