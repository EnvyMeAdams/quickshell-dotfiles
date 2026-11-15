import QtQuick
import qs.theme

// Three dots bouncing in turn: someone is typing.
Row {
    id: root
    property color dotColor: Theme.sub
    spacing: 4
    Repeater {
        model: 3
        delegate: Rectangle {
            required property int index
            width: 7; height: 7; radius: 3.5
            color: root.dotColor
            anchors.verticalCenter: parent.verticalCenter
            SequentialAnimation on anchors.verticalCenterOffset {
                running: root.visible
                loops: Animation.Infinite
                PauseAnimation { duration: index * 140 }
                NumberAnimation { to: -4; duration: 220; easing.type: Easing.OutQuad }
                NumberAnimation { to: 0; duration: 220; easing.type: Easing.InQuad }
                PauseAnimation { duration: (2 - index) * 140 + 260 }
            }
        }
    }
}
