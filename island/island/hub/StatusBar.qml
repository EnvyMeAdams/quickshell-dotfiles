import QtQuick
import qs.services
import qs.theme
import qs.components

// Home, top right: tray icons, then the battery (laptops).
Row {
    id: bar
    spacing: 8
    property real maxWidth: 260

    // tray is loaded at runtime, so a Quickshell built without SystemTray
    // just shows no tray instead of failing to start
    Loader {
        id: tray
        anchors.verticalCenter: parent.verticalCenter
        active: Config.s.showTray
        source: Qt.resolvedUrl("TrayRow.qml")
    }
    Binding {
        target: tray.item
        property: "maxWidth"
        value: bar.maxWidth - (battery.visible ? battery.width + bar.spacing : 0)
        when: tray.status === Loader.Ready
    }

    Card {
        id: battery
        visible: Battery.shown
        anchors.verticalCenter: parent.verticalCenter
        width: batRow.implicitWidth + 18 + offset
        height: 30 + offset
        offset: 3
        radius: 15
        fill: Battery.charging ? Theme.pastels.green
            : Battery.percent <= 15 ? Theme.pastels.pink
            : Battery.percent <= 30 ? Theme.pastels.butter : Theme.card

        Row {
            id: batRow
            anchors.centerIn: parent
            spacing: 3
            PIcon {
                name: Battery.icon
                size: 17
                rotation: 90
                color: (Battery.charging || Battery.percent <= 30) ? Theme.onPastel : Theme.ink
                anchors.verticalCenter: parent.verticalCenter
            }
            PText {
                text: Battery.percent + "%"
                font.bold: true
                font.pixelSize: 12
                color: (Battery.charging || Battery.percent <= 30) ? Theme.onPastel : Theme.ink
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
