import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.components

// iPhone-style charging card: pops up in the middle of the display you're on
// when the charger goes in (and, if you want, when it comes out). The battery
// fills up to your level with a bolt on top, then it fades away by itself.
// Never takes the keyboard or clicks. Settings > Home > Charging Popup.
PanelWindow {
    id: win

    required property ShellScreen modelData
    screen: modelData

    property bool showing: false
    property bool unplug: false          // this card is for the charger coming out

    readonly property bool limited: Battery.status === "Not charging"
    readonly property bool full: Battery.status === "Full" || Battery.percent >= 100
    readonly property bool low: win.unplug && Battery.percent <= 20
    readonly property color tint: low ? Theme.pastels.pink
                                : win.unplug ? Theme.pastels.butter
                                : limited ? Theme.pastels.sky : Theme.pastels.green

    visible: showing || card.opacity > 0.01
    color: "transparent"
    implicitWidth: 360
    implicitHeight: 320
    exclusionMode: ExclusionMode.Ignore
    readonly property bool upper: Config.s.chargePopupPos === "upper"
    anchors.top: upper
    margins.top: upper ? Math.round((modelData.height || 1080) * 0.12) : 0
    mask: Region {}                      // clicks pass straight through
    WlrLayershell.namespace: "island-charging"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    function pop(out) {
        // only on the display you're on, never over the lock screen
        if (!Config.s.chargePopup || LockState.locked) return;
        if (out && !Config.s.chargePopupUnplug) return;
        if (modelData.name !== Compositor.focused) return;
        win.unplug = out;
        win.showing = true;
        fill.level = 0;
        intro.restart();
        hide.restart();
    }
    Connections {
        target: Battery
        function onPlugged() { win.pop(false); }
        function onUnplugged() { win.pop(true); }
    }
    Connections {
        target: LockState
        function onLockedChanged() { if (LockState.locked) win.showing = false; }
    }
    Timer {
        id: hide
        interval: Math.max(1, Config.s.chargePopupTime) * 1000
        onTriggered: win.showing = false
    }

    Card {
        id: card
        anchors.centerIn: parent
        width: 260 + offset
        height: 236 + offset
        radius: 36
        fill: Theme.panel
        frost: true
        frostScreen: win.modelData.name
        // the window is centred, or anchored to the top with a margin
        frostOrigin: Qt.point(((win.modelData.width || 1920) - win.width) / 2,
                              win.upper ? win.margins.top : ((win.modelData.height || 1080) - win.height) / 2)
        opacity: win.showing ? 1 : 0
        scale: win.showing ? 1 : 0.82
        Behavior on opacity { NumberAnimation { duration: Theme.dur(220) } }
        Behavior on scale { NumberAnimation { duration: Theme.dur(380); easing.type: Easing.OutBack } }

        // soft glow ring that breathes out from the battery while charging
        Rectangle {
            id: ring
            anchors.horizontalCenter: battery.horizontalCenter
            anchors.verticalCenter: battery.verticalCenter
            width: battery.width + 24; height: battery.height + 24
            radius: height / 2
            color: "transparent"
            border.width: 2
            border.color: Theme.strong(win.tint)
            opacity: 0
            readonly property bool run: win.showing && !win.unplug && !win.limited && Config.s.chargePopupGlow
            SequentialAnimation on scale {
                running: ring.run
                loops: Animation.Infinite
                NumberAnimation { from: 0.92; to: 1.22; duration: 1500; easing.type: Easing.OutCubic }
                PauseAnimation { duration: 250 }
            }
            SequentialAnimation on opacity {
                running: ring.run
                loops: Animation.Infinite
                NumberAnimation { from: 0.9; to: 0; duration: 1500; easing.type: Easing.OutCubic }
                PauseAnimation { duration: 250 }
            }
        }

        // the battery: outline, nub and a fill that grows to your level
        Item {
            id: battery
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -4          // nub sits outside, so nudge the body
            y: 34
            width: 150; height: 72

            Rectangle {
                id: body
                anchors.fill: parent
                radius: 20
                color: Qt.rgba(Theme.ink.r, Theme.ink.g, Theme.ink.b, 0.06)
                border.width: Theme.glass ? 2 : Theme.outline + 1
                border.color: Theme.stroke

                Item {
                    id: fill
                    property real level: 0               // 0..1, animated in by `intro`
                    x: body.border.width + 4
                    y: body.border.width + 4
                    height: parent.height - 2 * y
                    width: Math.max(height * 0.5 * Math.min(1, level * 8), (parent.width - 2 * x) * level)
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        radius: body.radius - body.border.width - 4
                        color: Theme.strong(win.tint)
                        Behavior on color { ColorAnimation { duration: Theme.dur(200) } }
                    }
                    // light sweeping across the fill while it charges
                    Rectangle {
                        id: sweep
                        visible: win.showing && !win.unplug && !win.limited && !win.full && Config.s.chargePopupGlow
                        width: 34; height: parent.height
                        rotation: 12
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0; color: "#00ffffff" }
                            GradientStop { position: 0.5; color: "#88ffffff" }
                            GradientStop { position: 1; color: "#00ffffff" }
                        }
                        NumberAnimation on x {
                            running: sweep.visible
                            loops: Animation.Infinite
                            from: -40; to: fill.width + 40
                            duration: 1600
                            easing.type: Easing.InOutSine
                        }
                    }
                }
            }
            Rectangle {
                anchors.left: body.right
                anchors.leftMargin: 3
                anchors.verticalCenter: body.verticalCenter
                width: 7; height: 24; radius: 3
                color: Theme.stroke
            }
            PIcon {
                id: bolt
                anchors.centerIn: body
                name: win.unplug ? "power_off" : win.limited ? "power" : "bolt"
                size: 44
                color: Theme.onStrong
                scale: 0
                transform: Translate { id: boltY }
            }
        }

        PText {
            id: pct
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: battery.bottom
            anchors.topMargin: 18
            text: Math.round(fill.level * 100) + "%"     // counts up with the fill
            font.pixelSize: 38
            font.bold: true
        }
        PText {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: pct.bottom
            anchors.topMargin: 2
            width: parent.width - 32
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 13
            opacity: 0.75
            text: win.unplug ? (win.low ? "Low Battery" : "On Battery")
                : win.full ? "Fully Charged"
                : win.limited ? "Plugged In · Holding Charge"
                : "Charging"
        }

        // pop in, fill up to the level, then the bolt drops in with a bounce
        SequentialAnimation {
            id: intro
            PauseAnimation { duration: Theme.dur(120) }
            NumberAnimation {
                target: fill; property: "level"
                from: 0; to: Battery.percent / 100
                duration: Config.s.chargePopupFill ? Theme.dur(500 + 7 * Battery.percent) : 0
                easing.type: Easing.OutCubic
            }
            ParallelAnimation {
                NumberAnimation { target: bolt; property: "scale"; from: 0; to: 1; duration: Theme.dur(360); easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                NumberAnimation { target: boltY; property: "y"; from: -14; to: 0; duration: Theme.dur(360); easing.type: Easing.OutBack }
            }
        }
        // the percent can change while the card is up; follow it
        Connections {
            target: Battery
            function onPercentChanged() { if (!intro.running) fill.level = Battery.percent / 100; }
        }
    }
}
