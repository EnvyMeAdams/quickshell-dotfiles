import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.services

// Frosted wallpaper for the glass looks: this display's wallpaper, blurred
// once and lined up with the screen, so the glass looks like it's frosting
// what's behind it. Card loads it when `frost` is on (Settings → Appearance).
// Videos use their cached still (the same one the wallpaper accent uses).
//
// `origin` is where this item's window sits on screen (a full-screen window
// is 0,0). Its spot on screen is re-read only around size and visibility
// changes, so nothing runs while the island sits still.
ClippingRectangle {
    id: f

    property string screenName: ""
    property point origin: Qt.point(0, 0)
    color: "transparent"

    readonly property var scr: Quickshell.screens.find(s => s.name === screenName) ?? null
    readonly property var entry: Wallpaper.current(screenName)
    readonly property string src: {
        const e = f.entry;
        if (!e || !e.path) return "";
        if (e.kind === "video") return "file://" + Config.home + "/.cache/island/thumbs/" + e.path.split("/").pop() + ".jpg";
        return "file://" + e.path;
    }

    property point at: Qt.point(0, 0)
    function place() {
        const p = f.mapToItem(null, 0, 0);
        if (p.x !== f.at.x || p.y !== f.at.y) f.at = p;
    }
    // follow the pill while it springs, then stop
    FrameAnimation { running: follow.running && f.visible; onTriggered: f.place() }
    Timer { id: follow; interval: 900 }
    function kick() { f.place(); follow.restart(); }
    onWidthChanged: kick()
    onHeightChanged: kick()
    onVisibleChanged: if (visible) kick()
    Component.onCompleted: Qt.callLater(kick)

    Item {
        x: -f.at.x - f.origin.x
        y: -f.at.y - f.origin.y
        width: f.scr ? f.scr.width : 1920
        height: f.scr ? f.scr.height : 1080

        Image {
            id: img
            anchors.fill: parent
            source: f.src
            // small on purpose: it's blurred anyway, and it decodes in a blink
            sourceSize.width: 640
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: img
            visible: img.status === Image.Ready
            blurEnabled: true
            blur: Math.max(0.1, Math.min(1, Config.s.frostBlur))
            blurMax: 48
            saturation: 0.25
        }
    }
}
