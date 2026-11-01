pragma Singleton
import QtQuick
import Quickshell

// Same "Wallpaper" accent as the island: picked from the image the sync
// script saved (your desktop photo, or a frame of your video wallpaper).
Singleton {
    id: root

    property bool ready: false
    property color color: "#f8b984"
    property var quantizer: null

    readonly property bool wanted: Config.s.accent === "wallpaper"
    readonly property string sourcePath: Config.s.accentFile

    function ensure() {
        if (quantizer || !wanted) return;
        const c = Qt.createComponent(Qt.resolvedUrl("../accent/Quantizer.qml"));
        if (c.status !== Component.Ready) return;
        quantizer = c.createObject(root);
        quantizer.colorsChanged.connect(pick);
        refresh();
    }
    onWantedChanged: ensure()
    Component.onCompleted: ensure()
    onSourcePathChanged: refresh()
    function refresh() { if (quantizer && sourcePath) quantizer.source = "file://" + sourcePath; }

    function pick() {
        const cols = Array.from(quantizer?.colors ?? []);
        if (cols.length === 0) return;
        let best = cols[0], score = -1;
        for (const c of cols) {
            const s = c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.5));
            if (s > score) { score = s; best = c; }
        }
        const hue = best.hslHue < 0 ? 0.08 : best.hslHue;
        const sat = best.hslSaturation < 0.12 ? 0.25 : 0.62;
        color = Qt.hsla(hue, sat, 0.78, 1);
        ready = true;
    }
}
