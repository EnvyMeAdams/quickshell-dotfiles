pragma Singleton
import QtQuick
import Quickshell

// Decides when the screensaver and auto-lock must wait.
//   saverBlocked: anything playing, a call, fullscreen, recording, Keep Awake
//   lockBlocked:  video/fullscreen, a call, recording, Keep Awake
//                 (music alone still lets the screen lock)
Singleton {
    id: root

    property bool keepAwake: false

    // MPRIS covers browsers, mpv, Spotify, etc. (raw audio streams linger after pausing, so they're not used)
    readonly property bool media: Config.s.pauseForMedia && Media.playing
    readonly property bool call: Config.s.pauseForCalls && (Privacy.mic || Privacy.camera)
    readonly property bool full: Config.s.pauseForFullscreen && fullscreen
    readonly property bool rec: Recorder.recording

    readonly property bool saverBlocked: keepAwake || media || call || full || rec
    readonly property bool lockBlocked: keepAwake || call || full || rec

    readonly property string reason: keepAwake ? "Keep Awake" : rec ? "Recording" : call ? "Call"
        : full ? "Fullscreen" : media ? "Playing" : ""

    // a call or video starting while the saver is up ends it right away
    onSaverBlockedChanged: if (saverBlocked && LockState.saver) LockState.stopSaver()

    // a fullscreen window has focus (any compositor)
    readonly property bool fullscreen: Compositor.fullscreen
}
