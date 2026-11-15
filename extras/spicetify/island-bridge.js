// island-bridge.js — Spicetify extension for the quickshell-dotfiles island.
// Sends what MPRIS can't (liked, synced lyrics, Canvas, up next) to the island
// over a WebSocket on 127.0.0.1 only, and takes a few commands back
// (heart, seek). Nothing leaves your computer.
//
// Install:  cp island-bridge.js ~/.config/spicetify/Extensions/
//           spicetify config extensions island-bridge.js && spicetify apply
(function islandBridge() {
    const S = window.Spicetify;
    // connect as soon as Spicetify is up; a track isn't needed yet
    if (!S || !S.Player || !S.Player.addEventListener || !S.CosmosAsync) {
        setTimeout(islandBridge, 500);
        return;
    }

    const PORT = 47719;          // must match Settings › Media › Spotify › Port
    let ws = null;
    let lastUri = "";

    function send(obj) {
        if (ws && ws.readyState === 1) ws.send(JSON.stringify(obj));
    }

    function connect() {
        try { ws = new WebSocket("ws://127.0.0.1:" + PORT); }
        catch (e) { setTimeout(connect, 5000); return; }
        ws.onopen = () => { lastUri = ""; track(); };
        ws.onclose = () => { ws = null; setTimeout(connect, 5000); };
        ws.onerror = () => {};
        ws.onmessage = (e) => {
            let m;
            try { m = JSON.parse(e.data); } catch (err) { return; }
            if (m.cmd === "heart") S.Player.toggleHeart();
            else if (m.cmd === "seek" && typeof m.ms === "number") S.Player.seek(m.ms);
            else if (m.cmd === "refresh") lastUri = "";
            setTimeout(() => { state(); track(); }, 300);
        };
    }

    function current() { const d = S.Player.data; return d && (d.item || d.track); }

    function state() {
        if (!current()) return;
        send({ type: "state", liked: !!S.Player.getHeart(), playing: S.Player.isPlaying(),
               ms: S.Player.getProgress(), at: Date.now() });
    }

    async function lyrics(id) {
        try {
            const r = await S.CosmosAsync.get(
                "https://spclient.wg.spotify.com/color-lyrics/v2/track/" + id +
                "?format=json&vocalRemoval=false&market=from_token");
            const l = r && r.lyrics;
            if (!l || !l.lines) return { synced: false, lines: [] };
            return {
                synced: l.syncType === "LINE_SYNCED",
                lines: l.lines.map(x => ({ t: parseInt(x.startTimeMs) || 0, w: x.words || "" }))
            };
        } catch (e) { return { synced: false, lines: [] }; }
    }

    // Canvas: the looping video some songs have. Uses Spotify's own internal
    // query, so a Spotify update can break it; then it just stays empty.
    async function canvas(uri) {
        try {
            const def = S.GraphQL && S.GraphQL.Definitions && S.GraphQL.Definitions.canvas;
            if (!def) return "";
            const r = await S.GraphQL.Request(def, { uri: uri });
            const c = r && r.data && r.data.trackUnion && r.data.trackUnion.canvas;
            return (c && c.url && /\.mp4/.test(c.url)) ? c.url : "";
        } catch (e) { return ""; }
    }

    function upNext() {
        try {
            const q = (S.Queue && S.Queue.nextTracks) || [];
            return q.slice(0, 3).map(t => {
                const md = (t.contextTrack && t.contextTrack.metadata) || {};
                return { title: md.title || "", artist: md.artist_name || "" };
            }).filter(t => t.title);
        } catch (e) { return []; }
    }

    async function track() {
        const it = current();
        if (!it || !it.uri) return;
        state();
        send({ type: "queue", next: upNext() });
        if (it.uri === lastUri) return;
        lastUri = it.uri;
        const md = it.metadata || {};
        send({ type: "track", uri: it.uri, title: md.title || it.name || "", artist: md.artist_name || "" });
        const id = it.uri.split(":")[2];
        if (it.uri.startsWith("spotify:track:") && id) {
            const [ly, cv] = await Promise.all([lyrics(id), canvas(it.uri)]);
            if (lastUri !== it.uri) return;          // skipped meanwhile
            send({ type: "lyrics", uri: it.uri, synced: ly.synced, lines: ly.lines });
            send({ type: "canvas", uri: it.uri, url: cv });
        } else {
            send({ type: "lyrics", uri: it.uri, synced: false, lines: [] });
            send({ type: "canvas", uri: it.uri, url: "" });
        }
    }

    S.Player.addEventListener("songchange", () => track());
    S.Player.addEventListener("onplaypause", () => state());
    // keep lyrics in time without flooding: one position update a second
    let lastPos = 0;
    S.Player.addEventListener("onprogress", () => {
        const now = Date.now();
        if (now - lastPos < 1000) return;
        lastPos = now;
        state();
    });
    // the heart and queue can change without a song change
    setInterval(() => { if (ws) { state(); send({ type: "queue", next: upNext() }); } }, 5000);

    connect();
})();
