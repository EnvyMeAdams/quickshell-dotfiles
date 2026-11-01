import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.components

// One volume row: an app, a speaker/headphones, or a mic.
//   kind: "app" | "output" | "input"
Card {
    id: row

    property var node: null
    property string kind: "app"
    property color tint: Theme.accent
    readonly property bool muted: node?.audio?.muted ?? false
    readonly property real vol: node?.audio?.volume ?? 0
    readonly property bool isDefault: kind === "output" ? node === Audio.sink
                                    : kind === "input" ? node === Audio.source : false
    readonly property string sub: kind === "app" ? Audio.detail(node)
                                : isDefault ? "Default" : "Click to make default"

    width: parent ? parent.width : 400
    height: 62 + offset
    fill: isDefault ? Qt.tint(Theme.card, Qt.rgba(tint.r, tint.g, tint.b, 0.35)) : Theme.card

    // icon: app icon, or a pastel bubble for devices
    Item {
        id: ic
        x: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 32; height: 32

        IconImage {
            id: appIcon
            anchors.fill: parent
            visible: row.kind === "app" && status === Image.Ready
            source: row.kind === "app" ? Quickshell.iconPath(Audio.nodeIcon(row.node), true) : ""
        }
        Rectangle {
            anchors.fill: parent
            visible: !appIcon.visible
            radius: 16
            color: row.tint
            border.width: Theme.outline
            border.color: Theme.line
            PIcon {
                anchors.centerIn: parent
                size: 17
                color: Theme.onPastel
                name: row.kind === "input" ? "mic" : row.kind === "output" ? "speaker" : "music_note"
            }
        }
    }

    // name, clicking a device makes it the default
    Item {
        id: label
        anchors.left: ic.right
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 190
        height: 40

        Column {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            PText { width: parent.width; text: Audio.nodeName(row.node); font.bold: true }
            PText { width: parent.width; text: row.sub; visible: text !== ""; font.pixelSize: 11; color: Theme.sub }
        }
        MouseArea {
            anchors.fill: parent
            enabled: row.kind !== "app" && !row.isDefault
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: row.kind === "output" ? Audio.setDefault(row.node) : Audio.setDefaultSource(row.node)
        }
    }

    PSlider {
        anchors.left: label.right
        anchors.leftMargin: 12
        anchors.right: pct.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        value: row.muted ? 0 : row.vol
        tint: row.tint
        onMoved: v => Audio.setNode(row.node, v)
    }
    PText {
        id: pct
        anchors.right: mute.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        horizontalAlignment: Text.AlignRight
        text: row.muted ? "Off" : Math.round(row.vol * 100) + "%"
        font.pixelSize: 12
        font.bold: true
    }
    PButton {
        id: mute
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        icon: row.muted ? (row.kind === "input" ? "mic_off" : "volume_off")
                        : (row.kind === "input" ? "mic" : "volume_up")
        faceHeight: 28
        offset: 3
        pad: 4
        checked: row.muted
        tint: Theme.pastels.pink
        onClicked: Audio.muteNode(row.node)
    }
}
