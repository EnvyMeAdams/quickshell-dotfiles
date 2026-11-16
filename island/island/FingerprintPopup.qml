import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.components

// Fingerprint popup for doas, app permission prompts and anything else that
// asks fprintd for your finger (services/FingerprintWatch.qml), on the display
// you're on. Upper middle by default so it doesn't cover a permission window
// (Settings > Fingerprint > Popup Position). Never takes the keyboard or clicks:
// you can still type your password in the terminal or the window behind it.
PanelWindow {
    id: win

    required property ShellScreen modelData
    screen: modelData

    readonly property bool here: modelData.name === Compositor.focused
    readonly property bool want: FingerprintWatch.shown && here
    readonly property string st: FingerprintWatch.state

    // stays mapped while the card fades out
    visible: want || card.opacity > 0.01
    color: "transparent"
    implicitWidth: 340
    implicitHeight: 260
    exclusionMode: ExclusionMode.Ignore
    // no anchors = centred; anchored to the top with a margin = upper middle
    readonly property bool upper: Config.s.fpPopupPos !== "center"
    anchors.top: upper
    margins.top: upper ? Math.round((modelData.height || 1080) * 0.12) : 0
    mask: Region {}                       // clicks pass straight through
    WlrLayershell.namespace: "island-fingerprint"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Card {
        id: card
        anchors.centerIn: parent
        width: 300 + offset
        height: 22 + 84 + 14 + fpText.implicitHeight + 32 + offset
        radius: 32
        readonly property bool matched: win.st === "matched"
        readonly property bool typing: win.st === "password"
        property bool missed: false
        fill: Theme.glass ? Theme.panel : matched ? Theme.pastels.mint : missed ? Theme.pastels.pink : Theme.card
        readonly property color missInk: Theme.glass ? Theme.strong(Theme.pastels.pink) : Qt.darker(Theme.pastels.pink, 1.45)
        frost: true
        frostScreen: win.modelData.name
        frostOrigin: Qt.point(((win.modelData.width || 1920) - win.width) / 2,
                              win.upper ? win.margins.top : ((win.modelData.height || 1080) - win.height) / 2)
        opacity: win.want ? 1 : 0
        scale: win.want ? 1 : 0.86
        Behavior on opacity { NumberAnimation { duration: Theme.dur(200) } }
        Behavior on scale { NumberAnimation { duration: Theme.dur(320); easing.type: Easing.OutBack } }
        Behavior on height { NumberAnimation { duration: Theme.dur(200); easing.type: Easing.OutCubic } }
        transform: Translate { id: shakeX }

        // glass: the result washes over the dark glass instead of replacing it
        Rectangle {
            anchors.fill: parent
            visible: Theme.glass
            radius: card.radius
            color: card.matched ? Theme.pastels.mint : card.missed ? Theme.pastels.pink : "transparent"
            Behavior on color { ColorAnimation { duration: Theme.dur(200) } }
        }

        // who's asking (from the helper's note)
        Chip {
            readonly property string who: FingerprintWatch.source === "doas" ? "doas"
                                        : FingerprintWatch.source === "polkit-1" ? "App Permission" : ""
            visible: who !== "" && !card.matched
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 14
            text: who
            size: 22
            fontSize: 11
            fill: FingerprintWatch.source === "doas" ? Theme.pastels.butter : Theme.pastels.sky
        }

        Item {
            id: sensor
            anchors.horizontalCenter: parent.horizontalCenter
            y: 22
            width: 84; height: 84
            readonly property bool scanning: win.want && !card.matched && !card.typing

            Rectangle {
                anchors.centerIn: parent
                width: parent.width; height: width; radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: card.matched ? Theme.onPastel : card.missed ? card.missInk : Theme.strong(Theme.accent)
                opacity: 0
                SequentialAnimation on scale {
                    running: sensor.scanning
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.9; to: 1.35; duration: 1400; easing.type: Easing.OutCubic }
                    PauseAnimation { duration: 200 }
                }
                SequentialAnimation on opacity {
                    running: sensor.scanning
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.8; to: 0; duration: 1400; easing.type: Easing.OutCubic }
                    PauseAnimation { duration: 200 }
                }
            }
            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: card.matched ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
                border.width: Theme.outline
                border.color: Theme.line
                Behavior on color { ColorAnimation { duration: Theme.dur(200) } }
            }
            PIcon {
                anchors.centerIn: parent
                name: card.matched ? "check" : card.typing ? "keyboard" : "fingerprint"
                size: 52
                color: card.matched || card.missed ? Theme.onPastel : Theme.ink
                scale: card.matched ? 1.12 : 1
                Behavior on scale { NumberAnimation { duration: Theme.dur(260); easing.type: Easing.OutBack } }
            }
            Item {
                anchors.fill: parent
                clip: true
                visible: sensor.scanning
                Rectangle {
                    x: 14; width: parent.width - 28; height: card.missed ? 4 : 3; radius: height / 2
                    color: card.missed ? card.missInk : Theme.strong(Theme.accent)
                    Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
                    SequentialAnimation on y {
                        running: sensor.scanning
                        loops: Animation.Infinite
                        NumberAnimation { from: 14; to: 68; duration: 1100; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 68; to: 14; duration: 1100; easing.type: Easing.InOutSine }
                    }
                }
            }
        }

        Column {
            id: fpText
            anchors.top: sensor.bottom
            anchors.topMargin: 14
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 32
            spacing: 4
            PText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.bold: true
                color: card.matched || card.missed ? Theme.onPastel : Theme.ink
                text: card.matched ? "Allowed"
                    : card.typing ? "Type Your Password"
                    : Fingerprint.swipe ? "Swipe to Allow" : "Touch to Allow"
            }
            PText {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 12
                opacity: 0.75
                wrapMode: Text.Wrap
                elide: Text.ElideNone
                maximumLineCount: 2
                color: card.matched || card.missed ? Theme.onPastel : Theme.ink
                // what you can actually do right now
                text: card.matched ? ""
                    : card.typing ? (FingerprintWatch.canSkip ? "in the terminal"
                                     : FingerprintWatch.source === "polkit-1" ? "in the permission window" : "")
                    : FingerprintWatch.hint
                      || (FingerprintWatch.canSkip ? "or press any key in the terminal to type your password"
                          : FingerprintWatch.source === "polkit-1" ? "your password comes after " + Config.s.fpPamWait + " seconds"
                          : "")
            }
        }

        SequentialAnimation {
            id: shake
            ScriptAction { script: card.missed = true }
            NumberAnimation { target: shakeX; property: "x"; to: -12; duration: 50 }
            NumberAnimation { target: shakeX; property: "x"; to: 10; duration: 60 }
            NumberAnimation { target: shakeX; property: "x"; to: -6; duration: 60 }
            NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 70 }
            PauseAnimation { duration: 500 }
            ScriptAction { script: card.missed = false }
        }
        Connections {
            target: FingerprintWatch
            function onMissed() {
                if (!win.here || LockState.locked) return;
                shake.restart();
                Sounds.play("fpMiss");
            }
            function onStateChanged() {
                if (FingerprintWatch.state === "matched" && win.here && !LockState.locked) Sounds.play("fpMatch");
            }
        }
    }
}
