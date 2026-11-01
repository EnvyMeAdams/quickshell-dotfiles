pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Bluetooth through bluetoothctl, so it works on any Quickshell build.
// The tile only appears when a controller exists (laptop, not desktop).
Singleton {
    id: root

    property bool available: false
    property bool enabled: false

    Process {
        id: probe
        command: ["sh", "-c", "command -v bluetoothctl >/dev/null || exit 1; bluetoothctl show 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.available = /Controller\s/.test(text);
                root.enabled = /Powered:\s*yes/.test(text);
            }
        }
        onExited: code => { if (code !== 0) root.available = false; }
    }
    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: probe.running = true
    }

    function setEnabled(on) {
        enabled = on;
        Quickshell.execDetached(["bluetoothctl", "power", on ? "on" : "off"]);
        recheck.restart();
    }
    Timer { id: recheck; interval: 1500; onTriggered: probe.running = true }
}
