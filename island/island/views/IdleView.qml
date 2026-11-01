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

    // recording: red chip with the time, click to stop
    Chip {
        id: rec
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        visible: Recorder.recording
        size: 24
        text: "● " + Recorder.elapsed
        fill: Theme.pastels.coral
        SequentialAnimation on opacity {
            running: rec.visible
            loops: Animation.Infinite
            NumberAnimation { to: 0.6; duration: 800 }
            NumberAnimation { to: 1; duration: 800 }
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
    }
}
