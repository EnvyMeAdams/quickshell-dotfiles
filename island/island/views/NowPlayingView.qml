import QtQuick
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    readonly property var p: Media.player

    ClippingRectangle {
        id: art
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        width: 24
        height: 24
        radius: 12
        color: Theme.accent

        Image {
            anchors.fill: parent
            source: root.p?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(64, 64)
            asynchronous: true
        }
        RotationAnimation on rotation {
            running: Media.playing
            loops: Animation.Infinite
            from: 0; to: 360
            duration: 9000
        }
    }

    PText {
        anchors.left: art.right
        anchors.leftMargin: 8
        anchors.right: controls.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: (root.p?.trackTitle ?? "") + ((root.p?.trackArtist) ? "  ·  " + root.p.trackArtist : "")
        font.pixelSize: 12
        font.bold: true
    }

    Row {
        id: controls
        anchors.right: clock.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            model: [
                { icon: "skip_previous", act: () => root.p?.previous() },
                { icon: Media.playing ? "pause" : "play_arrow", act: () => root.p?.togglePlaying() },
                { icon: "skip_next", act: () => root.p?.next() }
            ]
            delegate: PIcon {
                required property var modelData
                name: modelData.icon
                size: 18
                width: 22
                height: 22
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.modelData.act()
                }
            }
        }
    }

    Rectangle {
        anchors.right: clock.left
        anchors.rightMargin: 5
        anchors.verticalCenter: parent.verticalCenter
        width: 1.5
        height: 16
        color: Theme.line
        opacity: 0.4
    }

    Rectangle {
        visible: Recorder.recording
        anchors.left: art.right
        anchors.leftMargin: -8
        anchors.top: art.top
        width: 10; height: 10; radius: 5
        color: Theme.pastels.coral
        border.width: 1.5
        border.color: Theme.line
        z: 2
    }

    PText {
        id: clock
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        text: Clock.hm + (Clock.ampm ? " " + Clock.ampm : "")
        font.pixelSize: 12
        font.bold: true
    }
}
