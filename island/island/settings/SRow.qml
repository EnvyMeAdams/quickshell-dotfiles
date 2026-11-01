import QtQuick
import qs.theme
import qs.components

Card {
    id: root

    property string label: ""
    property string hint: ""
    default property alias trailing: trailingRow.data

    width: parent ? parent.width : 300
    height: (hint ? 62 : 52) + offset

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.right: trailingRow.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        PText { width: parent.width; text: root.label; font.bold: true }
        PText { width: parent.width; text: root.hint; visible: text !== ""; color: Theme.sub; font.pixelSize: 11 }
    }

    Row {
        id: trailingRow
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
    }
}
