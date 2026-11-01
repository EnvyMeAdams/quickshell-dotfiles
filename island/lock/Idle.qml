import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// Auto screensaver and auto lock.
// While something keeps the screen awake (see services/Awake.qml) the
// monitor is switched off; when it ends, the countdown starts over from
// zero, so the saver never pops up the moment a video or call finishes.
Scope {
    IdleMonitor {
        enabled: Config.s.saverAfter > 0 && !LockState.locked && !Awake.saverBlocked
        timeout: Config.s.saverAfter * 60
        respectInhibitors: true
        onIsIdleChanged: {
            if (isIdle) LockState.startSaver();
            else if (LockState.saver) LockState.stopSaver();   // input on any display ends it
        }
    }
    IdleMonitor {
        enabled: Config.s.lockAfter > 0 && !LockState.locked && !Awake.lockBlocked
        timeout: Config.s.lockAfter * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) LockState.lock()
    }
}
