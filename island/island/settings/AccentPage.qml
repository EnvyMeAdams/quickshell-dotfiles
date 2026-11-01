import QtQuick
import qs.services
import qs.theme
import qs.components

SPage {
    id: page
    title: "Accent"

    // follow the wallpaper
    Card {
        width: parent ? parent.width : 400
        height: 76 + offset
        fill: Config.s.accent === "wallpaper" ? Theme.accent : (wpArea.containsMouse ? Theme.hover : Theme.card)

        Rectangle {
            id: wpSwatch
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 44; height: 44; radius: 22
            border.width: Theme.outline
            border.color: Theme.line
            gradient: Gradient {
                GradientStop { position: 0; color: AutoColor.ready ? AutoColor.color : Theme.pastels.peach }
                GradientStop { position: 1; color: Theme.pastels.lilac }
            }
            PIcon { anchors.centerIn: parent; name: "wallpaper"; color: Theme.onPastel }
        }
        Column {
            anchors.left: wpSwatch.right
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            PText { text: "Wallpaper"; font.bold: true; color: Config.s.accent === "wallpaper" ? Theme.onPastel : Theme.ink }
            PText {
                text: AutoColor.error ? "Needs a newer Quickshell" : "Picked from your photo or video"
                font.pixelSize: 11
                color: Config.s.accent === "wallpaper" ? Theme.onPastel : Theme.sub
            }
        }
        MouseArea {
            id: wpArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Config.s.accent = "wallpaper"
        }
    }

    Flow {
        width: parent ? parent.width : 400
        spacing: 12

        Repeater {
            model: Theme.accentNames
            delegate: Card {
                id: sw
                required property string modelData
                readonly property bool on: Config.s.accent === modelData
                width: 104 + offset
                height: 84 + offset
                fill: on ? Theme.pastels[modelData] : (area.containsMouse ? Theme.hover : Theme.card)

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 12
                    width: 36; height: 36; radius: 18
                    color: Theme.pastels[sw.modelData]
                    border.width: Theme.outline
                    border.color: Theme.line
                    PIcon { anchors.centerIn: parent; visible: sw.on; name: "check"; color: Theme.onPastel }
                }
                PText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 10
                    text: sw.modelData.charAt(0).toUpperCase() + sw.modelData.slice(1)
                    font.pixelSize: 11
                    font.bold: sw.on
                    color: sw.on ? Theme.onPastel : Theme.ink
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Config.s.accent = sw.modelData
                }
            }
        }
    }
}
