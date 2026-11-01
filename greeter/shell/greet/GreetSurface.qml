import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.components
import qs.media

// The island lock screen, as a login screen. Layers, bottom to top:
//   bg (photo/video, z 0)  →  bloom (z 5)  →  ui (z 10)
// Displays not picked in Lock Displays stay black with just the password
// field, exactly like the lock.
Item {
    id: root

    property var session: null
    property string screenName: ""

    readonly property string userName: Config.s.userName || session?.user || ""
    readonly property string avatarPath: Config.s.avatar
    readonly property bool primary: Wallpaper.onDisplay(Config.s.lockDisplays, screenName)
    readonly property Item glass: Config.s.lockGlass ? bg : null
    readonly property bool leaving: session?.leaving ?? false
    readonly property string status: session?.status ?? ""

    // lock background: chosen lock photo/video, else this display's desktop photo
    readonly property var deskPhotos: Config.s.desktopPhotos ?? {}
    readonly property string bgPath: Config.s.lockBg || deskPhotos[screenName] || deskPhotos["*"] || ""
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
            visible: root.primary
            path: root.bgPath
            kind: root.bgKind
            screenName: root.screenName
            playing: visible
        }
    }
    Rectangle {
        anchors.fill: parent
        z: 1
        color: Theme.shade
        opacity: root.primary ? 0.12 : 0
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
    // wait for settings so the first frame already has your colours
    property bool entered: false
    function enterOnce() { if (!entered && Config.loaded) { entered = true; playEnter(); } }
    Component.onCompleted: enterOnce()
    Connections { target: Config; function onLoadedChanged() { root.enterOnce(); } }
    Timer { interval: 600; running: !root.entered; onTriggered: { root.entered = true; root.playEnter(); } }
    // safety net: the UI must never stay invisible
    Timer {
        interval: 1500
        running: !root.leaving
        onTriggered: if (ui.opacity < 1) { ui.opacity = 1; ui.scale = 1; }
    }

    // ── login UI ──
    Item {
        id: ui
        anchors.fill: parent
        z: 10
        opacity: 0
        // login: grow slightly and fade, then greetd starts your session
        states: State {
            when: root.leaving
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
                source: root.avatarPath ? "file://" + root.avatarPath : ""
                letter: root.userName
                fill: Theme.pastels.blue
            }
            Chip {
                visible: root.primary
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.userName || "Run island-greeter-sync"
                fill: Theme.card
                size: 30; fontSize: 14
            }

            Card {
                id: pwCard
                anchors.horizontalCenter: parent.horizontalCenter
                glassSource: root.status === "wrong" ? null : root.glass
                width: 320 + offset
                height: 52 + offset
                radius: 26
                fill: root.status === "wrong" || root.status === "error" ? Theme.pastels.pink : Theme.card
                transform: Translate { id: shakeX }

                // hidden input does the typing; dots are drawn separately
                TextInput {
                    id: pw
                    anchors.fill: parent
                    opacity: 0
                    focus: true
                    enabled: !root.leaving
                    echoMode: TextInput.Password
                    text: root.session?.password ?? ""
                    onTextChanged: if (root.session && root.session.password !== text) {
                        root.session.password = text;
                        if (root.session.status === "wrong" || root.session.status === "error") root.session.status = "";
                    }
                    onAccepted: root.session?.submit()
                }

                PIcon {
                    id: lockIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.status === "checking" ? "hourglass_top" : root.leaving ? "lock_open" : "lock"
                    color: root.status === "wrong" || root.status === "error" ? Theme.onPastel : Theme.ink
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
                        width: parent.width
                        visible: pw.text.length === 0
                        text: root.session?.prompt ? root.session.prompt
                            : root.status === "checking" ? "Signing In…"
                            : root.status === "wrong" ? "Try Again"
                            : root.status === "error" ? "Error, Try Again" : "Password"
                        color: root.status === "wrong" || root.status === "error" ? Theme.onPastel : Theme.ink
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
                    function onStatusChanged() {
                        const s = root.session.status;
                        if (s === "wrong" || s === "error") shake.restart();
                    }
                }
            }

            // greetd / PAM messages (only when there is one)
            PText {
                visible: root.primary && (root.session?.message ?? "") !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.min(implicitWidth, 420)
                horizontalAlignment: Text.AlignHCenter
                text: root.session?.message ?? ""
                font.pixelSize: 12
                color: "white"
                style: Text.Outline
                styleColor: Theme.shade
            }
        }

        // session + power
        Row {
            id: power
            visible: root.primary
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40
            spacing: 10
            // only worth showing when there's a choice
            PButton {
                visible: (root.session?.sessions.length ?? 0) > 1
                icon: "desktop_windows"
                text: root.session?.session.name ?? ""
                onClicked: root.session.nextSession()
            }
            PButton { icon: "dark_mode"; text: "Sleep"; onClicked: root.session.power("suspend") }
            PButton { icon: "restart_alt"; text: "Reboot"; onClicked: root.session.power("reboot") }
            PButton { icon: "power_settings_new"; text: "Power"; onClicked: root.session.power("poweroff") }
        }
    }

    // clicks on empty space focus the password box
    MouseArea {
        anchors.fill: parent
        z: 2
        onClicked: pw.forceActiveFocus()
    }
}
