import QtQuick
import QtWebSockets

// The island end of the Spicetify bridge. Loaded at runtime by Spotify.qml,
// so a Quickshell without QtWebSockets just has no Spotify extras.
// Listens on 127.0.0.1 only; one client (the Spotify app) at a time.
WebSocketServer {
    id: server

    property var client: null
    signal message(var obj)
    signal gone()

    host: "127.0.0.1"
    name: "island"
    listen: true
    accept: true

    onClientConnected: ws => {
        if (server.client) { try { server.client.active = false; } catch (e) {} }   // newest Spotify window wins
        server.client = ws;
        ws.textMessageReceived.connect(text => {
            let o;
            try { o = JSON.parse(text); } catch (e) { return; }
            server.message(o);
        });
        ws.statusChanged.connect(() => {
            if (ws.status !== WebSocket.Open && server.client === ws) { server.client = null; server.gone(); }
        });
    }

    function send(obj) {
        if (client && client.status === WebSocket.Open) client.sendTextMessage(JSON.stringify(obj));
    }
}
