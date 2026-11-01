import QtQuick
import qs.theme
import qs.components

// Reboot / Power Off need a second press within 3 s — no accidental shutdowns.
PButton {
    id: root

    property string label: ""
    property string kind: ""
    property bool confirm: false
    property bool armedState: false

    faceHeight: 40
    text: armedState ? "Sure?" : label
    checked: armedState
    onClicked: {
        if (confirm && !armedState) { armedState = true; disarm.restart(); return; }
        armedState = false;
        ControlActions.power(kind);
    }

    Timer { id: disarm; interval: 3000; onTriggered: root.armedState = false }
}
