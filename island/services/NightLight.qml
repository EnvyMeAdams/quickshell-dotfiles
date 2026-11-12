pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Night light on/off and warmth. Every change goes through one queue: a new
// change waits for the previous one to finish, and only the latest warmth is
// applied, so dragging the slider can't leave an old (cooler) value behind.
Singleton {
    id: root

    readonly property bool on: Config.s.nightLight
    readonly property int temp: Config.s.nightTemp || 3500
    // 0 = barely warm (6000 K) … 1 = very red (1500 K)
    readonly property real warmth: (6000 - temp) / 4500

    // your own commands from Settings → Commands win, if set
    readonly property bool custom: !!((Config.s.nightOnCmd ?? "").trim() || (Config.s.nightOffCmd ?? "").trim())

    function toggle() { setOn(!on); }
    function setOn(v) { Config.s.nightLight = v; queue(); }
    function setWarmth(w) { setTemp(6000 - Math.max(0, Math.min(1, w)) * 4500); }
    function setTemp(k) {
        Config.s.nightTemp = Math.round(Math.max(1500, Math.min(6000, k)) / 100) * 100;
        if (on) batch.restart();
    }

    // while dragging, apply at most ~6 times a second
    Timer { id: batch; interval: 160; onTriggered: root.queue() }

    property bool pending: false
    function queue() {
        if (worker.running) { pending = true; return; }
        pending = false;
        if (custom) {
            // a custom command may keep running (like "hyprsunset -t 4500"), so
            // start it in the background; otherwise the queue would wait forever
            worker.command = ["sh", "-c", "setsid sh -c \"$1\" >/dev/null 2>&1 & sleep 0.3", "sh", Compositor.nightCmd(on)];
        } else {
            worker.command = ["sh", Compositor.scripts + "/night.sh", on ? "on" : "off", String(temp), Compositor.kind];
        }
        worker.running = true;
    }
    Process {
        id: worker
        onRunningChanged: if (running) watchdog.restart(); else watchdog.stop()
        onExited: if (root.pending) root.queue()
    }
    // never let one stuck change block every later one
    Timer { id: watchdog; interval: 4000; onTriggered: if (worker.running) worker.signal(15) }

    // put it back after a restart/login if it was on
    Timer { interval: 2000; running: true; onTriggered: if (root.on) root.queue() }
}
