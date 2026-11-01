import QtQuick
import Quickshell.Widgets
import qs.theme

// Always a circle. Falls back to a pastel letter if the image is missing.
Item {
    id: root

    property url source: ""
    property string letter: "?"
    property color fill: Theme.accent

    implicitWidth: 40
    implicitHeight: 40

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.fill
        border.width: Theme.outline
        border.color: Theme.line

        PText {
            anchors.centerIn: parent
            text: (root.letter || "?").charAt(0).toUpperCase()
            visible: img.status !== Image.Ready
            font.bold: true
            font.pixelSize: root.height * 0.42
            color: Theme.onPastel
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        anchors.margins: Theme.outline
        radius: width / 2
        color: "transparent"
        visible: img.status === Image.Ready

        Image {
            id: img
            anchors.fill: parent
            source: root.source
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(Math.max(64, root.width * 2), Math.max(64, root.height * 2))
            asynchronous: true
            smooth: true
            mipmap: true
        }
    }
}
