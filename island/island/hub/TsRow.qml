import QtQuick
import qs.services
import qs.theme
import qs.components

// One row in the Tailscale panel: a device, an exit node, a country.
// Same shape everywhere so the lists read as one.
Card {
    id: row

    property var node: null
    property string icon: ""
    property string emoji: ""
    property string title: ""
    property string sub: ""
    property bool active: false
    property bool dim: false
    property bool chevron: false
    property bool open: false
    property color tint: Theme.accent
    property var buttons: []                 // [{ i: icon, t: label, act: fn }]
    signal picked()

    height: 52 + offset
    fill: active ? tint : (area.containsMouse ? Theme.hover : Theme.card)
    opacity: dim ? 0.55 : 1

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: row.picked()
    }

    Rectangle {
        id: bubble
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 30; height: 30; radius: 15
        color: row.active ? Theme.card : Theme.sunk
        border.width: Theme.outline
        border.color: Theme.line
        PIcon { anchors.centerIn: parent; visible: row.emoji === ""; name: row.icon; size: 16 }
        Text { anchors.centerIn: parent; visible: row.emoji !== ""; text: row.emoji; font.pixelSize: 16 }
        // online dot for devices
        Rectangle {
            visible: row.node !== null && row.node !== undefined && row.emoji === ""
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: -2
            width: 10; height: 10; radius: 5
            color: row.node?.online ? "#59c36a" : Theme.sub
            border.width: 1.5
            border.color: Theme.line
        }
    }
    Column {
        anchors.left: bubble.right
        anchors.leftMargin: 12
        anchors.right: tail.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        PText { width: parent.width; text: row.title; font.bold: true; color: row.active ? Theme.onPastel : Theme.ink }
        PText { width: parent.width; text: row.sub; visible: text !== ""; font.pixelSize: 11; color: row.active ? Theme.onPastel : Theme.sub }
    }
    Row {
        id: tail
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Repeater {
            model: row.buttons
            delegate: PButton {
                required property var modelData
                icon: modelData.i
                text: modelData.t
                iconSize: 14
                faceHeight: 26
                offset: 2
                pad: 8
                onClicked: modelData.act()
            }
        }
        PIcon {
            visible: row.active && !row.chevron
            name: "check"
            size: 18
            color: Theme.onPastel
            anchors.verticalCenter: parent.verticalCenter
        }
        PIcon {
            visible: row.chevron
            name: "chevron_right"
            rotation: row.open ? 90 : 0
            color: row.active ? Theme.onPastel : Theme.ink
            anchors.verticalCenter: parent.verticalCenter
            Behavior on rotation { NumberAnimation { duration: Theme.dur(160) } }
        }
    }
}
