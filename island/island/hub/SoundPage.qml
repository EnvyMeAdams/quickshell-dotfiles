import QtQuick
import qs.services
import qs.theme
import qs.components

// SUPER+S. Every app, every speaker and every mic, each with its own volume.
Item {
    id: root

    property string section: "apps"     // apps | outputs | inputs

    Row {
        id: tabs
        anchors.top: parent.top
        anchors.left: parent.left
        spacing: 8
        PButton {
            icon: "apps"
            text: "Apps" + (Audio.streams.length ? " " + Audio.streams.length : "")
            checked: root.section === "apps"
            tint: Theme.pastels.pink
            onClicked: root.section = "apps"
        }
        PButton {
            icon: "speaker"
            text: "Outputs"
            checked: root.section === "outputs"
            tint: Theme.pastels.blue
            onClicked: root.section = "outputs"
        }
        PButton {
            icon: "mic"
            text: "Inputs"
            checked: root.section === "inputs"
            tint: Theme.pastels.green
            onClicked: root.section = "inputs"
        }
    }

    // master volume, always visible
    Card {
        id: master
        anchors.top: tabs.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        height: 54 + offset
        SliderRow {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 14
            icon: Audio.icon(Audio.volume, Audio.muted)
            label: "Master"
            value: Audio.muted ? 0 : Audio.volume
            tint: Theme.accent
            onMoved: v => Audio.setVolume(v)
            onIconClicked: Audio.toggleMute()
        }
    }

    PScroll {
        anchors.top: master.bottom
        anchors.topMargin: 14
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 8

        Repeater {
            model: root.section === "apps" ? Audio.streams
                 : root.section === "outputs" ? Audio.sinks : Audio.sources
            delegate: NodeRow {
                required property var modelData
                required property int index
                node: modelData
                kind: root.section === "apps" ? "app" : root.section === "outputs" ? "output" : "input"
                tint: Theme.cycle[index % Theme.cycle.length]
            }
        }

        Column {
            width: parent.width
            visible: root.section === "apps" && Audio.streams.length === 0
            spacing: 6
            topPadding: 30
            PIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "music_off"; size: 36; color: Theme.sub }
            PText { anchors.horizontalCenter: parent.horizontalCenter; text: "No Apps Playing"; color: Theme.sub }
        }
    }
}
