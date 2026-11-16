import QtQuick
import qs.services
import qs.theme
import qs.components

// Settings → Appearance: Smoked Glass (default), Clear Glass or Classic.
// Each tile shows a mini pill and a toggle over a little wallpaper, drawn
// in that look's own colours, so you can compare them before switching.
Item {
    id: root
    width: parent ? parent.width : 500
    readonly property int tileH: 132
    height: tileH

    readonly property var list: [
        { v: "smoke", l: "Smoked Glass" },
        { v: "clear", l: "Clear Glass" },
        { v: "classic", l: "Classic" }
    ]

    Row {
        anchors.fill: parent
        spacing: 12
        readonly property real w: Math.floor((width - 24) / 3)

        Repeater {
            model: root.list
            delegate: Item {
                id: tile
                required property var modelData
                readonly property bool on: Theme.look === modelData.v
                readonly property bool glassy: modelData.v !== "classic"
                readonly property var m: glassy ? Theme.glassModes[modelData.v]
                                                : (Theme.modes[Config.s.surface] ?? Theme.modes.cream)
                // the accent as it would sit on this look
                readonly property color acc: modelData.v === "clear" ? "#ffffff"
                                           : modelData.v === "smoke" ? Qt.rgba(Theme.accentRaw.r, Theme.accentRaw.g, Theme.accentRaw.b, 0.30)
                                           : Theme.accentRaw
                width: parent.w
                height: root.tileH
                scale: area.pressed ? 0.97 : 1
                Behavior on scale { NumberAnimation { duration: 90 } }

                // a little wallpaper (the same for every tile)
                Rectangle {
                    id: wall
                    anchors.fill: parent
                    radius: Theme.radius + 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#5e7fc7" }
                        GradientStop { position: 0.5; color: "#c77fae" }
                        GradientStop { position: 1.0; color: "#f2a07b" }
                    }
                    border.width: tile.on ? 2 : 0
                    border.color: Theme.strong(Theme.accent)
                }

                // mini pill
                Rectangle {
                    id: mini
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 14
                    width: parent.width - 36; height: 26
                    radius: 13
                    color: tile.glassy ? tile.m.base : tile.m.card
                    border.width: tile.glassy ? 1 : 2
                    border.color: tile.m.line
                    Rectangle {
                        visible: tile.glassy
                        x: 10; y: 1; width: parent.width - 20; height: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.5; color: tile.m.rim ?? "transparent" }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }
                    Rectangle {
                        x: 5; anchors.verticalCenter: parent.verticalCenter
                        width: 16; height: 16; radius: 8
                        color: tile.acc
                        border.width: 1
                        border.color: tile.glassy ? (tile.modelData.v === "clear" ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(Theme.accentRaw.r, Theme.accentRaw.g, Theme.accentRaw.b, 0.62)) : tile.m.line
                    }
                    PText {
                        anchors.centerIn: parent
                        text: Clock.hm
                        font.pixelSize: 10
                        font.bold: true
                        color: tile.m.ink
                    }
                }
                // mini toggle, on
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 50
                    width: 34; height: 18; radius: 9
                    color: tile.acc
                    border.width: tile.glassy ? 1 : 2
                    border.color: tile.glassy ? (tile.modelData.v === "clear" ? Qt.rgba(1, 1, 1, 0.75) : Qt.rgba(Theme.accentRaw.r, Theme.accentRaw.g, Theme.accentRaw.b, 0.62)) : tile.m.line
                    Rectangle {
                        x: parent.width - width - 3; y: 3
                        width: 12; height: 12; radius: 6
                        color: tile.glassy ? (tile.modelData.v === "clear" ? "#15171c" : tile.m.knob) : tile.m.card
                    }
                }

                // name + check
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 8
                    height: 30
                    radius: 15
                    color: Qt.rgba(0.06, 0.07, 0.1, 0.55)
                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Rectangle {
                            width: 14; height: 14; radius: 7
                            anchors.verticalCenter: parent.verticalCenter
                            color: tile.on ? "#ffffff" : "transparent"
                            border.width: 1.5
                            border.color: "#ffffff"
                            PIcon { anchors.centerIn: parent; visible: tile.on; name: "check"; size: 11; color: "#15171c" }
                        }
                        PText {
                            text: tile.modelData.l
                            font.bold: true
                            font.pixelSize: 11
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Config.s.look = tile.modelData.v
                }
            }
        }
    }
}
