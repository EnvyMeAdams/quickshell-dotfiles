import QtQuick
import qs.services
import qs.theme

Card {
    id: root

    property string text: ""
    property string icon: ""
    property real iconSize: 18
    property bool checked: false
    property color tint: Theme.accent
    property int pad: 12
    property int faceHeight: 32
    readonly property bool hovered: area.containsMouse
    signal clicked()
    signal rightClicked()

    fill: checked ? tint : (hovered ? Theme.hover : Theme.card)
    pressed: area.pressed && Config.s.pressEffect
    radius: Math.min(Theme.radius, faceHeight / 2)
    implicitWidth: Math.max(faceHeight, row.implicitWidth + pad * 2) + offset
    implicitHeight: faceHeight + offset

    Behavior on implicitWidth { NumberAnimation { duration: Theme.dur(180); easing.type: Easing.OutBack } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 6
        PIcon {
            name: root.icon
            size: root.iconSize
            visible: root.icon !== ""
            color: root.checked ? Theme.onPastel : Theme.ink
            anchors.verticalCenter: parent.verticalCenter
        }
        PText {
            text: root.text
            visible: root.text !== ""
            font.bold: true
            font.pixelSize: 12
            color: root.checked ? Theme.onPastel : Theme.ink
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }
}
