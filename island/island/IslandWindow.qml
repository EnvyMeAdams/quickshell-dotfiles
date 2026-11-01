import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme

// One full-screen transparent layer per display. While idle, only the pill
// takes clicks; while something is open, the whole screen does, and a click
// outside the pill closes it. (No focus grab: those could close the island
// the instant it opened from a keybind.)
PanelWindow {
    id: win

    required property ShellScreen modelData
    screen: modelData

    // the island lives only on the display you're using
    readonly property bool focusedScreen: modelData.name === Compositor.focused
    visible: focusedScreen
    readonly property bool open: focusedScreen && Island.mode !== "idle"

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    WlrLayershell.namespace: "island"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: !win.open ? WlrKeyboardFocus.None
        : Island.mode === "launcher" ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.OnDemand

    mask: Region { item: win.open ? catcher : pill }

    Shortcut {
        sequences: ["Escape"]
        enabled: win.open
        onActivated: Island.close()
    }

    MouseArea {
        id: catcher
        anchors.fill: parent
        enabled: win.open
        acceptedButtons: Qt.AllButtons
        onPressed: Island.close()
    }

    // little drop-in when the island moves to this display
    onFocusedScreenChanged: if (focusedScreen && Config.s.springy) arrive.restart()
    ParallelAnimation {
        id: arrive
        NumberAnimation { target: pill; property: "scale"; from: 0.6; to: 1; duration: Theme.dur(320); easing.type: Easing.OutBack }
        NumberAnimation { target: pill; property: "opacity"; from: 0; to: 1; duration: Theme.dur(200) }
    }

    Pill {
        id: pill
        transformOrigin: Item.Top
        screenName: win.modelData.name
        focusedScreen: win.focusedScreen
        anchors.horizontalCenter: parent.horizontalCenter
        y: Config.s.topGap
    }
}
