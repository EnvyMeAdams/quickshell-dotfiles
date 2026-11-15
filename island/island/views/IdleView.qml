import QtQuick
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    property string screenName: ""
    readonly property int ws: Compositor.workspace(screenName) || 1

    // left side: your profile picture (or the workspace number, in Settings → Pill)
    Avatar {
        anchors.left: parent.left
        anchors.leftMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        visible: !Recorder.recording && Config.s.idleLeft === "avatar"
        width: 26; height: 26
        source: Config.profilePic
        letter: Config.profileName
        fill: Theme.accent
    }
    Chip {
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        visible: !Recorder.recording && Config.s.idleLeft === "workspace"
        size: 24
        text: root.ws
        fill: Theme.accent
    }

    // recording: blinking red dot + time, click to stop
    Rectangle {
        id: rec
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        visible: Recorder.recording
        height: 24
        width: recRow.implicitWidth + 16
        radius: height / 2
        color: Theme.card
        border.width: Math.max(1, Theme.outline - 0.5)
        border.color: Theme.line

        Row {
            id: recRow
            anchors.centerIn: parent
            spacing: 6
            Rectangle {
                id: recDot
                anchors.verticalCenter: parent.verticalCenter
                width: 10; height: 10; radius: 5
                color: "#ff3b30"
                SequentialAnimation on opacity {
                    running: rec.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.15; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                }
            }
            PText {
                anchors.verticalCenter: parent.verticalCenter
                text: Recorder.elapsed
                font.pixelSize: 11
                font.bold: true
            }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Recorder.stop()
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 6
        PText {
            text: Clock.hm
            font.pixelSize: 14
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
        Chip {
            visible: Clock.ampm !== ""
            text: Clock.ampm
            size: 16
            fontSize: 9
            fill: Theme.pastels.lilac
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        PIcon {
            visible: Awake.keepAwake
            name: "coffee"
            size: 15
            anchors.verticalCenter: parent.verticalCenter
        }
        PrivacyDot { on: Privacy.mic; dotColor: Theme.mic }
        PrivacyDot { on: Privacy.camera; dotColor: Theme.camera }

        // unread chats (Signal + Fluxer)
        Row {
            visible: Messages.unread > 0
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            PIcon { name: "chat_bubble"; size: 15; color: "#3a76f0"; anchors.verticalCenter: parent.verticalCenter }
            PText { text: Messages.unread; font.bold: true; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
        }
        // on an exit node (e.g. Mullvad): a tiny flag, if you want it
        Text {
            visible: Config.s.tsPillFlag && Tailscale.up && !!Tailscale.exitNode
            text: Tailscale.exitNode ? (Tailscale.flag(Tailscale.exitNode.code) || "🛡") : ""
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }
        PIcon {
            name: Config.s.dnd ? "notifications_off" : "notifications"
            size: 16
            anchors.verticalCenter: parent.verticalCenter
        }
        PText {
            visible: Notifs.count > 0
            text: Notifs.count
            font.bold: true
            font.pixelSize: 11
            anchors.verticalCenter: parent.verticalCenter
        }
        PillBattery { anchors.verticalCenter: parent.verticalCenter }
    }
}
