pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen recording through scripts/record.sh (wf-recorder).
// Mic and desktop audio are separate options; with both on they are mixed.
Singleton {
    id: root

    property bool recording: false
    property bool busy: false
    property int seconds: 0
    property string lastFile: ""
    property string error: ""
    readonly property string script: Qt.resolvedUrl("../scripts/record.sh").toString().replace(/^file:\/\//, "")

    readonly property string elapsed: {
        const m = Math.floor(seconds / 60), s = seconds % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function toggle(mode) { recording ? stop() : start(mode); }

    function start(mode) {
        if (recording || busy) return;
        busy = true;
        error = "";
        Island.close();
        const m = mode || Config.s.recordMode;
        const out = Compositor.focused;
        starter.command = ["sh", root.script, "start",
            Config.s.recordMic ? "1" : "0", Config.s.recordDesktop ? "1" : "0",
            m, Config.expand(Config.s.recordDir), m === "screen" ? out : "", String(Config.s.recordFps)];
        // a short delay so the closing island isn't in the first frame
        delay.restart();
    }
    Timer { id: delay; interval: 300; onTriggered: starter.running = true }

    Process {
        id: starter
        stderr: StdioCollector { id: startErr }
        onExited: code => {
            root.busy = false;
            if (code === 0) { root.recording = true; root.seconds = 0; }
            else if (code !== 1) {   // 1 = region picking cancelled
                root.error = startErr.text.trim() || "Recording failed";
                Quickshell.execDetached(["notify-send", "Recording", root.error]);
            }
        }
    }

    function stop() {
        if (!recording) return;
        busy = true;
        stopper.running = true;
    }
    Process {
        id: stopper
        command: ["sh", root.script, "stop"]
        stdout: StdioCollector { id: stopOut }
        onExited: {
            root.busy = false;
            root.recording = false;
            root.lastFile = stopOut.text.trim();
            if (root.lastFile)
                Quickshell.execDetached(["notify-send", "Recording Saved", root.lastFile.replace(Config.home, "~")]);
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.recording
        onTriggered: root.seconds++
    }

    // pick up a recording that was still running after a reload
    Process {
        running: true
        command: ["sh", root.script, "status"]
        onExited: code => { if (code === 0) root.recording = true; }
    }

    function openFolder() { Quickshell.execDetached(["xdg-open", Config.expand(Config.s.recordDir)]); }
}
