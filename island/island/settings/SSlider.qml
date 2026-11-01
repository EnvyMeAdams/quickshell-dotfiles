import QtQuick
import qs.services
import qs.theme
import qs.components

SRow {
    id: root

    property string key: ""
    property real from: 0
    property real to: 1
    property real step: 1
    property string suffix: ""
    readonly property real val: Config.s[key] ?? from

    PSlider {
        width: 200
        anchors.verticalCenter: parent.verticalCenter
        value: (root.val - root.from) / (root.to - root.from)
        onMoved: v => {
            const raw = root.from + v * (root.to - root.from);
            const snapped = Math.round(raw / root.step) * root.step;
            Config.s[root.key] = Math.round(snapped * 100) / 100;
        }
    }
    PText {
        width: 64
        horizontalAlignment: Text.AlignRight
        anchors.verticalCenter: parent.verticalCenter
        text: root.val + root.suffix
        font.bold: true
        font.pixelSize: 12
    }
}
