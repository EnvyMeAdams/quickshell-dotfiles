pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Is there a fingerprint reader with a finger enrolled for you? (fprintd)
// Machines without a reader, or without fprintd, get `available = false`
// and the lock screen never shows anything fingerprint-related.
// Checked at start and whenever the screen locks (enrolling a finger later
// is picked up without restarting Quickshell).
Singleton {
    id: root

    property bool installed: false      // fprintd is installed
    property bool reader: false         // a reader was found
    property int fingers: 0             // fingers enrolled for you
    property string device: ""          // e.g. "Validity VFS5011"
    property bool swipe: false          // swipe sensor (vs. touch)
    readonly property bool available: reader && fingers > 0

    function refresh() { if (!check.running) check.running = true; }

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
                } else if (/No devices available/i.test(t)) {
                    root.reader = false; root.fingers = 0;
                } else if (/has no fingers enrolled/i.test(t)) {
                    root.reader = true; root.fingers = 0;
                }
                // anything else (fprintd hiccup): keep what we knew
            }
        }
    }

    Component.onCompleted: refresh()
    Connections {
        target: LockState
        function onLockedChanged() { if (LockState.locked) root.refresh(); }
    }
}
