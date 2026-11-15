import QtQuick
import qs.services
import qs.theme
import qs.components

// A Signal message as a live activity: who, what, quick reactions, Reply.
// A burst from one chat stays one popup with a count.
Item {
    id: root

    readonly property var c: Messages.popConv
    readonly property var msg: c ? Signal.lastFrom(c.key) : null
    readonly property bool hidden: LockState.locked && !Config.s.msgLockPreviews

    Avatar {
        id: av
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.top: parent.top
        anchors.topMargin: 14
        width: 50; height: 50
        source: Signal.avatarFor(root.c)
        letter: root.c?.name ?? "?"
        fill: Theme.pastels.mint
        scale: 0.7
        Component.onCompleted: popIn.start()
        NumberAnimation on scale { id: popIn; running: false; to: 1; duration: Theme.dur(300); easing.type: Easing.OutBack }

        // little Signal-blue badge so it's clearly not a normal notification
        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: -3
            width: 20; height: 20; radius: 10
            color: "#3a76f0"
            border.width: 1.5
            border.color: Theme.line
            PIcon { anchors.centerIn: parent; name: "chat_bubble"; size: 11; color: "white" }
        }
    }

    Column {
        anchors.left: av.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.top: parent.top
        anchors.topMargin: 13
        spacing: 2

        Row {
            width: parent.width
            spacing: 6
            PText {
                width: Math.min(implicitWidth, parent.width - (count.visible ? count.width + 6 : 0) - when.width - 6 - 40)
                text: (root.c?.name ?? "") + (root.c?.group && root.msg ? " · " + root.msg.fromName : "")
                font.bold: true
                font.pixelSize: 14
            }
            Chip {
                id: count
                visible: Messages.popCount > 1
                text: Messages.popCount + " new"
                size: 18
                fontSize: 9
                fill: Theme.pastels.mint
                anchors.verticalCenter: parent.verticalCenter
            }
            PText {
                id: when
                text: root.msg ? Messages.when(root.msg.ts) : ""
                color: Theme.sub
                font.pixelSize: 10
                anchors.verticalCenter: parent.verticalCenter
            }
            TypingDots { visible: !!root.c?.typing; height: 14; anchors.verticalCenter: parent.verticalCenter }
        }
        PText {
            width: parent.width
            text: root.hidden ? "New Message" : Messages.preview(root.msg)
            color: Theme.sub
            font.pixelSize: 12
            wrapMode: Text.Wrap
            maximumLineCount: 1
        }
    }

    // reactions + reply, along the bottom
    Row {
        anchors.left: av.right
        anchors.leftMargin: 12
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        spacing: 6
        visible: !root.hidden
        Repeater {
            model: (Config.s.msgReactions || "").split(/\s+/).filter(Boolean).slice(0, 5)
            delegate: PButton {
                required property string modelData
                text: modelData
                faceHeight: 26
                offset: 2
                pad: 6
                checked: (root.msg?.reactions?.me ?? "") === modelData
                tint: Theme.pastels.mint
                onClicked: { Signal.react(root.c.key, root.msg, modelData); Island.hold(); releaseSoon.restart(); }
            }
        }
        PButton {
            text: "Reply"
            icon: "reply"
            iconSize: 15
            faceHeight: 26
            offset: 2
            checked: true
            tint: Theme.pastels.mint
            onClicked: Messages.openChat(root.c.key, true)
        }
    }
    Timer { id: releaseSoon; interval: 900; onTriggered: Island.release() }
}
