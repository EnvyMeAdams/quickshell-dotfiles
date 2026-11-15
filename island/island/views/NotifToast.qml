import QtQuick
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    readonly property var n: Notifs.latest

    Avatar {
        id: av
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        height: 56
        source: Notifs.imageFor(root.n)
        letter: root.n?.appName ?? "?"
        fill: Theme.pastels.rose
    }

    Column {
        anchors.left: av.right
        anchors.leftMargin: 14
        anchors.right: close.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        PText {
            width: parent.width
            text: root.n?.appName ?? ""
            color: Theme.sub
            font.pixelSize: 11
        }
        PText {
            width: parent.width
            text: root.n?.summary ?? ""
            font.bold: true
            font.pixelSize: 14
        }
        PText {
            width: parent.width
            text: root.n?.body ?? ""
            color: Theme.sub
            font.pixelSize: 12
            wrapMode: Text.Wrap
            maximumLineCount: 2
            visible: text !== ""
        }
    }

    PButton {
        id: close
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: parent.top
        anchors.topMargin: 12
        icon: "close"
        iconSize: 16
        faceHeight: 26
        offset: 2
        onClicked: { root.n?.dismiss(); Island.dismiss(); }
    }
}
