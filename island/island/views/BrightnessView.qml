import QtQuick
import qs.services
import qs.theme
import qs.components
import qs.island.hub

// Brightness popup: sun button, slider, percent, and a night light toggle.
Item {
    id: root

    PButton {
        id: sun
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        offset: 3
        faceHeight: 32
        icon: Brightness.icon
        checked: true
        tint: Theme.pastels.butter
        onClicked: Brightness.set(Brightness.value < 0.5 ? 1 : 0.3)
    }

    PSlider {
        anchors.left: sun.right
        anchors.leftMargin: 12
        anchors.right: pct.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        value: Brightness.value
        tint: Theme.pastels.butter
        onMoved: v => Brightness.set(v)
    }

    PText {
        id: pct
        anchors.right: night.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        horizontalAlignment: Text.AlignRight
        text: Math.round(Brightness.value * 100) + "%"
        font.bold: true
    }

    PButton {
        id: night
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        offset: 3
        faceHeight: 32
        pad: 4
        icon: "bedtime"
        checked: Config.s.nightLight
        tint: Theme.pastels.coral
        onClicked: ControlActions.toggleNight()
    }
}
