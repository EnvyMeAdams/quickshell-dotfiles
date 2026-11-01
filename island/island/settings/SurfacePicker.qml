import QtQuick
import qs.services
import qs.theme
import qs.components

// Four mini previews: each shows its own surface with a few pastel buttons.
Item {
    id: root
    width: parent ? parent.width : 500
    height: 128

    readonly property var list: [
        { v: "cream", l: "Cream" }, { v: "fog", l: "Fog" },
        { v: "slate", l: "Slate" }, { v: "cocoa", l: "Cocoa" }
    ]

    Row {
        anchors.fill: parent
        spacing: 12
        readonly property real w: Math.floor((width - 36) / 4)

        Repeater {
            model: root.list
            delegate: Item {
                id: tile
                required property var modelData
                readonly property var m: Theme.modes[modelData.v]
                readonly property bool on: Config.s.surface === modelData.v
                width: parent.w
                height: root.height

                // shadow + face drawn with this surface's own colours
                Rectangle {
                    x: Theme.shadow; y: Theme.shadow
                    width: parent.width - Theme.shadow; height: parent.height - Theme.shadow
                    radius: Theme.radius
                    color: tile.m.shade
                }
                Rectangle {
                    id: face
                    x: area.pressed ? Theme.shadow : 0
                    y: area.pressed ? Theme.shadow : 0
                    width: parent.width - Theme.shadow; height: parent.height - Theme.shadow
                    radius: Theme.radius
                    color: tile.m.base
                    border.width: tile.on ? Theme.outline + 1 : Theme.outline
                    border.color: tile.m.line

                    Rectangle {
                        x: 10; y: 10
                        width: parent.width - 20; height: 40
                        radius: 12
                        color: tile.m.card
                        border.width: Theme.outline
                        border.color: tile.m.line
                        Row {
                            anchors.centerIn: parent
                            spacing: 5
                            Repeater {
                                model: [Theme.pastels.pink, Theme.pastels.butter, Theme.pastels.mint, Theme.pastels.lavender]
                                Rectangle {
                                    required property color modelData
                                    width: 14; height: 14; radius: 7
                                    color: modelData
                                    border.width: 1.5
                                    border.color: tile.m.line
                                }
                            }
                        }
                    }
                    Row {
                        x: 12
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 12
                        spacing: 6
                        Rectangle {
                            width: 16; height: 16; radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: tile.on ? Theme.accent : "transparent"
                            border.width: 1.5
                            border.color: tile.m.ink
                            PIcon { anchors.centerIn: parent; visible: tile.on; name: "check"; size: 12; color: Theme.onPastel }
                        }
                        PText {
                            text: tile.modelData.l
                            font.bold: true
                            color: tile.m.ink
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Config.s.surface = tile.modelData.v
                }
            }
        }
    }
}
