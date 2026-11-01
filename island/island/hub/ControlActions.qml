pragma Singleton
import QtQuick
import Quickshell
import qs.services

// Shared actions used by Home quick toggles and the Control page.
Singleton {
    id: root

    function run(cmd) { if (cmd) Quickshell.execDetached(["sh", "-c", cmd]); }

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
               poweroff: Config.s.poweroffCmd })[kind]);
    }
    // small delay so the click that started it doesn't instantly end it
    Timer { id: saverDelay; interval: 400; onTriggered: LockState.startSaver() }
}
