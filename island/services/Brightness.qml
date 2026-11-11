pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness.
//   Laptop: the backlight in /sys/class/backlight (brightnessctl to change it).
//           Changes from your brightness keys are noticed and shown in the pill.
//   Desktop: external monitors over DDC/CI with ddcutil (optional; needs the
//           i2c-dev module and your user in the i2c group). Slow-ish, so
//           changes are batched.
Singleton {
    id: root

    property string mode: ""                 // "backlight" | "ddc" | ""
    readonly property bool available: mode !== ""
    property real value: 0                   // 0..1
    property string device: ""
    property int maxRaw: 0
    property var ddcDisplays: []             // ["1", "2"] ddcutil display numbers

    readonly property string icon: value < 0.34 ? "brightness_5" : value < 0.67 ? "brightness_6" : "brightness_7"

    // ── find what we can control ──
    Process {
        running: true
        command: ["sh", "-c", "for d in /sys/class/backlight/*; do [ -r \"$d/max_brightness\" ] && { echo \"$(basename \"$d\") $(cat \"$d/max_brightness\")\"; exit 0; }; done; exit 1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(" ");
                if (p.length === 2 && parseInt(p[1]) > 0) {
                    root.device = p[0];
                    root.maxRaw = parseInt(p[1]);
                    root.mode = "backlight";
                }
            }
        }
        onExited: code => { if (code !== 0 && Config.s.ddcBrightness) ddcDetect.running = true; }
    }

    // backlight: read the file directly (cheap) so key presses show up
    FileView {
        id: blFile
        path: root.mode === "backlight" ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        blockLoading: false
        onLoaded: {
            const raw = parseInt(text()) || 0;
            const v = root.maxRaw > 0 ? raw / root.maxRaw : 0;
            if (Math.abs(v - root.value) > 0.004) {
                const first = root.lastRaw < 0;
                root.value = v;
                if (!first && !root.selfChange) root.osd();
            }
            root.lastRaw = raw;
            root.selfChange = false;
        }
    }
    property int lastRaw: -1
    property bool selfChange: false
    Timer {
        interval: 350
        repeat: true
        running: root.mode === "backlight"
        onTriggered: blFile.reload()
    }

    // ddc: find monitors once, read the first one's brightness
    Process {
        id: ddcDetect
        command: ["sh", "-c", "command -v ddcutil >/dev/null || exit 1; ddcutil detect --brief 2>/dev/null | sed -n 's/^Display \\([0-9]*\\).*/\\1/p'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = text.split("\n").map(s => s.trim()).filter(s => s);
                if (list.length > 0) { root.ddcDisplays = list; root.mode = "ddc"; ddcRead.running = true; }
            }
        }
    }
    Process {
        id: ddcRead
        command: ["sh", "-c", "ddcutil --display " + (root.ddcDisplays[0] ?? "1") + " getvcp 10 --brief 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                // "VCP 10 C 60 100"
                const p = text.trim().split(/\s+/);
                const cur = parseInt(p[3]), max = parseInt(p[4]);
                if (max > 0) root.value = cur / max;
            }
        }
    }
    Timer {
        id: ddcWrite
        interval: 250
        onTriggered: {
            const pct = Math.round(root.value * 100);
            Quickshell.execDetached(["sh", "-c",
                root.ddcDisplays.map(d => "ddcutil --noverify --display " + d + " setvcp 10 " + pct).join(" & ") + "; wait"]);
        }
    }

    function set(v) {
        if (!available) return;
        value = Math.max(0.01, Math.min(1, v));
        if (mode === "backlight") {
            selfChange = true;
            Quickshell.execDetached(["brightnessctl", "-q", "-d", device, "set", Math.round(value * 100) + "%"]);
        } else {
            ddcWrite.restart();
        }
    }
    function nudge(d) { set(value + d); osd(); }

    function osd() {
        if (Config.s.osdBrightness && Island.mode === "idle") Island.flash("brightness", Config.s.osdTimeout);
    }
}
