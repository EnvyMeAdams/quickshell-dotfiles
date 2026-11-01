import QtQuick
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.components

Card {
    id: root

    readonly property var p: Media.player

    PText {
        anchors.centerIn: parent
        visible: !Media.active
        text: "Nothing Playing"
        color: Theme.sub
    }

    Item {
        anchors.fill: parent
        anchors.margins: 14
        visible: Media.active

        // album art with its own little shadow
        Item {
            id: artBox
            width: height
            height: parent.height
            Rectangle {
                x: 3; y: 3
                width: parent.width - 3; height: parent.height - 3
                radius: 14
                color: Theme.shade
            }
            ClippingRectangle {
                width: parent.width - 3; height: parent.height - 3
                radius: 14
                color: Theme.accent
                Image {
                    anchors.fill: parent
                    source: root.p?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(320, 320)
                    asynchronous: true
                }
                PIcon { anchors.centerIn: parent; name: "music_note"; size: 40; color: Theme.onPastel; z: -1 }
            }
            Rectangle {
                width: parent.width - 3; height: parent.height - 3
                radius: 14
                color: "transparent"
                border.width: Theme.outline
                border.color: Theme.line
            }
        }

        Column {
            anchors.left: artBox.right
            anchors.leftMargin: 18
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            Row {
                width: parent.width
                spacing: 8
                Column {
                    width: parent.width - (playerChip.visible ? playerChip.width + 8 : 0)
                    PText { width: parent.width; text: root.p?.trackTitle ?? ""; font.bold: true; font.pixelSize: 17 }
                    PText { width: parent.width; text: root.p?.trackArtist ?? ""; color: Theme.sub; font.pixelSize: 12 }
                }
                Chip {
                    id: playerChip
                    visible: Media.players.length > 1
                    text: root.p?.identity ?? ""
                    fill: Theme.pastels.sand
                    fontSize: 10
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            const i = Media.players.indexOf(Media.player);
                            Media.manual = Media.players[(i + 1) % Media.players.length];
                        }
                    }
                }
            }

            // pastel dot visualizer (cava)
            Row {
                height: 30
                spacing: 4
                visible: Config.s.visualizer
                Repeater {
                    model: Config.s.visualizerBars
                    Rectangle {
                        required property int index
                        anchors.verticalCenter: parent.verticalCenter
                        width: 9
                        height: 9 + ((Visualizer.bars[index] ?? 0) / 100) * 21
                        radius: 4.5
                        color: Theme.cycle[index % Theme.cycle.length]
                        border.width: 1
                        border.color: Theme.line
                        Behavior on height { NumberAnimation { duration: 60 } }
                    }
                }
            }

            Row {
                width: parent.width
                spacing: 10
                PText { id: posT; text: Media.fmt(root.p?.position ?? 0); font.pixelSize: 11; color: Theme.sub; anchors.verticalCenter: parent.verticalCenter }
                PSlider {
                    width: parent.width - posT.width - lenT.width - 20
                    anchors.verticalCenter: parent.verticalCenter
                    value: Media.progress
                    tint: Theme.pastels.rose
                    onMoved: v => Media.seek(v)
                }
                PText { id: lenT; text: Media.fmt(root.p?.length ?? 0); font.pixelSize: 11; color: Theme.sub; anchors.verticalCenter: parent.verticalCenter }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                PButton { icon: "skip_previous"; faceHeight: 34; onClicked: root.p?.previous() }
                PButton {
                    icon: Media.playing ? "pause" : "play_arrow"
                    faceHeight: 34; pad: 16
                    checked: true
                    tint: Theme.pastels.pink
                    onClicked: root.p?.togglePlaying()
                }
                PButton { icon: "skip_next"; faceHeight: 34; onClicked: root.p?.next() }
            }
        }
    }
}
