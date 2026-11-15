pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Signal through signal-cli, as a linked device of your phone (like Signal
// Desktop). The island starts `signal-cli daemon --socket` itself and talks
// JSON-RPC over that socket: messages in, replies/reactions/read receipts out.
// Messages live in memory only; nothing is written to disk by the island.
// Settings › Messages › Signal links the device and shows the steps.
Singleton {
    id: root

    readonly property bool on: Config.s.signalOn && Config.s.signalAccount !== ""
    // signal-cli can be a normal install or the Flathub one (org.asamk.SignalCli);
    // the island finds whichever is there. Flatpak is sandboxed, so its socket
    // lives in the one runtime folder both sides can see, and its keys live
    // under ~/.var/app.
    readonly property string flatpakId: "org.asamk.SignalCli"
    property string kind: ""                // native | flatpak | "" (not found)
    readonly property bool installed: kind !== ""
    readonly property var cli: kind === "flatpak" ? ["flatpak", "run", flatpakId] : [Config.s.signalCli]
    readonly property string runDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string socketPath: Config.s.signalSocket
        || (kind === "flatpak" ? runDir + "/app/" + flatpakId + "/island-signal.sock" : runDir + "/island-signal.sock")
    readonly property string dataDir: kind === "flatpak" ? Config.home + "/.var/app/" + flatpakId + "/data/signal-cli"
        : (Quickshell.env("XDG_DATA_HOME") || (Config.home + "/.local/share")) + "/signal-cli"

    property bool connected: sock.connected
    property string status: ""              // last thing worth telling you (errors, "Connected")
    property var convs: ({})                // key -> conversation
    property int rev: 0                     // bumps on every change, so views redraw
    readonly property var list: Object.values(convs).sort((a, b) => b.last - a.last)
    readonly property int unread: list.reduce((n, c) => n + c.unread, 0)
    property var contacts: ({})             // number/uuid -> name
    property var groups: ({})               // groupId -> name
    property var avatars: ({})              // file name -> true (signal-cli's avatar folder)

    signal incoming(string key, var msg)

    // ── is signal-cli there? ──
    function detect() { if (!probe.running) probe.running = true; }
    Process {
        id: probe
        running: true
        command: ["sh", "-c", "if command -v \"$1\" >/dev/null; then echo native; " +
                              "elif command -v flatpak >/dev/null && flatpak info \"$2\" >/dev/null 2>&1; then echo flatpak; fi",
                  "sh", Config.s.signalCli, root.flatpakId]
        stdout: StdioCollector { onStreamFinished: root.kind = text.trim() }
    }

    // ── the daemon (unless you run your own) ──
    property bool daemonWanted: on && installed && Config.s.signalDaemon && !linking
    Process {
        id: daemon
        running: root.daemonWanted
        // an older daemon left on this socket (e.g. after a Quickshell restart)
        // would lock the account, so it goes first
        command: ["sh", "-c", "sock=\"$1\"; acct=\"$2\"; shift 2; pkill -f -- \"daemon --socket $sock\" 2>/dev/null; " +
                              "mkdir -p \"$(dirname \"$sock\")\"; rm -f \"$sock\"; exec \"$@\" -a \"$acct\" daemon --socket \"$sock\"",
                  "sh", root.socketPath, Config.s.signalAccount].concat(root.cli)
        stderr: SplitParser {
            onRead: line => {
                // signal-cli is chatty; keep only what explains a failure
                if (/error|not registered|exception|failed/i.test(line) && !/WARN/.test(line))
                    root.status = line.replace(/^.*?(ERROR|Error)\s*/, "").slice(0, 160);
            }
        }
        onRunningChanged: if (running) { root.status = "Starting signal-cli…"; reconnect.restart(); }
        onExited: code => {
            sock.connected = false;
            if (root.daemonWanted) { if (!root.status || root.status.startsWith("Start")) root.status = "signal-cli stopped (" + code + "), retrying"; restart.restart(); }
        }
    }
    Timer { id: restart; interval: 15000; onTriggered: if (root.daemonWanted && !daemon.running) daemon.running = true }

    // ── the socket ──
    Socket {
        id: sock
        path: root.socketPath
        parser: SplitParser { onRead: line => root.onLine(line) }
        onConnectedChanged: {
            if (connected) {
                root.status = "Connected";
                root.call("listContacts", {}, r => root.loadContacts(r));
                root.call("listGroups", {}, r => root.loadGroups(r));
                avatarScan.running = true;
            }
        }
    }
    // the socket appears a few seconds after the daemon starts; keep knocking
    Timer {
        id: reconnect
        interval: 2000
        repeat: true
        running: root.on && !sock.connected
        onTriggered: sock.connected = true
    }

    // ── JSON-RPC ──
    property int nextId: 1
    property var pending: ({})
    function call(method, params, done) {
        if (!sock.connected) { status = "Not connected"; return false; }
        const id = nextId++;
        if (done) pending[id] = done;
        // single-account daemon (started with -a), so no "account" in params
        sock.write(JSON.stringify({ jsonrpc: "2.0", method: method, params: params, id: id }) + "\n");
        sock.flush();
        return true;
    }
    function onLine(line) {
        let m;
        try { m = JSON.parse(line); } catch (e) { return; }
        if (m.id !== undefined && m.id !== null) {
            const done = pending[m.id];
            delete pending[m.id];
            if (m.error) status = m.error.message ?? "signal-cli error";
            else if (done) done(m.result);
            return;
        }
        if (m.method === "receive") {
            const env = m.params?.envelope ?? m.params?.result?.envelope;
            if (env) handle(env);
        }
    }

    // ── names and pictures ──
    function loadContacts(r) {
        const c = {};
        for (const x of (r ?? [])) {
            const prof = x.profile ?? {};
            const name = x.name || [prof.givenName, prof.familyName].filter(Boolean).join(" ") || x.username || x.number || "";
            if (x.number) c[x.number] = name;
            if (x.uuid) c[x.uuid] = name;
        }
        contacts = c;
    }
    function loadGroups(r) {
        const g = {};
        for (const x of (r ?? [])) g[x.id] = x.name || "Group";
        groups = g;
        // groups we already have messages for get their names now
        for (const k in convs) if (convs[k].group) convs[k].name = g[convs[k].group] ?? convs[k].name;
        touch();
    }
    Process {
        id: avatarScan
        command: ["sh", "-c", "ls -1 \"$1/avatars\" 2>/dev/null", "sh", root.dataDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const a = {};
                for (const f of text.split("\n")) if (f) a[f] = true;
                root.avatars = a;
            }
        }
    }
    function avatarFor(c) {
        if (!c) return "";
        const tries = c.group ? ["group-" + c.group.replace(/\//g, "_"), "group-" + c.group]
                              : ["profile-" + c.uuid, "contact-" + c.number, "profile-" + c.number];
        for (const t of tries) if (t && !t.endsWith("-") && !t.endsWith("-undefined") && avatars[t])
            return "file://" + dataDir + "/avatars/" + t;
        return "";
    }
    function nameFor(id, fallback) { return contacts[id] || fallback || id || "Unknown"; }

    // ── conversations ──
    function conv(key, init) {
        if (!convs[key]) convs[key] = Object.assign({ key: key, name: "", group: "", number: "", uuid: "",
                                                      msgs: [], unread: 0, last: 0, typing: false }, init);
        return convs[key];
    }
    function touch() { convs = Object.assign({}, convs); rev++; }
    // a fresh copy of one chat: views bound to it see every change
    // (the stored object stays the same, so QML wouldn't notice otherwise)
    function snapshot(key) {
        void rev;
        const c = convs[key];
        return c ? Object.assign({}, c, { msgs: c.msgs.slice() }) : null;
    }
    function push(c, msg) {
        c.msgs = c.msgs.concat([msg]).slice(-200);
        c.last = Math.max(c.last, msg.ts);
    }

    function handle(env) {
        const from = env.sourceUuid || env.sourceNumber || env.source || "";
        const fromNum = env.sourceNumber || "";
        const senderName = env.sourceName || nameFor(fromNum || from, fromNum);

        // someone else typing
        if (env.typingMessage && Config.s.msgTyping) {
            const g = env.typingMessage.groupId;
            const c = convs[g ? "g:" + g : "u:" + from];
            if (c) { c.typing = env.typingMessage.action === "STARTED"; touch(); if (c.typing) typingOff.restart(); }
            return;
        }

        // a message (or reaction) for you
        const dm = env.dataMessage;
        if (dm) {
            const g = dm.groupInfo?.groupId ?? "";
            const key = g ? "g:" + g : "u:" + from;
            const c = conv(key, g ? { group: g, name: groups[g] ?? "Group" }
                                  : { number: fromNum, uuid: env.sourceUuid ?? "", name: senderName });
            if (!g && senderName) c.name = senderName;
            c.typing = false;
            if (dm.reaction) {
                const t = c.msgs.find(x => x.ts === dm.reaction.targetSentTimestamp);
                if (t) {
                    const r = Object.assign({}, t.reactions ?? {});
                    if (dm.reaction.isRemove) delete r[from]; else r[from] = dm.reaction.emoji;
                    t.reactions = r;
                    touch();
                }
                return;
            }
            const text = dm.message ?? (dm.sticker ? "Sticker" : "");
            const att = (dm.attachments ?? []).length;
            if (!text && !att) return;
            const msg = { ts: dm.timestamp ?? env.timestamp, from: from, fromName: senderName, mine: false,
                          text: text, attachments: att, reactions: {} };
            push(c, msg);
            c.unread += 1;
            touch();
            incoming(key, msg);
            return;
        }

        // synced from your phone: things you sent there, and chats you read there
        const sync = env.syncMessage;
        if (sync?.sentMessage) {
            const s = sync.sentMessage;
            const g = s.groupInfo?.groupId ?? "";
            const to = s.destinationUuid || s.destinationNumber || s.destination || "";
            const key = g ? "g:" + g : "u:" + to;
            const c = conv(key, g ? { group: g, name: groups[g] ?? "Group" }
                                  : { number: s.destinationNumber ?? "", uuid: s.destinationUuid ?? "",
                                      name: nameFor(s.destinationNumber || to, s.destinationNumber) });
            if (s.message || (s.attachments ?? []).length)
                push(c, { ts: s.timestamp, from: "me", fromName: "You", mine: true, text: s.message ?? "",
                          attachments: (s.attachments ?? []).length, reactions: {} });
            touch();
        }
        if (sync?.readMessages) {
            for (const r of sync.readMessages) {
                const who = r.senderUuid || r.senderNumber || r.sender;
                for (const k in convs) if (convs[k].msgs.some(m => m.from === who && m.ts <= r.timestamp)) convs[k].unread = 0;
            }
            touch();
        }
    }
    Timer { id: typingOff; interval: 15000; onTriggered: { for (const k in root.convs) root.convs[k].typing = false; root.touch(); } }

    // ── sending ──
    function target(c) {
        return c.group ? { groupId: c.group } : { recipient: [c.number || c.uuid] };
    }
    function send(key, text) {
        const c = convs[key];
        text = (text ?? "").trim();
        if (!c || !text) return;
        const ok = call("send", Object.assign({ message: text }, target(c)), r => {
            const ts = r?.timestamp ?? Date.now();
            push(c, { ts: ts, from: "me", fromName: "You", mine: true, text: text, attachments: 0, reactions: {} });
            touch();
        });
        if (ok) markRead(key);
    }
    function react(key, msg, emoji) {
        const c = convs[key];
        if (!c || !msg) return;
        const p = Object.assign({ emoji: emoji, targetAuthor: msg.mine ? Config.s.signalAccount : msg.from,
                                  targetTimestamp: msg.ts }, target(c));
        call("sendReaction", p, () => {
            msg.reactions = Object.assign({}, msg.reactions ?? {}, { me: emoji });
            touch();
        });
    }
    function markRead(key) {
        const c = convs[key];
        if (!c || c.unread === 0) return;
        if (Config.s.msgReceipts && !c.group) {
            const ts = c.msgs.filter(m => !m.mine).slice(-c.unread).map(m => m.ts);
            if (ts.length) call("sendReceipt", { recipient: [c.number || c.uuid], targetTimestamp: ts, type: "read" });
        }
        c.unread = 0;
        touch();
    }
    function lastFrom(key) {
        const c = convs[key];
        return c ? (c.msgs.filter(m => !m.mine).slice(-1)[0] ?? null) : null;
    }

    // ── linking this computer to your phone ──
    property bool linking: false
    property string linkQr: ""              // file:// path of the QR picture
    property string linkError: ""
    readonly property string qrFile: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/island-signal-link.png"
    Process {
        id: linker
        command: ["sh", "-c", "exec \"$@\" link -n \"Island\" 2>&1", "sh"].concat(root.cli)
        stdout: SplitParser {
            onRead: line => {
                const uri = line.match(/(sgnl:\/\/linkdevice\S+|tsdevice:\S+)/);
                if (uri) { qr.command = ["qrencode", "-s", "8", "-m", "2", "-o", root.qrFile, uri[1]]; qr.running = true; return; }
                const num = line.match(/Associated with:\s*(\+\d+)/i);
                if (num) { Config.s.signalAccount = num[1]; Config.s.signalOn = true; }
                else if (/error|exception|failed/i.test(line)) root.linkError = line.slice(0, 160);
            }
        }
        onExited: code => {
            root.linking = false;
            root.linkQr = "";
            if (code !== 0 && !root.linkError) root.linkError = "Linking stopped (" + code + ")";
        }
    }
    Process {
        id: qr
        onExited: code => {
            if (code === 0) root.linkQr = "file://" + root.qrFile + "?" + Date.now();
            else root.linkError = "Couldn't draw the QR code: install qrencode (media-gfx/qrencode)";
        }
    }
    function startLink() {
        if (linker.running) return;
        linkError = "";
        linkQr = "";
        linking = true;
        linker.running = true;
    }
    function cancelLink() { linker.signal(15); linking = false; linkQr = ""; }
    function unlink() {
        // forget the account here; your phone still lists the device until you remove it there
        Config.s.signalOn = false;
        Config.s.signalAccount = "";
        convs = ({});
    }
}
