import QtQuick
import qs.theme

Rectangle {
    id: root

    property bool checked: false
    property color tint: Theme.accent
    signal toggled()

    implicitWidth: 46
    implicitHeight: 26
    radius: height / 2
    color: checked ? tint : Theme.sunk
    border.width: Theme.outline
    border.color: checked ? Theme.edge(tint) : Theme.line
    Behavior on color { ColorAnimation { duration: 140 } }

    Rectangle {
        width: parent.height - 8
        height: width
        radius: width / 2
        y: 4
        x: root.checked ? root.width - width - 4 : 4
        // Clear's "on" track is milky-light, so its knob goes dark
        color: Theme.look === "clear" && root.checked ? Theme.onPastel : Theme.knob
        border.width: Theme.glass ? 0 : Theme.outline
        border.color: Theme.line
        Behavior on x { NumberAnimation { duration: Theme.dur(180); easing.type: Easing.OutBack } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
