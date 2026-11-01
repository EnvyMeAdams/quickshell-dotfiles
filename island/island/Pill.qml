import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.components
import qs.island.views
import qs.island.hub

// The one pill. It never swaps for another window — it springs to a new
// size and crossfades its contents. Content is always laid out at the
// FINAL size and clipped, so text never reflows mid-animation.
Item {
    id: root

    property string screenName: ""
    readonly property int ws: Compositor.workspace(screenName)
    property bool focusedScreen: false

    readonly property string view: {
        if (focusedScreen && Island.mode !== "idle") return Island.mode;
        if (focusedScreen && Island.popup !== "") return Island.popup;
        if (Config.s.nowPlayingInPill && Media.active) return "nowplaying";
        return "idle";
    }
    readonly property bool clickToOpen: ["idle", "nowplaying", "workspace", "volume", "notif"].includes(view)
    readonly property bool roundPill: ["idle", "nowplaying", "workspace", "volume"].includes(view)
    readonly property size target: Theme.sizes[view]
    property string shown: view

    width: body.width
    height: body.height

    onViewChanged: swap.restart()

    SequentialAnimation {
        id: swap
        NumberAnimation { target: host; property: "opacity"; to: 0; duration: Theme.dur(70) }
        ScriptAction { script: root.shown = root.view }
        NumberAnimation { target: host; property: "opacity"; to: 1; duration: Theme.dur(180); easing.type: Easing.OutCubic }
    }

    // ── workspace jiggle ──────────────────────────────
    property bool armed: false
    Timer { running: true; interval: 2000; onTriggered: root.armed = true }

    onWsChanged: {
        if (!root.armed || !root.focusedScreen || !Config.s.workspaceFlash || ws <= 0) return;
        Island.flash("workspace", 1100);
        if (Config.s.jiggle) jiggle.restart();
    }

    // little hello after unlocking
    Connections {
        target: LockState
        function onUnlocked() { if (root.focusedScreen && Config.s.jiggle) jiggle.restart(); }
    }

    SequentialAnimation {
        id: jiggle
        NumberAnimation { target: jig; property: "x"; to: -6; duration: Theme.dur(55); easing.type: Easing.OutQuad }
        NumberAnimation { target: jig; property: "x"; to: 5; duration: Theme.dur(70); easing.type: Easing.InOutQuad }
        NumberAnimation { target: jig; property: "x"; to: -3; duration: Theme.dur(65); easing.type: Easing.InOutQuad }
        NumberAnimation { target: jig; property: "x"; to: 0; duration: Theme.dur(90); easing.type: Easing.OutBack }
    }

    // ── clicks on compact shapes (sits under the content) ──
    MouseArea {
        anchors.fill: body
        enabled: root.clickToOpen
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => {
            if (m.button === Qt.MiddleButton) { Media.player?.togglePlaying(); return; }
            if (m.button === Qt.RightButton) { Island.toggleHub("control"); return; }
            Island.toggleHub(root.view === "notif" ? "notifications"
                           : root.view === "volume" ? "sound" : "home");
        }
        onWheel: w => {
            if (!Config.s.pillScrollVolume) { w.accepted = false; return; }
            Audio.nudge(w.angleDelta.y > 0 ? 0.05 : -0.05);
        }
    }

    // hover never blocks clicks (HoverHandler is passive)
    HoverHandler {
        id: hover
        onHoveredChanged: {
            if (hovered) {
                Island.hold();
                if (Config.s.openOnHover && root.clickToOpen && root.focusedScreen) hoverOpen.restart();
                leaveClose.stop();
            } else {
                Island.release();
                hoverOpen.stop();
                if (Config.s.openOnHover && Island.mode === "hub") leaveClose.restart();
            }
        }
    }
    Timer { id: hoverOpen; interval: Config.s.hoverDelay; onTriggered: Island.toggleHub("home") }
    Timer { id: leaveClose; interval: 600; onTriggered: if (!hover.hovered) Island.close() }

    Card {
        id: body

        width: root.target.width + Theme.shadow
        height: root.target.height + Theme.shadow
        radius: root.roundPill ? root.target.height / 2 : 26
        fill: Theme.card

        Behavior on width {
            SpringAnimation {
                spring: (Config.s.springy ? 3.4 : 7) * Config.s.animSpeed
                damping: Config.s.springy ? 0.28 : 0.75
                epsilon: 0.3
            }
        }
        Behavior on height {
            SpringAnimation {
                spring: (Config.s.springy ? 3.4 : 7) * Config.s.animSpeed
                damping: Config.s.springy ? 0.30 : 0.75
                epsilon: 0.3
            }
        }
        Behavior on radius { NumberAnimation { duration: Theme.dur(220); easing.type: Easing.OutCubic } }

        transform: Translate { id: jig }

        Item {
            id: host
            anchors.fill: parent
            anchors.margins: Theme.outline
            clip: true

            Loader {
                anchors.centerIn: parent
                width: Theme.sizes[root.shown].width - Theme.outline * 2
                height: Theme.sizes[root.shown].height - Theme.outline * 2
                sourceComponent: ({
                    idle: idleC, nowplaying: nowC, workspace: wsC, volume: volC,
                    notif: notifC, launcher: launcherC, hub: hubC, windows: windowsC
                })[root.shown] ?? idleC
            }
        }
    }

    Component { id: idleC; IdleView { screenName: root.screenName } }
    Component { id: nowC; NowPlayingView {} }
    Component { id: wsC; WorkspaceView { screenName: root.screenName } }
    Component { id: volC; VolumeView {} }
    Component { id: notifC; NotifToast {} }
    Component { id: launcherC; LauncherView {} }
    Component { id: hubC; HubView {} }
    Component { id: windowsC; WindowsView {} }
}
