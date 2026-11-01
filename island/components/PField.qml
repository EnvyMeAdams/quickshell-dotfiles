import QtQuick
import qs.theme

Card {
    id: root

    property alias text: textInput.text
    property alias input: textInput
    property string placeholder: ""
    property string icon: ""
    property bool password: false
    signal accepted()
    signal edited()
    signal keyPressed(var event)

    fill: Theme.sunk
    offset: 0
    radius: Math.min(Theme.radius, height / 2)
    implicitWidth: 240
    implicitHeight: 36

    PIcon {
        id: ic
        name: root.icon
        visible: root.icon !== ""
        size: 18
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
    }

    TextInput {
        id: textInput
        anchors.left: ic.visible ? ic.right : parent.left
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        font.family: Theme.font
        font.pixelSize: 13
        color: Theme.ink
        selectionColor: Theme.accent
        selectedTextColor: Theme.onPastel
        selectByMouse: true
        clip: true
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        onAccepted: root.accepted()
        onEditingFinished: root.edited()
        Keys.onPressed: e => root.keyPressed(e)

        PText {
            anchors.fill: parent
            text: root.placeholder
            color: Theme.sub
            visible: !textInput.text && !textInput.preeditText
        }
    }
}
