pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string kind: "none"     // wifi | ethernet | none
    property string name: ""
    property bool wifiEnabled: true
    property bool hasWifi: false
    property var networks: []
    property bool scanning: false
    property string connecting: ""
    property string needsPassword: ""

    Process {
        id: status
        command: ["sh", "-c", "nmcli -t -f TYPE,STATE,CONNECTION device; echo \"RADIO:$(nmcli radio wifi)\""]
        stdout: StdioCollector { onStreamFinished: root.parseStatus(text) }
    }
    Timer {
        interval: 5000; repeat: true; running: true; triggeredOnStart: true
        onTriggered: status.running = true
    }
    function refresh() { status.running = true; }

    function parseStatus(t) {
        let k = "none", n = "", wifi = false;
        for (const line of t.trim().split("\n")) {
            if (line.startsWith("RADIO:")) { root.wifiEnabled = line.slice(6).trim() === "enabled"; continue; }
            const parts = line.split(":");
            const type = parts[0], state = parts[1], conn = parts.slice(2).join(":");
            if (type === "wifi") wifi = true;
            if (state !== "connected") continue;
            if (type === "ethernet" && k !== "ethernet") { k = "ethernet"; n = conn; }
            else if (type === "wifi" && k === "none") { k = "wifi"; n = conn; }
        }
        kind = k; name = n; hasWifi = wifi;
    }

    Process {
        id: scan
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "dev", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector { onStreamFinished: root.parseScan(text) }
        onExited: root.scanning = false
    }
    function rescan() { scanning = true; scan.running = true; }

    function parseScan(t) {
        const seen = {};
        for (const raw of t.split("\n")) {
            if (!raw) continue;
            // -t escapes ':' inside fields as '\:'
            const f = raw.replace(/\\:/g, "\u0001").split(":").map(x => x.replace(/\u0001/g, ":"));
            const ssid = f.slice(3).join(":");
            if (!ssid) continue;
            const net = { ssid: ssid, active: f[0] === "*", signal: parseInt(f[1]) || 0, secure: !!f[2] && f[2] !== "--" };
            if (!seen[ssid] || seen[ssid].signal < net.signal || net.active) seen[ssid] = net;
        }
        networks = Object.values(seen).sort((a, b) => (b.active - a.active) || (b.signal - a.signal));
    }

    Process {
        id: joiner
        onExited: code => {
            root.needsPassword = (code === 0) ? "" : root.connecting;
            root.connecting = "";
            root.refresh();
            root.rescan();
        }
    }
    function connect(ssid, password) {
        connecting = ssid;
        joiner.command = password ? ["nmcli", "dev", "wifi", "connect", ssid, "password", password]
                                  : ["nmcli", "dev", "wifi", "connect", ssid];
        joiner.running = true;
    }
    function disconnect(ssid) {
        Quickshell.execDetached(["nmcli", "con", "down", "id", ssid]);
        refreshLater.restart();
    }
    function setWifi(on) {
        wifiEnabled = on;
        Quickshell.execDetached(["nmcli", "radio", "wifi", on ? "on" : "off"]);
        refreshLater.restart();
    }
    Timer { id: refreshLater; interval: 1500; onTriggered: { root.refresh(); root.rescan(); } }

    function signalIcon(s) {
        if (s > 75) return "signal_wifi_4_bar";
        if (s > 50) return "network_wifi_3_bar";
        if (s > 25) return "network_wifi_2_bar";
        return "network_wifi_1_bar";
    }
}
