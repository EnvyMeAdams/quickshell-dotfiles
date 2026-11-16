import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.components
import qs.media

// One lock screen per display. Layers, bottom to top:
//   bg (photo/video, z 0)  →  bloom (z 5)  →  ui (z 10)  →  saver catcher (z 20)
// Displays not picked in Settings → Lock & Saver → Lock Displays stay black
// with just the password field, so typing still works wherever the mouse is.
Item {
    id: root

    property var session: null
    property string screenName: ""

    readonly property string userName: Config.s.userName || Quickshell.env("USER") || ""
    readonly property string avatarPath: Config.s.avatar ? Config.expand(Config.s.avatar) : Config.home + "/.face"
    readonly property bool saverPhase: session?.showSaver ?? false
    readonly property bool primary: Wallpaper.onDisplay(Config.s.lockDisplays, screenName)
    readonly property bool saverHere: Wallpaper.onDisplay(Config.s.saverDisplays, screenName)
    readonly property var desk: Wallpaper.current(screenName)
    readonly property Item glass: Config.s.lockGlass ? bg : null
    readonly property bool fpShown: session?.fpShown ?? false

    // lock background: chosen lock photo/video, else this display's desktop photo
    readonly property string bgPath: Config.s.lockBg || (desk?.kind === "photo" ? desk.path : "")
    readonly property string bgKind: Config.s.lockBg ? Config.s.lockBgKind : "photo"

    focus: true

    Rectangle { anchors.fill: parent; color: "black"; z: -1 }

    // ── background ──
    Item {
        id: bg
        anchors.fill: parent
        z: 0

        Backdrop {
            anchors.fill: parent
            visible: root.primary && !root.saverPhase
            path: root.bgPath
            kind: root.bgKind
            screenName: root.screenName
            playing: visible                     // never runs under the screensaver
        }
        // the screensaver carries on until a click or key
        Backdrop {
            anchors.fill: parent
            visible: root.saverPhase && root.saverHere
            path: Config.s.saverVideo
            kind: "video"
            screenName: root.screenName
            playing: visible
        }
    }
    Rectangle {
        anchors.fill: parent
        z: 1
        color: Theme.glass ? "black" : Theme.shade
        opacity: root.saverPhase || !root.primary ? 0 : 0.12
    }

    // ── entry animation: pastel bloom from the middle ──
    Rectangle {
        id: bloom
        z: 5
        anchors.centerIn: parent
        width: Math.hypot(root.width, root.height)
        height: width
        radius: width / 2
        color: Theme.accent
        scale: 0
        opacity: 0
    }
    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: bloom; property: "scale"; from: 0; to: 1.05; duration: 520; easing.type: Easing.OutCubic }
        SequentialAnimation {
            NumberAnimation { target: bloom; property: "opacity"; from: 0; to: 0.8; duration: 160 }
            NumberAnimation { target: bloom; property: "opacity"; to: 0; duration: 420; easing.type: Easing.InQuad }
        }
        NumberAnimation { target: ui; property: "scale"; from: 0.92; to: 1; duration: 520; easing.type: Easing.OutBack }
        NumberAnimation { target: ui; property: "opacity"; from: 0; to: 1; duration: 380 }
        onFinished: ui.opacity = 1
    }
    function playEnter() {
        if (Config.s.lockAnim && root.primary) enterAnim.restart();
        else { ui.opacity = 1; ui.scale = 1; }
        pw.forceActiveFocus();
    }
    Component.onCompleted: if (!saverPhase) playEnter()
    onSaverPhaseChanged: if (!saverPhase) playEnter()
    Connections {
        target: LockState
        function onLockedChanged() { if (LockState.locked && !root.saverPhase) root.playEnter(); }
    }
    // safety net: the UI must never stay invisible
    Timer {
        interval: 1200
        running: !root.saverPhase && !(root.session?.leaving ?? false)
        onTriggered: if (ui.opacity < 1) { ui.opacity = 1; ui.scale = 1; }
    }

    // ── lock UI ──
    Item {
        id: ui
        anchors.fill: parent
        z: 10
        visible: !root.saverPhase
        opacity: 0
        // unlock: grow slightly and fade, then the lock lets go
        states: State {
            when: root.session?.leaving ?? false
            PropertyChanges { target: ui; opacity: 0; scale: 1.06 }
        }
        transitions: Transition {
            NumberAnimation { properties: "opacity,scale"; duration: Config.s.lockAnim ? 380 : 0; easing.type: Easing.InCubic }
        }

        // clock
        Card {
            id: clock
            visible: root.primary
            glassSource: root.glass
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.12
            width: clockRow.implicitWidth + 64 + offset
            height: 150 + offset
            radius: 28

            Column {
                anchors.centerIn: parent
                spacing: 2
                Row {
                    id: clockRow
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    PText { text: Clock.hm; font.pixelSize: 80; font.bold: true }
                    Chip {
                        visible: Clock.ampm !== ""
                        text: Clock.ampm
                        fill: Theme.pastels.lilac
                        size: 26; fontSize: 13
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 18
                    }
                }
                PText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Clock.weekday + ", " + Clock.dateLong
                    font.pixelSize: 14
                }
            }
        }

        // user + password
        Column {
            id: login
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: root.primary ? 60 : 0
            spacing: 14

            Avatar {
                visible: root.primary
                anchors.horizontalCenter: parent.horizontalCenter
                width: 104; height: 104
                source: "file://" + root.avatarPath
                letter: root.userName
                fill: Theme.pastels.blue
            }
            Chip {
                visible: root.primary
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.userName
                fill: Theme.card
                size: 30; fontSize: 14
            }

            // password field and fingerprint widget share this spot and crossfade
            Item {
                id: authBox
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.max(pwCard.width, fpCard.width)
                height: root.fpShown ? fpCard.height : pwCard.height
                Behavior on height { NumberAnimation { duration: Theme.dur(240); easing.type: Easing.OutCubic } }

                Card {
                    id: pwCard
                    anchors.centerIn: parent
                    opacity: root.fpShown ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(180) } }
                    glassSource: root.session?.status === "wrong" && !Theme.glass ? null : root.glass
                    width: 320 + offset
                    height: 52 + offset
                    radius: 26
                    fill: root.session?.status === "wrong" ? Theme.pastels.pink : Theme.card
                    transform: Translate { id: shakeX }

                    // hidden input does the typing; dots are drawn separately
                    TextInput {
                        id: pw
                        anchors.fill: parent
                        opacity: 0
                        focus: !root.saverPhase
                        echoMode: TextInput.Password
                        text: root.session?.password ?? ""
                        onTextChanged: if (root.session && root.session.password !== text) {
                            root.session.password = text;
                            if (root.session.status === "wrong") root.session.status = "";
                        }
                        onAccepted: root.session?.submit()
                    }

                    // lock icon; a fingerprint button while the reader is resting
                    PIcon {
                        id: lockIcon
                        readonly property bool fpButton: root.session?.fp === "idle" && Config.s.lockFingerprint && Fingerprint.available
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        name: root.session?.status === "checking" ? "hourglass_top" : fpButton ? "fingerprint" : "lock"
                        color: root.session?.status === "wrong" ? Theme.onPastel : Theme.ink
                        scale: fpTap.containsMouse ? 1.15 : 1
                        Behavior on scale { NumberAnimation { duration: Theme.dur(120) } }
                        MouseArea {
                            id: fpTap
                            anchors.fill: parent
                            anchors.margins: -8
                            enabled: lockIcon.fpButton
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                root.session.password = "";
                                root.session.status = "";
                                root.session.startFp();
                            }
                        }
                    }

                    Item {
                        id: dotsBox
                        anchors.left: lockIcon.right
                        anchors.leftMargin: 12
                        anchors.right: go.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        height: 14
                        clip: true
                        readonly property int fit: Math.max(1, Math.floor(width / 16))

                        PText {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: pw.text.length === 0
                            text: root.session?.status === "wrong" ? "Try Again"
                                : root.session?.status === "error" ? "Error, Try Again" : "Password"
                            color: root.session?.status === "wrong" ? Theme.onPastel : Theme.ink
                            opacity: 0.7
                        }
                        Row {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            Repeater {
                                model: Math.min(pw.text.length, dotsBox.fit)
                                Rectangle {
                                    required property int index
                                    width: 10; height: 10; radius: 5
                                    color: Theme.strong(Theme.cycle[index % Theme.cycle.length])
                                    border.width: Theme.glass ? 0 : 1.5
                                    border.color: Theme.line
                                    scale: 0
                                    Component.onCompleted: scale = 1
                                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                                }
                            }
                        }
                    }

                    PButton {
                        id: go
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        icon: "arrow_forward"
                        faceHeight: 34
                        offset: 3
                        pad: 6
                        checked: pw.text.length > 0
                        onClicked: root.session?.submit()
                    }

                    SequentialAnimation {
                        id: shake
                        NumberAnimation { target: shakeX; property: "x"; to: -12; duration: 50 }
                        NumberAnimation { target: shakeX; property: "x"; to: 10; duration: 60 }
                        NumberAnimation { target: shakeX; property: "x"; to: -6; duration: 60 }
                        NumberAnimation { target: shakeX; property: "x"; to: 0; duration: 70 }
                    }
                    Connections {
                        target: root.session
                        function onStatusChanged() { if (root.session.status === "wrong") shake.restart(); }
                    }
                }
                // fingerprint widget: listening, hints, shake on a miss, check on a match
                Card {
                    id: fpCard
                    anchors.centerIn: parent
                    glassSource: fpCard.missed && !Theme.glass ? null : root.glass
                    width: 300 + offset
                    // grows with its text, so a two-line hint never sits on the edge
                    height: 22 + 84 + 14 + fpText.implicitHeight + 32 + offset
                    Behavior on height { NumberAnimation { duration: Theme.dur(200); easing.type: Easing.OutCubic } }
                    // a missed swipe flashes the ring and scan line a deeper rose
                    readonly property color missInk: Theme.glass ? Theme.strong(Theme.pastels.pink) : Qt.darker(Theme.pastels.pink, 1.45)
                    radius: 32
                    fill: fpCard.matched ? Theme.pastels.mint : fpCard.missed ? Theme.pastels.pink : Theme.card
                    readonly property bool matched: root.session?.fp === "matched"
                    property bool missed: false
                    opacity: root.fpShown ? 1 : 0
                    scale: root.fpShown ? 1 : 0.86
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Theme.dur(200) } }
                    Behavior on scale { NumberAnimation { duration: Theme.dur(320); easing.type: Easing.OutBack } }
                    transform: Translate { id: fpShakeX }

                    Item {
                        id: sensor
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 22
                        width: 84; height: 84

                        // soft ring breathing out while it listens
                        Rectangle {
                            id: pulse
                            anchors.centerIn: parent
                            width: parent.width; height: width; radius: width / 2
                            color: "transparent"
                            border.width: 2
                            border.color: fpCard.matched ? Theme.onPastel : fpCard.missed ? fpCard.missInk : Theme.strong(Theme.accent)
                            opacity: 0
                            SequentialAnimation on scale {
                                running: root.fpShown && !fpCard.matched && fpCard.visible
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.9; to: 1.35; duration: 1400; easing.type: Easing.OutCubic }
                                PauseAnimation { duration: 200 }
                            }
                            SequentialAnimation on opacity {
                                running: root.fpShown && !fpCard.matched && fpCard.visible
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.8; to: 0; duration: 1400; easing.type: Easing.OutCubic }
                                PauseAnimation { duration: 200 }
                            }
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: fpCard.matched ? Qt.rgba(1, 1, 1, 0.5) : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
                            border.width: Theme.outline
                            border.color: Theme.line
                            Behavior on color { ColorAnimation { duration: Theme.dur(200) } }
                        }
                        PIcon {
                            id: fpIcon
                            anchors.centerIn: parent
                            name: fpCard.matched ? "check" : "fingerprint"
                            size: 52
                            color: fpCard.matched || fpCard.missed ? Theme.onPastel : Theme.ink
                            scale: fpCard.matched ? 1.12 : 1
                            Behavior on scale { NumberAnimation { duration: Theme.dur(260); easing.type: Easing.OutBack } }
                        }
                        // scan line sweeping over the print, the way a swipe reads it
                        Item {
                            anchors.fill: parent
                            clip: true
                            visible: root.fpShown && !fpCard.matched
                            Rectangle {
                                id: scanLine
                                x: 14; width: parent.width - 28; height: fpCard.missed ? 4 : 3; radius: height / 2
                                color: fpCard.missed ? fpCard.missInk : Theme.strong(Theme.accent)
                                Behavior on color { ColorAnimation { duration: Theme.dur(120) } }
                                opacity: 0.9
                                SequentialAnimation on y {
                                    running: root.fpShown && !fpCard.matched && fpCard.visible
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
                            color: fpCard.matched || fpCard.missed ? Theme.onPastel : Theme.ink
                            text: fpCard.matched ? "Unlocking"
                                : Fingerprint.swipe ? "Swipe Your Finger" : "Touch the Sensor"
                        }
                        PText {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: 12
                            opacity: 0.75
                            color: fpCard.matched || fpCard.missed ? Theme.onPastel : Theme.ink
                            wrapMode: Text.Wrap
                            elide: Text.ElideNone
                            maximumLineCount: 2
                            text: fpCard.matched ? "" : (root.session?.fpHint || "or start typing your password")
                        }
                    }

                    SequentialAnimation {
                        id: fpShake
                        ScriptAction { script: fpCard.missed = true }
                        NumberAnimation { target: fpShakeX; property: "x"; to: -12; duration: 50 }
                        NumberAnimation { target: fpShakeX; property: "x"; to: 10; duration: 60 }
                        NumberAnimation { target: fpShakeX; property: "x"; to: -6; duration: 60 }
                        NumberAnimation { target: fpShakeX; property: "x"; to: 0; duration: 70 }
                        PauseAnimation { duration: 500 }
                        ScriptAction { script: fpCard.missed = false }
                    }
                    Connections {
                        target: root.session
                        function onFpMiss() { fpShake.restart(); }
                    }
                }
            }

            // while the fingerprint reader rests: why, and how to bring it back
            PText {
                id: fpRestHint
                readonly property string reason: root.session?.fpRest ?? ""
                readonly property bool show: root.session?.fp === "idle" && Config.s.lockFingerprint
                                             && Fingerprint.available && (root.session?.password ?? "") === ""
                                             && root.session?.status !== "checking" && reason !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                width: pwCard.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 12
                text: reason === "busy" ? "Reader didn't start · tap the fingerprint to try again"
                    : reason === "tries" ? "Too many tries · tap the fingerprint or type your password"
                    : reason === "typed" ? "Tap the fingerprint to use it instead"
                    : "Move the mouse to use your fingerprint"
                // fades after Settings > Fingerprint > Hint For (0 = stays); the mouse brings it back
                property bool fresh: true
                function poke() {
                    fresh = true;
                    if (Config.s.fpHintFor > 0) hintFade.restart();
                }
                onShowChanged: if (show) poke()
                onReasonChanged: if (show) poke()
                Timer { id: hintFade; interval: Math.max(1, Config.s.fpHintFor) * 1000; onTriggered: fpRestHint.fresh = false }
                opacity: show && (fresh || Config.s.fpHintFor === 0) ? 0.8 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: Theme.dur(fpRestHint.fresh ? 220 : 600) } }
            }
        }

        // now playing
        Card {
            visible: root.primary && Config.s.lockMedia && Media.active
            glassSource: root.glass
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: power.top
            anchors.bottomMargin: 20
            width: 420 + offset
            height: 84 + offset
            radius: 22

            ClippingRectangle {
                id: art
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 56; height: 56; radius: 14
                color: Theme.accent
                Image { anchors.fill: parent; source: Media.player?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(128, 128); asynchronous: true }
            }
            Column {
                anchors.left: art.right
                anchors.leftMargin: 12
                anchors.right: ctl.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                PText { width: parent.width; text: Media.player?.trackTitle ?? ""; font.bold: true }
                PText { width: parent.width; text: Media.player?.trackArtist ?? ""; font.pixelSize: 12; opacity: 0.75 }
            }
            Row {
                id: ctl
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                PButton { icon: Media.canPrev ? "skip_previous" : "replay_10"; faceHeight: 30; offset: 3; pad: 4; onClicked: Media.prev() }
                PButton { icon: Media.playing ? "pause" : "play_arrow"; faceHeight: 30; offset: 3; pad: 8; checked: true; tint: Theme.pastels.pink; onClicked: Media.toggle() }
                PButton { icon: Media.canNext ? "skip_next" : "forward_10"; faceHeight: 30; offset: 3; pad: 4; onClicked: Media.next() }
            }
        }

        // power
        Row {
            id: power
            visible: root.primary
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            spacing: 10
            PButton { icon: "dark_mode"; text: "Sleep"; onClicked: Quickshell.execDetached(["sh", "-c", Config.s.sleepCmd]) }
            PButton { icon: "restart_alt"; text: "Reboot"; onClicked: Quickshell.execDetached(["sh", "-c", Config.s.rebootCmd]) }
            PButton { icon: "power_settings_new"; text: "Power"; onClicked: Quickshell.execDetached(["sh", "-c", Config.s.poweroffCmd]) }
        }
    }

    // clicks on empty space focus the password box; moving the mouse wakes
    // a resting fingerprint reader (not after too many tries)
    MouseArea {
        anchors.fill: parent
        z: 2
        hoverEnabled: !root.saverPhase
        onClicked: { pw.forceActiveFocus(); root.session?.fpWake(); }
        onPositionChanged: { root.session?.fpWake(); if (fpRestHint.show) fpRestHint.poke(); }
    }

    // any click or key ends the screensaver part
    MouseArea {
        anchors.fill: parent
        visible: root.saverPhase
        z: 20
        onPressed: root.session?.wakeFromSaver()
    }
    Keys.onPressed: e => {
        if (root.saverPhase) { root.session?.wakeFromSaver(); e.accepted = true; }
    }
}
