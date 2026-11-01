import QtQuick
import Quickshell
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    readonly property int gap: 12
    readonly property string userName: Config.s.userName || Quickshell.env("USER") || "you"
    readonly property string avatarPath: Config.s.avatar ? Config.expand(Config.s.avatar) : Config.home + "/.face"

    // ── profile ──
    Card {
        id: profile
        x: 0; y: 0
        width: 180
        height: 214

        Column {
            anchors.centerIn: parent
            spacing: 8
            Avatar {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 84; height: 84
                source: "file://" + root.avatarPath
                letter: root.userName
                fill: Theme.pastels.blue
            }
            PText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.userName
                font.bold: true
                font.pixelSize: 15
            }
            PText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Clock.greeting
                color: Theme.sub
                font.pixelSize: 11
            }
            Chip {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Network.kind === "none" ? "● Offline" : "● Online"
                fill: Network.kind === "none" ? Theme.pastels.pink : Theme.pastels.green
                fontSize: 10
            }
        }
    }

    // ── clock ──
    Card {
        id: clockCard
        x: profile.width + root.gap
        y: 0
        width: 330
        height: 101

        Row {
            anchors.centerIn: parent
            spacing: 16
            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter
                PText { text: Clock.hm; font.pixelSize: 38; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                Chip {
                    visible: Clock.ampm !== ""
                    text: Clock.ampm
                    fill: Theme.pastels.lilac
                    size: 18; fontSize: 10
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                }
            }
            Rectangle { width: 2; height: 46; color: Theme.line; opacity: 0.25; anchors.verticalCenter: parent.verticalCenter }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                PText { text: Clock.weekday.toUpperCase(); font.bold: true; font.pixelSize: 12 }
                PText { text: Clock.dateLong; color: Theme.sub; font.pixelSize: 11 }
            }
        }
    }

    // ── quick toggles ──
    Card {
        x: clockCard.x
        y: clockCard.height + root.gap
        width: clockCard.width
        height: profile.height - clockCard.height - root.gap

        PText {
            id: qtTitle
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 12
            text: "Quick"
            color: Theme.sub
            font.pixelSize: 11
        }
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: qtTitle.bottom
            anchors.topMargin: 10
            spacing: 8
            PButton {
                icon: Config.s.dnd ? "notifications_off" : "notifications"
                text: "Focus"
                checked: Config.s.dnd
                tint: Theme.pastels.lilac
                onClicked: Config.s.dnd = !Config.s.dnd
            }
            PButton {
                icon: Audio.micMuted ? "mic_off" : "mic"
                text: "Mic"
                checked: !Audio.micMuted
                tint: Theme.pastels.green
                onClicked: Audio.toggleMic()
            }
            PButton {
                icon: "bedtime"
                text: "Night"
                checked: Config.s.nightLight
                tint: Theme.pastels.yellow
                onClicked: ControlActions.toggleNight()
            }
        }
    }

    // ── calendar ──
    CalendarCard {
        x: clockCard.x + clockCard.width + root.gap
        y: 0
        width: root.width - x
        height: profile.height
    }

    // ── media ──
    MediaCard {
        x: 0
        y: profile.height + root.gap
        width: root.width
        height: root.height - y
    }
}
