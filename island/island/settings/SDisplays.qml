import QtQuick
import qs.services
import qs.theme
import qs.components

// Pick displays. Nothing picked = every display ("All").
SRow {
    id: root

    property string key: ""
    readonly property var picked: Config.s[key] ?? []

    function toggle(name) {
        const list = picked.slice();
        const i = list.indexOf(name);
        if (i >= 0) list.splice(i, 1); else list.push(name);
        // picking every display is the same as All
        Config.s[root.key] = list.length >= Wallpaper.displays.length ? [] : list;
    }

    PButton {
        text: "All"
        faceHeight: 28
        offset: 3
        checked: root.picked.length === 0
        tint: Theme.pastels.yellow
        onClicked: Config.s[root.key] = []
    }
    Repeater {
        model: Wallpaper.displays
        delegate: PButton {
            required property string modelData
            text: modelData
            faceHeight: 28
            offset: 3
            checked: root.picked.includes(modelData)
            tint: Theme.pastels.yellow
            onClicked: root.toggle(modelData)
        }
    }
}
