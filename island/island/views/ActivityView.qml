import QtQuick
import qs.services
import qs.theme
import qs.components

// Live activity in the pill: one bubble, a title and a line under it.
Item {
    id: root

    readonly property var a: Island.activity
    // services pass a pastel name ("aqua"), so they don't need the theme
    readonly property color tint: Theme.pastels[a.tint] ?? a.tint ?? Theme.accent

    Rectangle {
        id: bubble
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 38; height: 38; radius: 19
        color: root.tint
        border.width: Theme.outline
        border.color: Theme.line
        scale: 0.6
        Component.onCompleted: pop.start()
        NumberAnimation on scale { id: pop; running: false; to: 1; duration: Theme.dur(320); easing.type: Easing.OutBack }
        PIcon { anchors.centerIn: parent; visible: !root.a.emoji && !art.visible; name: root.a.icon ?? ""; size: 20; color: Theme.onPastel }
        // album art (song change), always a circle
        Avatar {
            id: art
            anchors.fill: parent
            visible: !!root.a.image
            source: root.a.image ?? ""
            letter: root.a.title ?? ""
            fill: root.tint
        }
        Text { anchors.centerIn: parent; visible: !!root.a.emoji; text: root.a.emoji ?? ""; font.pixelSize: 19 }
    }
    Column {
        anchors.left: bubble.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        PText { width: parent.width; text: root.a.title ?? ""; font.bold: true; font.pixelSize: 13 }
        PText { width: parent.width; text: root.a.sub ?? ""; visible: text !== ""; font.pixelSize: 11; color: Theme.sub }
    }
}
