import QtQuick
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    PButton {
        id: mute
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        offset: 3
        faceHeight: 32
        icon: Audio.icon(Audio.volume, Audio.muted)
        checked: !Audio.muted
        tint: Theme.accent
        onClicked: Audio.toggleMute()
    }

    PSlider {
        anchors.left: mute.right
        anchors.leftMargin: 12
        anchors.right: pct.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        value: Audio.muted ? 0 : Audio.volume
        onMoved: v => Audio.setVolume(v)
    }

    PText {
        id: pct
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        horizontalAlignment: Text.AlignRight
        text: Audio.muted ? "Off" : Math.round(Audio.volume * 100) + "%"
        font.bold: true
    }
}
