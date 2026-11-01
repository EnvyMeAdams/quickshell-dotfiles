import QtQuick
import qs.services
import qs.theme
import qs.components

// Uniform control tile. Fixed height, text elides — nothing sticks out.
Card {
    id: root

    property string icon: ""
    property string title: ""
    property string sub: ""
    property bool active: false
    property color tint: Theme.accent
    property bool chevron: false
    signal clicked()

    height: 64 + offset
    fill: active ? tint : (area.containsMouse ? Theme.hover : Theme.card)
    pressed: area.pressed && Config.s.pressEffect

    Rectangle {
        id: bubble
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 36; height: 36; radius: 18
        color: root.active ? Theme.card : Theme.sunk
        border.width: Theme.outline
        border.color: Theme.line
        PIcon { anchors.centerIn: parent; name: root.icon; size: 19 }
    }

    Column {
        anchors.left: bubble.right
        anchors.leftMargin: 10
        anchors.right: chev.visible ? chev.left : parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        PText {
            width: parent.width
            text: root.title
            font.bold: true
            color: root.active ? Theme.onPastel : Theme.ink
        }
        PText {
            width: parent.width
            text: root.sub
            visible: text !== ""
            font.pixelSize: 11
            color: root.active ? Theme.onPastel : Theme.sub
            opacity: root.active ? 0.75 : 1
        }
    }

    PIcon {
        id: chev
        visible: root.chevron
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        name: "chevron_right"
        color: root.active ? Theme.onPastel : Theme.ink
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
