pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Is there a fingerprint reader with a finger enrolled for you? (fprintd)
// Machines without a reader, or without fprintd, get `available = false`
// and the lock screen never shows anything fingerprint-related.
// Checked at start and after each unlock (enrolling a finger later is picked
// up without restarting Quickshell). Never while locked: the lock opening the
// sensor can make it vanish from USB for a moment (VFS5011 resets on open).
Singleton {
    id: root

    property bool installed: false      // fprintd is installed
    property bool reader: false         // a reader was found
    property int fingers: 0             // fingers enrolled for you
    property string device: ""          // e.g. "Validity VFS5011"
    property bool swipe: false          // swipe sensor (vs. touch)
    property string first: ""           // first enrolled finger, e.g. "Right Index Finger"
    // swipe sensors usually can't search a list, so fprintd checks only the first finger
    readonly property string lockUses: !available ? "" : swipe ? first : "Any finger you set up"
    readonly property bool available: reader && fingers > 0

    function refresh() { if (!check.running) check.running = true; }
    property bool doubting: false       // saw "no reader" once after having one: look again before believing it

    Process {
        id: check
        // fprintd-list only reads the saved prints; it doesn't use the sensor
        command: ["sh", "-c", "command -v fprintd-list >/dev/null || { echo NOFPRINTD; exit 0; }; " +
                              "fprintd-list \"${USER:-$(id -un)}\" 2>&1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text;
                if (t.indexOf("NOFPRINTD") >= 0) {
                    root.installed = false; root.reader = false; root.fingers = 0;
                    return;
                }
                root.installed = true;
                const head = t.match(/Fingerprints for user \S+ on (.+?) \((\w+)\)/);
                if (head) {
                    root.reader = true;
                    root.device = head[1];
                    root.swipe = head[2] === "swipe";
                    root.fingers = (t.match(/^\s*-\s*#\d+:/gm) || []).length;
                    const f = t.match(/^\s*-\s*#0:\s*(\S+)/m);
                    root.first = f ? f[1].split("-").map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ") : "";
                } else if (/No devices available/i.test(t)) {
                    if (root.reader && !root.doubting) {
                        // probably mid-reset: ask again in a few seconds
                        root.doubting = true;
                        recheck.restart();
                        return;
                    }
                    root.reader = false; root.fingers = 0;
                } else if (/has no fingers enrolled/i.test(t)) {
                    root.reader = true; root.fingers = 0;
                }
                // anything else (fprintd hiccup): keep what we knew
                root.doubting = false;
            }
        }
    }
    Timer {
        id: recheck
        interval: 5000
        onTriggered: {
            if (LockState.locked) { restart(); return; }   // wait until unlocked
            root.refresh();
        }
    }

    Component.onCompleted: refresh()
    Connections {
        target: LockState
        function onLockedChanged() { if (!LockState.locked) root.refresh(); }
    }
}
