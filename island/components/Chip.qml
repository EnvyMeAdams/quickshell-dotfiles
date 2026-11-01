import QtQuick
import qs.theme

Rectangle {
    id: root

    property string text: ""
    property color fill: Theme.accent
    property int size: 22
    property int fontSize: 11

    implicitWidth: Math.max(size, label.implicitWidth + 14)
    implicitHeight: size
    radius: height / 2
    color: fill
    border.width: Math.max(1, Theme.outline - 0.5)
    border.color: Theme.line
    Behavior on color { ColorAnimation { duration: 140 } }

    PText {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.bold: true
        font.pixelSize: root.fontSize
        color: Theme.onPastel
    }
}
