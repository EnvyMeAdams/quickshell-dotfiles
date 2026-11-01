import QtQuick
import qs.services
import qs.theme
import qs.components

// options: [{ v: value, l: "Label", c: optional colour }]
SRow {
    id: root

    property string key: ""
    property var options: []

    Repeater {
        model: root.options
        delegate: PButton {
            required property var modelData
            text: modelData.l ?? ""
            icon: modelData.i ?? ""
            faceHeight: 28
            offset: 3
            pad: modelData.l ? 10 : 4
            checked: Config.s[root.key] === modelData.v
            tint: modelData.c ?? Theme.accent
            onClicked: Config.s[root.key] = modelData.v
        }
    }
}
