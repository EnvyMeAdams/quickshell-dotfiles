pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Only shows up on machines with a backlight (laptop). Needs brightnessctl.
Singleton {
    id: root

    property bool available: false
    property real value: 0

    Process {
        running: true
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",");
                if (p.length >= 5) { root.available = true; root.value = (parseInt(p[3]) || 0) / 100; }
            }
        }
    }

    function set(v) {
        value = Math.max(0.01, Math.min(1, v));
        Quickshell.execDetached(["brightnessctl", "-c", "backlight", "set", Math.round(value * 100) + "%"]);
    }
}
