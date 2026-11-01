import QtQuick
import qs.services
import qs.theme
import qs.components

Card {
    id: root

    property var n: null

    height: Math.max(76, col.implicitHeight + 26) + offset

    Avatar {
        id: av
        x: 14
        y: 14
        width: 46
        height: 46
        source: Notifs.imageFor(root.n)
        letter: root.n?.appName ?? "?"
        fill: Theme.pastels.rose
    }

    Column {
        id: col
        anchors.left: av.right
        anchors.leftMargin: 12
        anchors.right: close.left
        anchors.rightMargin: 10
        y: 13
        spacing: 3

        PText { width: parent.width; text: root.n?.appName ?? ""; color: Theme.sub; font.pixelSize: 11 }
        PText { width: parent.width; text: root.n?.summary ?? ""; font.bold: true }
        PText {
            width: parent.width
            text: root.n?.body ?? ""
            visible: text !== ""
            color: Theme.sub
            font.pixelSize: 12
            wrapMode: Text.Wrap
            maximumLineCount: 4
        }
        Flow {
            width: parent.width
            spacing: 6
            visible: (root.n?.actions?.length ?? 0) > 0
            topPadding: 4
            Repeater {
                model: root.n?.actions ?? []
                delegate: PButton {
                    required property var modelData
                    text: modelData.text
                    faceHeight: 26
                    offset: 2
                    onClicked: modelData.invoke()
                }
            }
        }
    }

    PButton {
        id: close
        anchors.right: parent.right
        anchors.rightMargin: 12
        y: 12
        icon: "close"
        iconSize: 15
        faceHeight: 24
        offset: 2
        pad: 2
        onClicked: root.n?.dismiss()
    }
}
