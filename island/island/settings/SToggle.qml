import QtQuick
import qs.services
import qs.components

SRow {
    id: root
    property string key: ""

    PToggle {
        checked: !!Config.s[root.key]
        onToggled: Config.s[root.key] = !Config.s[root.key]
    }
}
