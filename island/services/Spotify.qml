pragma Singleton
import QtQuick
import Quickshell

// Spotify extras through Spicetify (extras/spicetify/island-bridge.js):
// liked, synced lyrics, Canvas video, up next. Play/pause/art still come
// from MPRIS (Media.qml), so all of this is a bonus: no bridge, no change.
Singleton {
    id: root

    property var server: null
    property string loadError: ""            // e.g. QtWebSockets missing
    readonly property bool connected: !!server && !!server.client
    readonly property bool current: /spotify/i.test(Media.player?.identity ?? "") || /spotify/i.test(Media.player?.desktopEntry ?? "")
    readonly property bool on: connected && current

    property string uri: ""
    property bool liked: false
    property var lines: []                   // [{ t: ms, w: text }]
    property bool synced: false
    property string canvas: ""
    property var upNext: []
    property real ms: 0                      // position from Spotify
    property real at: 0                      // when ms was measured
    property bool playing: false
    property real now: 0                     // ticks while lyrics need it

    readonly property int lineIndex: {
        if (!synced || lines.length === 0) return -1;
        const p = ms + (playing ? Math.max(0, now - at) : 0) + 250;    // a hair early reads better
        let i = -1;
        for (let k = 0; k < lines.length; k++) { if (lines[k].t <= p) i = k; else break; }
        return i;
    }
    readonly property string line: lineIndex >= 0 ? (lines[lineIndex].w || "♪") : ""

    Timer {
        interval: 200
        repeat: true
        running: root.on && root.synced && root.playing
        onTriggered: root.now = Date.now()
    }

    function start() {
        if (server || !Config.s.spotifyBridge) return;
        const c = Qt.createComponent(Qt.resolvedUrl("SpotifyBridge.qml"));
        if (c.status !== Component.Ready) {
            loadError = "Needs QtWebSockets (dev-qt/qtwebsockets)";
            console.warn("island: Spotify bridge off:", c.errorString().split("\n")[0]);
            return;
        }
        server = c.createObject(root, { port: Config.s.spotifyPort });
        server.message.connect(o => root.take(o));
        server.gone.connect(() => { root.lines = []; root.canvas = ""; root.upNext = []; });
        loadError = "";
    }
    function stop() { if (server) { server.destroy(); server = null; } }
    Component.onCompleted: start()
    Connections {
        target: Config.s
        function onSpotifyBridgeChanged() { Config.s.spotifyBridge ? root.start() : root.stop(); }
        function onSpotifyPortChanged() { root.stop(); root.start(); }
    }

    function take(o) {
        if (o.type === "state") {
            liked = !!o.liked; playing = !!o.playing;
            ms = o.ms ?? 0; at = Date.now(); now = at;
        } else if (o.type === "track") {
            const changed = uri !== "" && uri !== o.uri;
            uri = o.uri ?? ""; lines = []; synced = false; canvas = "";
            if (changed && Config.s.spotifyToast && Media.player)
                Island.showActivity({ image: Media.player.trackArtUrl ?? "", icon: "music_note", tint: "green",
                                      title: o.title ?? "", sub: o.artist ?? "", tab: "home" }, 2200);
        } else if (o.type === "lyrics" && o.uri === uri) {
            lines = o.lines ?? []; synced = !!o.synced;
        } else if (o.type === "canvas" && o.uri === uri) {
            canvas = o.url ?? "";
        } else if (o.type === "queue") {
            upNext = o.next ?? [];
        }
    }

    function heart() { if (server) { server.send({ cmd: "heart" }); liked = !liked; } }
}
