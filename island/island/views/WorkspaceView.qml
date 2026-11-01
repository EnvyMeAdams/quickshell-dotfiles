import QtQuick
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    property string screenName: ""
    readonly property int ws: Compositor.workspace(screenName) || 1
    // ids that exist on this display (always including the current one)
    readonly property var list: {
        const l = Compositor.workspaces(screenName).slice();
        if (!l.includes(ws)) { l.push(ws); l.sort((a, b) => a - b); }
        return l;
    }

    Chip {
        id: num
        anchors.left: parent.left
        anchors.leftMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        size: 26
        fontSize: 13
        text: root.ws
        fill: Theme.accent
    }

    PText {
        anchors.left: num.right
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        text: Compositor.kind === "mango" ? "Tag" : "Workspace"
        font.bold: true
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Repeater {
            model: root.list
            delegate: Rectangle {
                required property var modelData
                readonly property bool current: modelData === root.ws
                anchors.verticalCenter: parent.verticalCenter
                width: current ? 22 : 9
                height: 9
                radius: 4.5
                color: current ? Theme.accent : Theme.sunk
                border.width: 1
                border.color: Theme.line
                Behavior on width { NumberAnimation { duration: Theme.dur(200); easing.type: Easing.OutBack } }
            }
        }
    }
}
