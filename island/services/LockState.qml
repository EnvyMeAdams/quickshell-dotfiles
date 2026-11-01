pragma Singleton
import QtQuick
import Quickshell

// Lock + screensaver state. The lock itself lives in lock/ and is loaded
// separately; if it can't load (missing module), locking falls back to
// the command in Settings so you are never locked out with no way back.
Singleton {
    id: root

    property bool sessionReady: false   // set by the lock loader
    property bool idleReady: false
    property string lockError: ""       // why the built-in lock didn't load
    property string idleError: ""
    property bool locked: false
    property bool saver: false          // screensaver is showing
    property bool saverOnLock: false    // lock started while saver was up
    signal unlocked()

    function lock() {
        if (locked) return;
        Island.close();
        if (Config.s.builtinLock && sessionReady) {
            saverOnLock = saver;
            saver = false;
            locked = true;
        } else {
            saver = false;
            Quickshell.execDetached(["sh", "-c", fallbackCmd()]);
        }
    }

    // the Fallback Lock setting, or the first lock screen that's installed
    function fallbackCmd() {
        const c = (Config.s.lockCmd ?? "").trim();
        if (c && c !== "loginctl lock-session" && c !== "swaylock") return c;
        return "if command -v hyprlock >/dev/null; then exec hyprlock; " +
               "elif command -v swaylock >/dev/null; then exec swaylock -f; " +
               "else notify-send 'Lock' 'No lock screen available. See Settings → About.'; fi";
    }

    function finishUnlock() {
        locked = false;
        saverOnLock = false;
        unlocked();
    }

    function startSaver() {
        if (locked || saver) return;
        Island.close();
        saver = true;
    }
    function stopSaver() { saver = false; }
}
