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
        anchors.right: sep.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Repeater {
            // skip buttons fall back to -10 s / +10 s when the app has no
            // previous/next track (YouTube in Firefox, single videos, …)
            model: [
                { icon: Media.canPrev ? "skip_previous" : "replay_10", ok: Media.canPrev || Media.canSeekNow, act: () => Media.prev() },
                { icon: Media.playing ? "pause" : "play_arrow", ok: true, act: () => Media.toggle() },
                { icon: Media.canNext ? "skip_next" : "forward_10", ok: Media.canNext || Media.canSeekNow, act: () => Media.next() }
            ]
            delegate: PIcon {
                id: btn
                required property var modelData
                name: modelData.icon
                size: 18
                width: 24
                height: 24
                opacity: modelData.ok ? (area.containsMouse ? 1 : 0.85) : 0.3
                scale: area.pressed ? 0.85 : 1
                Behavior on scale { NumberAnimation { duration: 80 } }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    anchors.margins: -3
                    hoverEnabled: true
                    enabled: btn.modelData.ok
                    cursorShape: Qt.PointingHandCursor
                    // swallow the press so the pill underneath doesn't open the hub
                    acceptedButtons: Qt.LeftButton
                    onClicked: btn.modelData.act()
                }
            }
        }
    }

    Rectangle {
        id: sep
        anchors.right: rightBox.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 1.5
        height: 16
        color: Theme.line
        opacity: 0.4
    }

    Row {
        id: rightBox
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        PillBattery { anchors.verticalCenter: parent.verticalCenter }
        PText {
            id: clock
            text: Clock.hm + (Clock.ampm ? " " + Clock.ampm : "")
            font.pixelSize: 12
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
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
}
