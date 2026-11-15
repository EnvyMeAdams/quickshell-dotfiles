import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.services

// The real lock. Uses its own tiny PAM files:
//   lock/pam/password.conf     pam_unix only, so it checks your normal login password
//   lock/pam/fingerprint.conf  pam_fprintd, runs alongside while you haven't typed
// Whichever succeeds first unlocks. Typing stops the fingerprint check.
Scope {
    id: root

    property string password: ""
    property string status: ""          // "" | checking | wrong | error
    property bool leaving: false        // unlock animation running
    property bool showSaver: false      // lock began during the screensaver

    // ── fingerprint ──
    // off       not in use (no reader, turned off, or not started yet)
    // listening waiting for a finger
    // idle      stopped (timed out, too many tries, or you typed); move the
    //           mouse or tap the fingerprint icon to listen again
    // matched   recognised, unlocking
    property string fp: "off"
    property string fpHint: ""          // the sensor's last message ("Swipe was too short…")
    property bool fpTooMany: false      // ran out of tries: only the icon restarts it
    property bool fpTyped: false        // you typed this lock: the mouse no longer brings it back
    signal fpMiss()                     // a swipe that didn't match: the widget shakes

    readonly property bool fpWanted: Config.s.lockFingerprint && Fingerprint.available
                                     && LockState.locked && !showSaver && !leaving
    // the widget shows while listening (or just matched) and nothing is typed
    readonly property bool fpShown: (fp === "listening" || fp === "matched") && password === ""

    property int fpRetries: 0           // quick re-opens after the sensor's USB hiccup
    property double fpStarted: 0

    function submit() {
        if (pam.active || password === "") return;
        stopFp("idle");
        status = "checking";
        pam.start();
    }
    function wakeFromSaver() { showSaver = false; }

    function startFp() {
        if (!fpWanted || fpPam.active || password !== "") return;
        fpHint = "";
        fpTooMany = false;
        fp = "listening";
        fpStarted = Date.now();
        fpPam.start();
        fpWindow.restart();
    }
    function stopFp(next) {
        fpWindow.stop();
        fpRetry.stop();
        // state first: an abort may report "completed" right away, and that
        // must not look like a failed swipe
        if (fp !== "matched") fp = next;
        if (fpPam.active) fpPam.abort();
    }
    // mouse moved / key pressed on an idle lock: listen again (not after too many tries)
    function fpWake() {
        if (fp === "idle" && !fpTooMany && !fpTyped && password === "") startFp();
    }

    // typing switches to the password
    onPasswordChanged: if (password !== "") {
        fpTyped = true;
        if (fp === "listening") stopFp("idle");
    }
    onFpWantedChanged: {
        if (fpWanted) fpStart.restart();
        else stopFp("off");
    }

    Connections {
        target: LockState
        function onLockedChanged() {
            if (LockState.locked) {
                root.password = "";
                root.status = "";
                root.leaving = false;
                root.showSaver = LockState.saverOnLock;
                root.fp = "off";
                root.fpRetries = 0;
                root.fpTooMany = false;
                root.fpTyped = false;
                root.fpHint = "";
                fpStart.restart();
            } else {
                root.stopFp("off");
            }
        }
    }

    function unlockNow() {
        root.status = "";
        root.leaving = true;
        leave.restart();
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
                root.unlockNow();
            } else {
                root.status = result === PamResult.Failed ? "wrong" : "error";
                root.password = "";
            }
        }
    }

    PamContext {
        id: fpPam
        configDirectory: Qt.resolvedUrl("pam").toString().replace(/^file:\/\//, "")
        config: "fingerprint.conf"

        onPamMessage: {
            if (responseRequired) { respond(""); return; }
            // first message is the instruction ("Swipe your right index finger…"),
            // the widget has its own; keep only the useful ones
            if (messageIsError) {
                root.fpHint = message;
                if (/match/i.test(message)) root.fpMiss();
            }
        }
        onCompleted: result => {
            if (result === PamResult.Success) {
                fpWindow.stop();
                root.fp = "matched";
                root.fpHint = "";
                root.unlockNow();
                return;
            }
            if (root.fp !== "listening") return;       // we stopped it ourselves
            // some sensors (VFS5011) fail to open right after their last use;
            // a quick failure gets a quiet second try
            if (Date.now() - root.fpStarted < 2500 && root.fpRetries < 2) {
                root.fpRetries++;
                fpRetry.restart();
                return;
            }
            root.fpRetries = 0;
            if (result === PamResult.MaxTries) {
                root.fpTooMany = true;
                root.fpHint = "Too many tries";
            }
            fpWindow.stop();
            root.fp = "idle";
        }
    }
    Timer { id: fpStart; interval: 350; onTriggered: root.startFp() }
    Timer {
        id: fpRetry
        interval: 1500
        onTriggered: {
            if (!root.fpWanted || root.password !== "" || fpPam.active || root.fp !== "listening") return;
            root.fpHint = "";
            root.fpStarted = Date.now();
            fpPam.start();
        }
    }
    // stop listening after a while; the mouse or a tap on the icon starts it again
    Timer {
        id: fpWindow
        interval: Math.max(10, Config.s.fpListen) * 1000
        onTriggered: { root.fpHint = ""; root.stopFp("idle"); }
    }

    // let the unlock animation play before the lock lets go
    Timer {
        id: leave
        interval: Config.s.lockAnim ? 420 : 0
        onTriggered: {
            root.password = "";
            root.stopFp("off");
            root.fp = "off";
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
