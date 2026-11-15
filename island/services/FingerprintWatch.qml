pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Watches fprintd on the system bus, so the island can show a fingerprint
// popup whenever something asks for your finger: doas, app permission prompts
// (polkit), fprintd-verify. The lock screen has its own widget, so nothing
// shows while locked. Only runs on machines with a reader.
//
// fprintd broadcasts what it's doing:
//   VerifyFingerSelected ('right-index-finger',)   a check started
//   VerifyStatus ('verify-swipe-too-short', false)  a hint, still going
//   VerifyStatus ('verify-no-match', true)          a miss, this round is over
//   VerifyStatus ('verify-match', true)             recognised
Singleton {
    id: root

    // idle | listening | miss | matched
    property string state: "idle"
    property string hint: ""
    signal missed()

    readonly property bool wanted: Config.s.fpPopup && Fingerprint.reader
    readonly property bool shown: state !== "idle" && !LockState.locked

    // are doas / app prompts set up for fingerprint? (Settings shows it)
    property bool pamDoas: false
    property bool pamPolkit: false
    function checkPam() { if (!pamCheck.running) pamCheck.running = true; }

    readonly property var hints: ({
        "verify-swipe-too-short": "Swipe was too short, try again",
        "verify-finger-not-centered": "Finger not centred, try again",
        "verify-remove-and-retry": "Lift your finger and try again",
        "verify-retry-scan": "Try again"
    })

    function parse(line) {
        if (line.indexOf("VerifyFingerSelected") >= 0) {
            hideLater.stop();
            hint = "";
            state = "listening";
            safety.restart();
            return;
        }
        const m = line.match(/VerifyStatus \('([\w-]+)', (true|false)\)/);
        if (!m) return;
        const result = m[1], done = m[2] === "true";
        safety.restart();
        if (result === "verify-match") {
            state = "matched";
            hint = "";
            hideLater.interval = 900;
            hideLater.restart();
        } else if (result === "verify-no-match") {
            state = "miss";
            hint = "No match";
            missed();
            // another round usually follows (2 tries); hide if it doesn't
            hideLater.interval = 3500;
            hideLater.restart();
        } else if (root.hints[result]) {
            hint = root.hints[result];
            if (state === "idle") state = "listening";
        } else if (done) {
            // disconnected / unknown error: this check is over
            hideLater.interval = 1200;
            hideLater.restart();
        }
    }

    Timer { id: hideLater; onTriggered: { root.state = "idle"; root.hint = ""; } }
    // never leave it up if fprintd goes quiet (timeouts don't announce anything)
    Timer { id: safety; interval: 14000; onTriggered: { root.state = "idle"; root.hint = ""; } }

    Process {
        id: monitor
        running: root.wanted
        command: ["sh", "-c", "command -v gdbus >/dev/null || exit 3; exec gdbus monitor --system --dest net.reactivated.Fprint"]
        stdout: SplitParser { onRead: line => root.parse(line) }
        onExited: code => { if (root.wanted && code !== 3) restart.restart(); }
    }
    Timer { id: restart; interval: 3000; onTriggered: if (root.wanted) monitor.running = true }

    Process {
        id: pamCheck
        command: ["sh", "-c", "h=/usr/local/libexec/island-fingerprint-auth; " +
                              "grep -qF \"$h\" /etc/pam.d/doas 2>/dev/null && echo doas; " +
                              "grep -qF \"$h\" /etc/pam.d/polkit-1 2>/dev/null && echo polkit; true"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.pamDoas = text.indexOf("doas") >= 0;
                root.pamPolkit = text.indexOf("polkit") >= 0;
            }
        }
    }
    Component.onCompleted: checkPam()
}
