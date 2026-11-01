import QtQuick
import qs.theme
import qs.components

Card {
    id: root

    property string text: ""

    width: parent ? parent.width : 400
    height: body.implicitHeight + 32 + offset

    PText {
        id: body
        x: 16
        y: 16
        width: parent.width - 32
        text: root.text
        wrapMode: Text.Wrap
        elide: Text.ElideNone
        textFormat: Text.PlainText
        font.pixelSize: 12
    }
}
