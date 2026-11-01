pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Pastel accent from the wallpaper. Photos are read directly; videos use
// their thumbnail (made with ffmpegthumbnailer if it isn't cached yet).
Singleton {
    id: root

    property bool ready: false
    property color color: "#f8b984"
    property var quantizer: null
    property string error: ""

    readonly property bool wanted: Config.s.accent === "wallpaper"
    readonly property var entry: Wallpaper.current(Quickshell.screens[0]?.name ?? "*")
    readonly property string thumbDir: Config.home + "/.cache/island/thumbs"
    readonly property string sourcePath: !entry?.path ? ""
        : entry.kind === "video" ? thumbDir + "/" + entry.path.split("/").pop() + ".jpg"
        : entry.path

    function ensure() {
        if (quantizer || !wanted) return;
        const c = Qt.createComponent(Qt.resolvedUrl("../accent/Quantizer.qml"));
        if (c.status !== Component.Ready) { error = c.errorString().split("\n")[0]; return; }
        quantizer = c.createObject(root);
        quantizer.colorsChanged.connect(pick);
        refresh();
    }
    onWantedChanged: ensure()
    Component.onCompleted: ensure()
    onSourcePathChanged: refresh()

    function refresh() {
        if (!quantizer || !sourcePath) return;
        if (entry?.kind === "video") {
            thumb.command = ["sh", "-c", "[ -f \"$2\" ] || { mkdir -p \"$(dirname \"$2\")\"; ffmpegthumbnailer -i \"$1\" -o \"$2\" -s 480 -q 6; } >/dev/null 2>&1",
                             "sh", entry.path, sourcePath];
            thumb.running = true;
        } else {
            quantizer.source = "file://" + sourcePath;
        }
    }
    Process { id: thumb; onExited: if (root.quantizer) root.quantizer.source = "file://" + root.sourcePath }

    // most colourful swatch, softened into a pastel
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
