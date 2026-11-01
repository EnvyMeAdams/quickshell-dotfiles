import QtQuick
import qs.theme
import qs.components

// Row that opens another panel (category, instructions, etc.)
Card {
    id: root

    property string icon: ""
    property string label: ""
    property string hint: ""
    property color tint: Theme.accent
    signal clicked()

    width: parent ? parent.width : 300
    height: 52 + offset
    fill: area.containsMouse ? Theme.hover : Theme.card

    Rectangle {
        id: bubble
        visible: root.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 30; height: 30; radius: 9
        color: root.tint
        border.width: Theme.outline
        border.color: Theme.line
        PIcon { anchors.centerIn: parent; name: root.icon; size: 17; color: Theme.onPastel }
    }
    Column {
        anchors.left: bubble.visible ? bubble.right : parent.left
        anchors.leftMargin: bubble.visible ? 12 : 16
        anchors.right: chev.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        PText { width: parent.width; text: root.label; font.bold: true }
        PText { width: parent.width; text: root.hint; visible: text !== ""; color: Theme.sub; font.pixelSize: 11 }
    }
    PIcon {
        id: chev
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        name: "chevron_right"
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
