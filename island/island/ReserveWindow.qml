import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme

// Invisible, click-through strip that keeps windows below the pill.
// Pushes windows down below the pill. Only the display the island is on
// gets the gap (Settings → Pill → Gap Everywhere puts it on all displays),
// so the compositor resizes the windows there as the island moves.
PanelWindow {
    id: win
    required property ShellScreen modelData
    screen: modelData

    readonly property bool active: modelData.name === Compositor.focused

    anchors { top: true; left: true; right: true }
    implicitHeight: 1
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: (Config.s.reserveAll || active)
        ? Config.s.topGap + Theme.sizes.idle.height + Theme.shadow + Config.s.windowGap : 0
    WlrLayershell.namespace: "island-reserve"
    WlrLayershell.layer: WlrLayer.Bottom
    mask: Region {}
}
