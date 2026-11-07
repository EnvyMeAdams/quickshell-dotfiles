import QtQuick
import qs.services
import qs.theme

// Small battery for the pill: icon + percent. Only exists when the Battery
// service says there's one (laptop, or Settings → Home → Battery = On).
Item {
    id: root

    readonly property bool on: { try { return Battery.shown === true; } catch (e) { return false; } }
    readonly property bool low: on && !Battery.charging && Battery.percent <= 20

    visible: on
    implicitWidth: on ? row.implicitWidth + (low || Battery.charging ? 12 : 0) : 0
    implicitHeight: 20

    Rectangle {
        anchors.fill: parent
        visible: root.low || (root.on && Battery.charging)
        radius: height / 2
        color: root.low ? Theme.pastels.pink : Theme.pastels.green
        border.width: 1.5
        border.color: Theme.line
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2
        PIcon {
            name: root.on ? Battery.icon : ""
            size: 15
            rotation: 90
            color: (root.low || (root.on && Battery.charging)) ? Theme.onPastel : Theme.ink
            anchors.verticalCenter: parent.verticalCenter
        }
        PText {
            text: root.on ? Battery.percent + "%" : ""
            font.pixelSize: 11
            font.bold: true
            color: (root.low || (root.on && Battery.charging)) ? Theme.onPastel : Theme.ink
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
