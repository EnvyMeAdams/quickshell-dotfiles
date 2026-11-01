import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.services
import qs.theme

// Wallpaper layer for one display. Photos change with a Grow / Fade / Wipe
// reveal; videos play muted and pause while the lock or screensaver is up.
PanelWindow {
    id: win

    required property ShellScreen modelData
    screen: modelData

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "black"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "island-wallpaper"

    readonly property var entry: Wallpaper.current(modelData.name)
    readonly property string path: entry?.path ?? ""
    readonly property string kind: entry?.kind ?? "photo"
    readonly property bool isVideo: kind === "video" && path !== "" && Wallpaper.videoOk

    // ── photo: back = current, front = incoming, revealed by t ──
    property real t: 1
    readonly property string mode: Config.s.transition

    Image {
        id: back
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(win.width, win.height)
        asynchronous: true
        cache: false
    }

    ClippingRectangle {
        id: reveal
        z: win.isVideo ? 1 : 3
        color: "transparent"
        readonly property real maxR: Math.hypot(win.width / 2, win.height)
        readonly property real r: reveal.maxR * win.t
        x: win.mode === "grow" ? win.width / 2 - r : 0
        y: win.mode === "grow" ? -r : 0
        width: win.mode === "grow" ? r * 2 : win.mode === "wipe" ? win.width * win.t : win.width
        height: win.mode === "grow" ? r * 2 : win.height
        radius: win.mode === "grow" ? r : 0
        opacity: win.mode === "fade" ? win.t : 1

        Image {
            id: front
            x: -reveal.x
            y: -reveal.y
            width: win.width
            height: win.height
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(win.width, win.height)
            asynchronous: true
            cache: false
            onStatusChanged: if (status === Image.Ready && win.pendingReveal) win.startReveal()
        }
    }

    property bool pendingReveal: false
    function startReveal() {
        pendingReveal = false;
        if (mode === "none") { t = 1; finish(); return; }
        anim.restart();
    }
    function finish() {
        back.source = front.source;
        videoBox.hideAfterPhoto();
    }
    NumberAnimation {
        id: anim
        target: win; property: "t"
        from: 0; to: 1
        duration: Theme.dur(win.mode === "fade" ? 600 : 900)
        easing.type: Easing.InOutCubic
        onFinished: win.finish()
    }

    function showPhoto() {
        const src = "file://" + path;
        if (front.source.toString() === src && back.source.toString() === src) return;
        t = 0;
        pendingReveal = true;
        front.source = src;
        if (front.status === Image.Ready) startReveal();
    }

    // ── video ──
    Item {
        id: videoBox
        anchors.fill: parent
        z: (win.isVideo || keep) ? 2 : -1
        opacity: 0
        property bool keep: false

        Loader {
            id: video
            anchors.fill: parent
            active: win.isVideo || videoBox.keep
            source: Qt.resolvedUrl("../media/VideoBg.qml")
        }
        Binding { target: video.item; property: "source"; value: "file://" + win.path; when: video.status === Loader.Ready && win.isVideo }
        Binding { target: video.item; property: "playing"; value: !LockState.locked && !LockState.saver; when: video.status === Loader.Ready }

        NumberAnimation { id: fadeIn; target: videoBox; property: "opacity"; from: 0; to: 1; duration: Theme.dur(700); easing.type: Easing.OutCubic }

        // when going video → photo, keep the video until the photo is in
        function hideAfterPhoto() { if (!win.isVideo) { keep = false; opacity = 0; } }
    }

    function refresh() {
        if (path === "") return;
        if (isVideo) { videoBox.keep = false; fadeIn.restart(); }
        else if (kind === "photo") { videoBox.keep = videoBox.opacity > 0; showPhoto(); }
    }
    onPathChanged: refresh()
    onKindChanged: refresh()
    Component.onCompleted: {
        if (kind === "photo" && path) { back.source = "file://" + path; front.source = back.source; }
        else refresh();
    }

    // videos can't play here → hand them to mpvpaper if it exists
    readonly property bool needFallback: kind === "video" && path !== "" && !Wallpaper.videoOk
    onNeedFallbackChanged: if (needFallback) Quickshell.execDetached(["sh", "-c",
        "command -v mpvpaper >/dev/null && { pkill -f \"mpvpaper.* $1 \"; mpvpaper -f -o 'no-audio loop' \"$1\" \"$2\"; }", "sh", modelData.name, path])
}
