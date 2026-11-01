import QtQuick
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    Row {
        id: header
        anchors.left: parent.left
        anchors.top: parent.top
        spacing: 10
        PText { text: "Alerts"; font.bold: true; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
        Chip { text: Notifs.count; fill: Theme.pastels.rose; anchors.verticalCenter: parent.verticalCenter }
    }
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 8
        PButton {
            icon: Config.s.dnd ? "notifications_off" : "notifications_active"
            text: "Focus"
            checked: Config.s.dnd
            tint: Theme.pastels.lilac
            onClicked: Config.s.dnd = !Config.s.dnd
        }
        PButton {
            icon: "clear_all"
            text: "Clear All"
            visible: Notifs.count > 0
            onClicked: Notifs.clearAll()
        }
    }

    Column {
        anchors.centerIn: parent
        visible: Notifs.count === 0
        spacing: 8
        PIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "notifications_paused"; size: 40; color: Theme.sub }
        PText { anchors.horizontalCenter: parent.horizontalCenter; text: "All Clear"; color: Theme.sub }
    }

    PScroll {
        anchors.top: header.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 10

        Repeater {
            model: Notifs.list
            delegate: NotifCard {
                required property var modelData
                n: modelData
                width: parent ? parent.width : 0
            }
        }
    }
}
