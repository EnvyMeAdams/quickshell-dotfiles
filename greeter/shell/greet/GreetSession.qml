import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd
import qs.services

// Login state shared by every display. Same shape as the island's
// LockSession (password / status / leaving), but greetd checks the
// password and starts your session instead of unlocking one.
Scope {
    id: root

    readonly property string user: Config.s.greeterUser
    property string password: ""
    property string status: ""          // "" | checking | wrong | error
    property string message: ""         // greetd / PAM text worth showing
    property string prompt: ""          // a second PAM question (expired password, 2FA ...)
    property bool leaving: false        // login animation running
    property bool open: false           // greetd session started
    property bool answered: false       // password already sent for this attempt

    // ── sessions from /usr/share/wayland-sessions ──
    property var sessions: []           // [{ name, exec }]
    property int sessionIndex: 0
    readonly property var session: sessions[sessionIndex] ?? { name: "Hyprland", exec: "Hyprland" }

    Process {
        running: true
        command: ["sh", "-c",
            "for f in /usr/share/wayland-sessions/*.desktop; do [ -f \"$f\" ] || continue; " +
            "grep -qi '^NoDisplay=true' \"$f\" && continue; " +
            "n=$(grep -m1 '^Name=' \"$f\" | cut -d= -f2-); e=$(grep -m1 '^Exec=' \"$f\" | cut -d= -f2-); " +
            "[ -n \"$e\" ] && printf '%s\\t%s\\n' \"$n\" \"$e\"; done"]
        stdout: StdioCollector { onStreamFinished: root.readSessions(text) }
    }
    function readSessions(t) {
        const list = [];
        for (const line of t.trim().split("\n")) {
            const [name, exec] = line.split("\t");
            if (exec) list.push({ name: name || exec, exec: exec.replace(/%[a-zA-Z]/g, "").trim() });
        }
        // the compositor you normally use first, uwsm-managed variants after it
        list.sort((a, b) => score(b) - score(a));
        if (list.length > 0) sessions = list;
        pickRemembered();
    }
    function score(s) {
        const e = (s.exec + " " + s.name).toLowerCase();
        const want = Config.s.desktop || "hyprland";
        return (e.includes(want) ? 4 : 0) + (e.includes("hyprland") || e.includes("mango") ? 2 : 0)
             - (e.includes("uwsm") ? 1 : 0);
    }
    function pickRemembered() {
        const want = Config.s.greeterSession;
        if (want && !sessions.some(s => s.exec === want))
            sessions = [{ name: want.split(/\s+/).pop(), exec: want }].concat(sessions);
        const i = sessions.findIndex(s => s.exec === want);
        sessionIndex = i >= 0 ? i : 0;
    }
    Connections {
        target: Config
        function onLoadedChanged() {
            root.sessions = root.sessions.slice().sort((a, b) => root.score(b) - root.score(a));
            root.pickRemembered();
        }
    }
    function nextSession() { if (sessions.length > 1) sessionIndex = (sessionIndex + 1) % sessions.length; }

    // ── login ──
    function submit() {
        if (leaving || password === "" || user === "") return;
        status = "checking";
        message = "";
        if (prompt !== "") {                 // answering a follow-up question
            prompt = "";
            Greetd.respond(password);
            password = "";
        } else if (!open) {
            open = true;
            answered = false;
            Greetd.createSession(user);
        }
    }
    function reset(why, text) {
        status = why;
        message = text ?? "";
        prompt = "";
        password = "";
        open = false;
        answered = false;
    }

    Connections {
        target: Greetd
        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired && !root.answered) {
                root.answered = true;
                Greetd.respond(root.password);
                root.password = "";
            } else if (responseRequired) {
                root.status = "";
                root.prompt = message.trim() || "Answer";
            } else if (message.trim() !== "") {
                root.message = message.trim();
            }
        }
        function onAuthFailure(message) { root.reset("wrong"); }
        function onError(error) {
            console.warn("greeter: greetd error:", error);
            Greetd.cancelSession();
            root.reset("error", error);
        }
        function onReadyToLaunch() {
            root.status = "";
            root.leaving = true;
            launchTimer.restart();          // let the animation play: greetd wants us gone soon after
        }
    }

    Timer {
        id: launchTimer
        interval: Config.s.lockAnim ? 420 : 0
        onTriggered: {
            const cmd = root.session.exec.split(/\s+/).filter(x => x !== "");
            // greetd joins this into one shell line, so it must stay plain words:
            // session.sh adds D-Bus (without systemd) and logs to ~/.cache/island-session.log
            Greetd.launch(["/etc/greetd/island/session.sh"].concat(cmd));
        }
    }

    // ── power ──
    function power(action) { Quickshell.execDetached(["loginctl", action]); }
}
