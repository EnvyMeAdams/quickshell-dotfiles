pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property bool mic: Audio.micInUse
    property bool camera: false

    Process {
        id: cam
        // needs fuser (psmisc). exit 0 = some process holds a /dev/video* device
        command: ["sh", "-c", "for d in /dev/video*; do [ -e \"$d\" ] && fuser \"$d\" >/dev/null 2>&1 && exit 0; done; exit 1"]
        onExited: code => root.camera = (code === 0)
    }
    Timer {
        interval: 3000
        repeat: true
        triggeredOnStart: true
        running: Config.s.cameraIndicator
        onTriggered: cam.running = true
        onRunningChanged: if (!running) root.camera = false
    }
}
