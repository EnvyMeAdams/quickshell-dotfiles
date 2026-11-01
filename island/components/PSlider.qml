import QtQuick
import qs.services
import qs.theme

// Drag or click to set. Mouse wheel passes through to the page scroll
// unless "Scroll on Sliders" is turned on — that was the old scroll fight.
Item {
    id: root

    property real value: 0
    property color tint: Theme.accent
    signal moved(real v)

    implicitWidth: 200
    implicitHeight: 22

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 14
        radius: 7
        color: Theme.sunk
        border.width: Theme.outline
        border.color: Theme.line

        Rectangle {
            width: Math.max(height, track.width * Math.max(0, Math.min(1, root.value)))
            height: parent.height
            radius: parent.radius
            color: root.tint
            border.width: Theme.outline
            border.color: Theme.line
            Behavior on width { enabled: !area.pressed; NumberAnimation { duration: 90 } }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.topMargin: -4
        anchors.bottomMargin: -4
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        function set(x) { root.moved(Math.max(0, Math.min(1, x / width))); }
        onPressed: m => set(m.x)
        onPositionChanged: m => { if (pressed) set(m.x); }
        onWheel: w => {
            if (!Config.s.sliderWheel) { w.accepted = false; return; }
            root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))));
        }
    }
}
