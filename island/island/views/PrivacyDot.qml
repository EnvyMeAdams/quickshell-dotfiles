import QtQuick
import qs.theme

Rectangle {
    id: root

    property bool on: false
    property color dotColor: Theme.mic

    visible: on
    width: 9
    height: 9
    radius: 4.5
    color: dotColor
    border.width: 1
    border.color: Theme.line
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined

    SequentialAnimation on opacity {
        running: root.on
        loops: Animation.Infinite
        NumberAnimation { to: 0.45; duration: 900; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0; duration: 900; easing.type: Easing.InOutSine }
    }
}
