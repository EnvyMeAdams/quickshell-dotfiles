pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// cava in raw ascii mode, only while music is playing and the hub is open.
Singleton {
    id: root

    property var bars: []
    readonly property bool wanted: Config.s.visualizer && Media.playing && Island.mode === "hub"

    Process {
        running: root.wanted
        command: ["sh", "-c",
            "command -v cava >/dev/null || exit 0; cfg=\"${XDG_RUNTIME_DIR:-/tmp}/island-cava.conf\"; " +
            "printf '[general]\\nbars=%s\\nframerate=30\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\ndata_format=ascii\\nascii_max_range=100\\n' \"$1\" > \"$cfg\"; " +
            "exec cava -p \"$cfg\"", "sh", String(Config.s.visualizerBars)]
        stdout: SplitParser {
            onRead: line => root.bars = line.split(";").filter(s => s !== "").map(Number)
        }
        onRunningChanged: if (!running) root.bars = []
    }
}
