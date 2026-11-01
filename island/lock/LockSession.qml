import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.services

// The real lock. Uses its own tiny PAM file (lock/pam/password.conf:
// pam_unix only) so it checks your normal login password.
Scope {
    id: root

    property string password: ""
    property string status: ""          // "" | checking | wrong | error
    property bool leaving: false        // unlock animation running
    property bool showSaver: false      // lock began during the screensaver

    function submit() {
        if (pam.active || password === "") return;
        status = "checking";
        pam.start();
    }
    function wakeFromSaver() { showSaver = false; }

    Connections {
        target: LockState
        function onLockedChanged() {
            if (LockState.locked) {
                root.password = "";
                root.status = "";
                root.leaving = false;
                root.showSaver = LockState.saverOnLock;
            }
        }
    }

    PamContext {
        id: pam
        configDirectory: Qt.resolvedUrl("pam").toString().replace(/^file:\/\//, "")
        config: "password.conf"

        onPamMessage: {
            if (responseRequired) respond(root.password);
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.status = "";
                root.leaving = true;
                leave.restart();
            } else {
                root.status = result === PamResult.Failed ? "wrong" : "error";
                root.password = "";
            }
        }
    }

    // let the unlock animation play before the lock lets go
    Timer {
        id: leave
        interval: Config.s.lockAnim ? 420 : 0
        onTriggered: {
            root.password = "";
            LockState.finishUnlock();
        }
    }

    WlSessionLock {
        id: lock
        locked: LockState.locked

        WlSessionLockSurface {
            id: surface
            color: "black"
            LockSurface {
                anchors.fill: parent
                session: root
                screenName: surface.screen?.name ?? ""
            }
        }
    }
}
