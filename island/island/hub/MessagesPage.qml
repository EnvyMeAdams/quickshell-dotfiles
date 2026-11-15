import QtQuick
import qs.services
import qs.theme
import qs.components
import qs.island.settings

// Hub › Messages: Signal chats on the left, the open chat on the right.
// Fluxer alerts get their own switch at the top when there are any.
Item {
    id: root

    readonly property var c: Messages.open ? (Signal.convs[Messages.open] ?? null) : null
    property bool helpOpen: false
    property real picked: -1                 // timestamp of the bubble showing reactions

    // ── left: source switch + chat list ──
    Item {
        id: left
        visible: !root.helpOpen
        width: 270
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        Row {
            id: sources
            spacing: 8
            PButton {
                text: "Signal"
                icon: "chat"
                faceHeight: 30
                offset: 3
                checked: Messages.source === "signal"
                tint: Theme.pastels.mint
                onClicked: Messages.source = "signal"
            }
            PButton {
                visible: Config.s.fluxerStyle && Notifs.fluxerCount > 0
                text: "Fluxer " + Notifs.fluxerCount
                icon: "forum"
                faceHeight: 30
                offset: 3
                checked: Messages.source === "fluxer"
                tint: Theme.pastels.lavender
                onClicked: Messages.source = "fluxer"
            }
        }

        // Signal not ready: one card that says why, with the steps behind a button
        Card {
            id: stCard
            visible: Messages.source === "signal" && !Signal.connected
            anchors.top: sources.bottom
            anchors.topMargin: 12
            width: parent.width
            height: stCol.implicitHeight + 28 + offset
            fill: Theme.sunk
            Column {
                id: stCol
                x: 14; y: 14
                width: parent.width - 28
                spacing: 8
                PText {
                    width: parent.width
                    font.bold: true
                    text: !Signal.installed ? "signal-cli isn't installed"
                        : !Signal.enabled ? "Signal isn't linked yet" : "Connecting…"
                }
                PText {
                    width: parent.width
                    visible: text !== ""
                    text: Signal.enabled ? Signal.status : ""
                    wrapMode: Text.Wrap
                    font.pixelSize: 11
                    color: Theme.sub
                }
                PButton {
                    text: "Set Up"
                    icon: "help"
                    faceHeight: 28
                    checked: true
                    tint: Theme.pastels.yellow
                    onClicked: root.helpOpen = true
                }
            }
        }

        PScroll {
            visible: Messages.source === "signal" && Signal.connected
            anchors.top: sources.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 8

            PText {
                visible: Signal.list.length === 0
                width: parent.width
                wrapMode: Text.Wrap
                text: "New messages show up here. (Older chats stay on your phone.)"
                color: Theme.sub
                font.pixelSize: 12
            }
            Repeater {
                model: Signal.list
                delegate: Card {
                    id: chatRow
                    required property var modelData
                    readonly property bool on: Messages.open === modelData.key
                    readonly property var lastMsg: modelData.msgs[modelData.msgs.length - 1] ?? null
                    width: parent ? parent.width : 0
                    height: 58 + offset
                    fill: on ? Theme.pastels.mint : (area.containsMouse ? Theme.hover : Theme.card)

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Messages.openChat(chatRow.modelData.key, true)
                    }
                    Avatar {
                        id: cav
                        x: 10
                        anchors.verticalCenter: parent.verticalCenter
                        width: 38; height: 38
                        source: Signal.avatarFor(chatRow.modelData)
                        letter: chatRow.modelData.name
                        fill: chatRow.modelData.group ? Theme.pastels.sky : Theme.pastels.mint
                    }
                    Column {
                        anchors.left: cav.right
                        anchors.leftMargin: 10
                        anchors.right: badge.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        PText { width: parent.width; text: chatRow.modelData.name; font.bold: chatRow.modelData.unread > 0 || chatRow.on; color: chatRow.on ? Theme.onPastel : Theme.ink }
                        PText {
                            width: parent.width
                            visible: !chatRow.modelData.typing
                            text: chatRow.lastMsg ? (chatRow.lastMsg.mine ? "You: " : "") + Messages.preview(chatRow.lastMsg) : ""
                            font.pixelSize: 11
                            color: chatRow.on ? Theme.onPastel : Theme.sub
                        }
                        TypingDots { visible: chatRow.modelData.typing; height: 14 }
                    }
                    Chip {
                        id: badge
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        visible: chatRow.modelData.unread > 0
                        text: chatRow.modelData.unread
                        size: 20
                        fontSize: 10
                        fill: "#3a76f0"
                    }
                }
            }
        }

        // Fluxer: its alerts, newest first; the buttons are the app's own actions
        PScroll {
            visible: Messages.source === "fluxer"
            anchors.top: sources.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 8
            Repeater {
                model: Messages.source === "fluxer" ? Notifs.fluxerList : []
                delegate: NotifCard {
                    required property var modelData
                    width: parent ? parent.width : 0
                    n: modelData
                }
            }
        }
    }

    // ── right: the open chat ──
    Card {
        id: thread
        visible: !root.helpOpen && Messages.source === "signal"
        anchors.left: left.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        fill: Theme.sunk
        offset: 0

        PText {
            anchors.centerIn: parent
            visible: !root.c
            text: Signal.connected ? "Pick a Chat" : ""
            color: Theme.sub
        }

        Item {
            anchors.fill: parent
            anchors.margins: 12
            visible: !!root.c

            Row {
                id: th
                spacing: 10
                Avatar {
                    width: 34; height: 34
                    source: Signal.avatarFor(root.c)
                    letter: root.c?.name ?? "?"
                    fill: root.c?.group ? Theme.pastels.sky : Theme.pastels.mint
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    PText { text: root.c?.name ?? ""; font.bold: true; font.pixelSize: 14 }
                    PText { visible: !!root.c?.typing; text: "typing…"; font.pixelSize: 11; color: Theme.sub }
                }
            }

            ListView {
                id: bubbles
                anchors.top: th.bottom
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: composer.top
                anchors.bottomMargin: 10
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                model: root.c?.msgs ?? []
                onCountChanged: Qt.callLater(positionViewAtEnd)
                Component.onCompleted: positionViewAtEnd()

                delegate: Item {
                    id: b
                    required property var modelData
                    readonly property bool mine: modelData.mine
                    readonly property bool showPick: root.picked === modelData.ts
                    readonly property var reacts: Object.values(modelData.reactions ?? {})
                    width: bubbles.width
                    height: bub.height + (reacts.length ? 14 : 0) + (showPick ? 36 : 0) + (root.c?.group && !mine ? 14 : 0)

                    PText {
                        id: who
                        visible: !!root.c?.group && !b.mine
                        text: b.modelData.fromName
                        font.pixelSize: 10
                        color: Theme.sub
                        x: 4
                    }
                    Rectangle {
                        id: bub
                        y: who.visible ? 14 : 0
                        width: Math.min(bubbles.width * 0.72, txt.implicitWidth + 24)
                        height: txt.implicitHeight + 16
                        x: b.mine ? bubbles.width - width - 4 : 4
                        radius: 14
                        color: b.mine ? "#3a76f0" : Theme.card
                        border.width: b.mine ? 0 : Math.max(1, Theme.outline - 0.5)
                        border.color: Theme.line
                        PText {
                            id: txt
                            x: 12; y: 8
                            width: Math.min(bubbles.width * 0.72 - 24, implicitWidth)
                            text: (b.modelData.text || "") + (b.modelData.attachments ? (b.modelData.text ? "\n" : "") + "📎 " + b.modelData.attachments : "")
                            wrapMode: Text.Wrap
                            elide: Text.ElideNone
                            font.pixelSize: 12
                            color: b.mine ? "white" : Theme.ink
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.picked = b.showPick ? -1 : b.modelData.ts
                        }
                    }
                    // reactions under the bubble
                    Text {
                        visible: b.reacts.length > 0
                        anchors.top: bub.bottom
                        anchors.topMargin: -4
                        x: b.mine ? bub.x + bub.width - width - 6 : bub.x + 6
                        text: b.reacts.join("")
                        font.pixelSize: 13
                    }
                    // click a bubble: pick a reaction
                    Row {
                        visible: b.showPick
                        anchors.top: bub.bottom
                        anchors.topMargin: b.reacts.length ? 14 : 4
                        x: b.mine ? bub.x + bub.width - width : bub.x
                        spacing: 4
                        Repeater {
                            model: (Config.s.msgReactions || "").split(/\s+/).filter(Boolean)
                            delegate: PButton {
                                required property string modelData
                                text: modelData
                                faceHeight: 26
                                offset: 2
                                pad: 5
                                onClicked: { Signal.react(root.c.key, b.modelData, modelData); root.picked = -1; }
                            }
                        }
                    }
                }
            }

            Row {
                id: composer
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 8
                PField {
                    id: field
                    width: parent.width - sendBtn.width - 8
                    height: 36
                    placeholder: "Message " + (root.c?.name ?? "")
                    onAccepted: { Signal.send(Messages.open, text); text = ""; }
                }
                PButton {
                    id: sendBtn
                    icon: "send"
                    faceHeight: 34
                    checked: field.text.trim() !== ""
                    tint: "#8fb3f7"
                    onClicked: { Signal.send(Messages.open, field.text); field.text = ""; }
                }
            }
            Connections {
                target: Messages
                function onOpenChanged() { field.text = ""; root.picked = -1; }
                function onFocusReplyChanged() { if (Messages.focusReply) { field.input.forceActiveFocus(); Messages.focusReply = false; } }
            }
            Component.onCompleted: if (Messages.focusReply) { field.input.forceActiveFocus(); Messages.focusReply = false; }
        }
    }

    // ── setup steps, in their own panel ──
    Item {
        anchors.fill: parent
        visible: root.helpOpen
        Row {
            id: hh
            spacing: 10
            PButton { icon: "arrow_back"; onClicked: root.helpOpen = false }
            PText { text: "Set Up Signal"; font.bold: true; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
        }
        PScroll {
            anchors.top: hh.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            SignalSetup { width: parent.width }
        }
    }

    // mark read while you're looking at it
    Connections {
        target: Signal
        function onIncoming(key) { if (key === Messages.open) Signal.markRead(key); }
    }
}
