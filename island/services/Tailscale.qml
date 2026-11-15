pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Trayscale-style Tailscale control, straight from the tailscale command.
// Nothing shows anywhere unless `tailscale` is installed. Changing things
// (connect, exit nodes, toggles) needs your user set as the Tailscale
// operator once:  doas tailscale set --operator=$USER
Singleton {
    id: root

    // ── what we know ──
    property bool installed: false
    property bool daemon: false             // tailscaled answered
    property string state: ""               // Running | Stopped | NeedsLogin | NeedsMachineAuth | Starting | NoState
    readonly property bool up: state === "Running"
    property string authUrl: ""
    property var self: ({})                 // { name, dns, ips, os }
    property string tailnet: ""
    property string user: ""
    property var peers: []                  // your devices (not Mullvad)
    property var mullvad: []                // Mullvad exit nodes, if your tailnet has the add-on
    readonly property bool hasMullvad: mullvad.length > 0
    property var exitNode: null             // the peer in use as exit node, or null
    property bool exitOnline: true
    property var prefs: ({})                // RouteAll, CorpDNS, ShieldsUp, ExitNodeAllowLANAccess, …
    readonly property bool advertisingExit: (prefs.AdvertiseRoutes ?? []).some(r => r === "0.0.0.0/0" || r === "::/0")
    readonly property bool isOperator: (prefs.OperatorUser ?? "") === Quickshell.env("USER")
    property bool busy: false
    property string error: ""
    property string suggested: ""           // hostname from `tailscale exit-node suggest`
    property bool watching: false           // the panel is open: refresh faster
    property bool firstRead: true

    signal exitChanged(var node)            // live activity: "Connected via …"
    signal exitLost(var node)               // live activity: exit node went offline

    onExitChanged: node => {
        if (!Config.s.tsActivity) return;
        Island.showActivity({ emoji: flag(node.code), icon: "vpn_lock", tint: "aqua", tab: "tailscale",
                              title: "Connected via " + (node.code ? "Mullvad" : node.name),
                              sub: node.code ? place(node) : (node.ips[0] ?? "") }, 2800);
    }
    // this one matters for privacy, so it shows even with the other activity off
    onExitLost: node => {
        if (!Config.s.tsLostAlert) return;
        Island.showActivity({ icon: "warning", tint: "pink", tab: "tailscale",
                              title: "Exit Node Offline", sub: (place(node) || node.name) + " stopped answering" }, 5000);
        Sounds.play("tsLost");
    }

    // ── reading ──
    Process {
        id: probe
        running: true
        command: ["sh", "-c", "command -v tailscale >/dev/null && echo yes"]
        stdout: StdioCollector { onStreamFinished: { root.installed = text.trim() === "yes"; if (root.installed) root.refresh(); } }
    }

    Process {
        id: status
        command: ["sh", "-c", "tailscale status --json 2>/dev/null || exit 3; echo '@@PREFS@@'; tailscale debug prefs 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
        onExited: code => { if (code === 3) { root.daemon = false; root.state = ""; } }
    }
    Timer {
        interval: root.watching ? 4000 : 15000
        running: root.installed
        repeat: true
        onTriggered: root.refresh()
    }
    function refresh() { if (installed && !status.running) status.running = true; }
    Timer { id: soon; interval: 900; onTriggered: root.refresh() }

    function parse(t) {
        const cut = t.indexOf("@@PREFS@@");
        let st, pr = {};
        try { st = JSON.parse(cut >= 0 ? t.slice(0, cut) : t); } catch (e) { daemon = false; return; }
        try { if (cut >= 0) pr = JSON.parse(t.slice(cut + 9)); } catch (e) {}
        daemon = true;
        prefs = pr;
        state = st.BackendState ?? "";
        authUrl = st.AuthURL ?? "";
        tailnet = st.CurrentTailnet?.Name ?? "";
        const me = st.Self ?? {};
        const u = (st.User ?? {})[String(me.UserID)] ?? {};
        user = u.LoginName ?? u.DisplayName ?? "";
        self = { name: me.HostName ?? "", dns: (me.DNSName ?? "").replace(/\.$/, ""),
                 ips: me.TailscaleIPs ?? [], os: me.OS ?? "" };

        const mine = [], mv = [];
        let ex = null;
        for (const p of Object.values(st.Peer ?? {})) {
            const loc = p.Location ?? null;
            const row = {
                id: p.ID ?? "",
                name: (p.HostName || (p.DNSName ?? "").split(".")[0]).replace(/\.mullvad\.ts\.net\.?$/, ""),
                dns: (p.DNSName ?? "").replace(/\.$/, ""),
                ips: p.TailscaleIPs ?? [],
                os: p.OS ?? "",
                online: !!p.Online,
                lastSeen: p.LastSeen ?? "",
                exitOption: !!p.ExitNodeOption,
                exit: !!p.ExitNode,
                country: loc?.Country ?? "",
                code: loc?.CountryCode ?? "",
                city: loc?.City ?? "",
                priority: loc?.Priority ?? 0
            };
            if (row.exit) ex = row;
            (loc ? mv : mine).push(row);
        }
        mine.sort((a, b) => (b.exit - a.exit) || (b.online - a.online) || a.name.localeCompare(b.name));
        mv.sort((a, b) => a.country.localeCompare(b.country) || a.city.localeCompare(b.city) || (b.priority - a.priority));
        peers = mine;
        mullvad = mv;

        const online = st.ExitNodeStatus ? !!st.ExitNodeStatus.Online : true;
        const was = exitNode;
        exitNode = ex;
        if (!firstRead) {
            if (ex && (!was || was.id !== ex.id)) exitChanged(ex);
            if (ex && exitOnline && !online) exitLost(ex);
        }
        exitOnline = online;
        firstRead = false;
    }

    // ── changing things ──
    Process {
        id: runner
        stderr: StdioCollector { id: errOut }
        onExited: code => {
            root.busy = false;
            const e = errOut.text.trim();
            root.error = code === 0 ? "" : (/access denied|operator|permission/i.test(e)
                ? "Needs permission: see Settings › Tailscale › Set Up" : (e.split("\n")[0] || "Didn't work"));
            soon.restart();
        }
    }
    function run(args) {
        if (busy) return;                   // no double taps while it's switching
        busy = true;
        error = "";
        runner.command = ["tailscale"].concat(args);
        runner.running = true;
    }

    function connect() { run(["up"]); }
    function disconnect() { run(["down"]); }
    function toggle() { up ? disconnect() : connect(); }
    function login() {
        if (authUrl) { Quickshell.execDetached(["xdg-open", authUrl]); return; }
        run(["login"]);
        openAuth.restart();
    }
    // the login link shows up in status a moment after `tailscale login`
    Timer { id: openAuth; interval: 2500; onTriggered: { root.refresh(); authLater.restart(); } }
    Timer { id: authLater; interval: 800; onTriggered: if (root.authUrl) Quickshell.execDetached(["xdg-open", root.authUrl]) }

    function useExit(node) {
        // Tailscale itself remembers the exit node across disconnects and reboots
        run(["set", "--exit-node=" + (node ? (node.ips[0] ?? node.id) : "")]);
    }
    function setPref(flag, on) { run(["set", "--" + flag + "=" + (on ? "true" : "false")]); }

    Process {
        id: suggest
        command: ["tailscale", "exit-node", "suggest"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/Suggested exit node:\s*(\S+)/i);
                root.suggested = m ? m[1].replace(/\.$/, "") : "";
            }
        }
    }
    function findSuggestion() { if (installed && !suggest.running) suggest.running = true; }

    // Taildrop: files sent to this device land in the folder you choose
    Process {
        id: taildrop
        running: root.installed && root.up && Config.s.tsTaildrop
        command: ["sh", "-c", "d=\"$1\"; mkdir -p \"$d\" && exec tailscale file get --loop --verbose --conflict=rename \"$d\"",
                  "sh", Config.expand(Config.s.tsTaildropDir)]
        stderr: SplitParser {
            // --verbose prints a line per file it saves
            onRead: line => {
                const dir = Config.expand(Config.s.tsTaildropDir);
                const m = line.match(/wrote\s+(.+?)\s+as\s+(.+)$/i) || line.match(/(?:moved|saved)\s+(.+)$/i)
                       || (line.includes(dir) ? line.match(/(\S+)\s*$/) : null);
                if (m) Quickshell.execDetached(["notify-send", "-a", "Tailscale", "-i", "folder-download",
                                                "File Received", (m[2] || m[1]).replace(/^.*\//, "")]);
            }
        }
    }

    function copy(text) { Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", text]); }

    function flag(code) {
        // country code → flag emoji (works with any emoji font)
        if (!code || code.length !== 2) return "";
        return String.fromCodePoint(...[...code.toUpperCase()].map(c => 0x1F1E6 + c.charCodeAt(0) - 65));
    }
    function place(n) { return n ? (n.city ? n.city + ", " + n.country : n.country || n.name) : ""; }
    function seen(iso) {
        if (!iso || iso.startsWith("0001")) return "";
        const s = (Date.now() - Date.parse(iso)) / 1000;
        if (!isFinite(s) || s < 0) return "";
        if (s < 3600) return Math.max(1, Math.round(s / 60)) + " min ago";
        if (s < 86400) return Math.round(s / 3600) + " h ago";
        return Math.round(s / 86400) + " d ago";
    }
}
