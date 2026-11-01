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
        color: Theme.shade
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

            Card {
                id: pwCard
                anchors.horizontalCenter: parent.horizontalCenter
                glassSource: root.session?.status === "wrong" ? null : root.glass
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

                PIcon {
                    id: lockIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.session?.status === "checking" ? "hourglass_top" : "lock"
                    color: root.session?.status === "wrong" ? Theme.onPastel : Theme.ink
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
                                color: Theme.cycle[index % Theme.cycle.length]
                                border.width: 1.5
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
                PButton { icon: "skip_previous"; faceHeight: 30; offset: 3; pad: 4; onClicked: Media.player?.previous() }
                PButton { icon: Media.playing ? "pause" : "play_arrow"; faceHeight: 30; offset: 3; pad: 8; checked: true; tint: Theme.pastels.pink; onClicked: Media.player?.togglePlaying() }
                PButton { icon: "skip_next"; faceHeight: 30; offset: 3; pad: 4; onClicked: Media.player?.next() }
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

    // clicks on empty space focus the password box
    MouseArea {
        anchors.fill: parent
        z: 2
        onClicked: pw.forceActiveFocus()
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
