pragma Singleton
import QtQuick
import Quickshell
import qs.services

// Shared actions used by Home quick toggles and the Control page.
Singleton {
    id: root

    function run(cmd) { if (cmd) Quickshell.execDetached(["sh", "-c", cmd]); }

    // 0 = barely warm (6000 K) … 1 = very red (1500 K)
    readonly property real warmth: (6000 - (Config.s.nightTemp || 3500)) / 4500
    function setWarmth(w) { setNightTemp(6000 - Math.max(0, Math.min(1, w)) * 4500); }

    // warmth slider: re-apply while night light is on (batched while dragging)
    function setNightTemp(k) {
        Config.s.nightTemp = Math.round(k / 100) * 100;
        if (Config.s.nightLight) nightApply.restart();
    }
    Timer { id: nightApply; interval: 300; onTriggered: root.run(Compositor.nightCmd(true)) }

    // put night light back after a restart/login if it was on
    Timer {
        interval: 2000
        running: true
        onTriggered: if (Config.s.nightLight) root.run(Compositor.nightCmd(true))
    }

    function toggleNight() {
        Config.s.nightLight = !Config.s.nightLight;
        run(Compositor.nightCmd(Config.s.nightLight));
    }

    // close the island first so it's not in the shot
    function screenshot() {
        Island.close();
        shot.restart();
    }
    Timer { id: shot; interval: 350; onTriggered: root.run(Compositor.screenshotCmd("region")) }

    function power(kind) {
        Island.close();
        if (kind === "lock") { LockState.lock(); return; }
        if (kind === "saver") { saverDelay.restart(); return; }
        run(({ sleep: Config.s.sleepCmd, reboot: Config.s.rebootCmd,
               poweroff: Config.s.poweroffCmd, logout: Compositor.logoutCmd() })[kind]);
    }
    // small delay so the click that started it doesn't instantly end it
    Timer { id: saverDelay; interval: 400; onTriggered: LockState.startSaver() }
}
