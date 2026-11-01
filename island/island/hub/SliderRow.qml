import QtQuick
import qs.theme
import qs.components

Item {
    id: root

    property string icon: ""
    property string label: ""
    property real value: 0
    property color tint: Theme.accent
    signal moved(real v)
    signal iconClicked()

    implicitHeight: 34

    PButton {
        id: btn
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        icon: root.icon
        faceHeight: 30
        offset: 3
        pad: 6
        onClicked: root.iconClicked()
    }
    PText {
        id: lbl
        visible: root.label !== ""
        anchors.left: btn.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: visible ? 150 : 0
        text: root.label
        font.bold: true
    }
    PSlider {
        anchors.left: lbl.visible ? lbl.right : btn.right
        anchors.leftMargin: 12
        anchors.right: pct.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        value: root.value
        tint: root.tint
        onMoved: v => root.moved(v)
    }
    PText {
        id: pct
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100) + "%"
        font.bold: true
        font.pixelSize: 12
    }
}
