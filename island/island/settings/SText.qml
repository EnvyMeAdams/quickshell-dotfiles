import QtQuick
import qs.services
import qs.components

SRow {
    id: root

    property string key: ""
    property string placeholder: ""
    property int fieldWidth: 320

    PField {
        id: f
        width: root.fieldWidth
        anchors.verticalCenter: parent.verticalCenter
        placeholder: root.placeholder
        text: Config.s[root.key] ?? ""
        onEdited: if (text !== Config.s[root.key]) Config.s[root.key] = text
    }
}
