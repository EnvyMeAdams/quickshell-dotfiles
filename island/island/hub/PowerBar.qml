import QtQuick
import qs.services
import qs.theme
import qs.components

// Home, top left: icon-only power buttons. Hover shows the name; Reboot,
// Power and Log Out need a second click within 3 s (Settings → Home).
Row {
    id: bar
    spacing: 5

    property string armed: ""
    Timer { id: disarm; interval: 3000; onTriggered: bar.armed = "" }

    readonly property var items: [
        { kind: "lock", icon: "lock", label: "Lock", tint: Theme.pastels.blue, confirm: false },
        { kind: "saver", icon: "movie", label: "Saver", tint: Theme.pastels.green, confirm: false },
        { kind: "sleep", icon: "dark_mode", label: "Sleep", tint: Theme.pastels.lilac, confirm: false },
        { kind: "logout", icon: "logout", label: "Log Out", tint: Theme.pastels.butter, confirm: true },
        { kind: "reboot", icon: "restart_alt", label: "Reboot", tint: Theme.pastels.peach, confirm: true },
        { kind: "poweroff", icon: "power_settings_new", label: "Power", tint: Theme.pastels.pink, confirm: true }
    ]

    Repeater {
        model: bar.items
        delegate: PButton {
            id: b
            required property var modelData
            readonly property bool isArmed: bar.armed === modelData.kind
            icon: isArmed ? "check" : modelData.icon
            iconSize: 17
            faceHeight: 30
            offset: 3
            pad: 0
            checked: isArmed
            tint: modelData.tint
            onClicked: {
                if (modelData.confirm && Config.s.powerConfirm && !isArmed) {
                    bar.armed = modelData.kind;
                    disarm.restart();
                    return;
                }
                bar.armed = "";
                ControlActions.power(modelData.kind);
            }

            // name under the button on hover, "Sure?" while armed
            Chip {
                z: 50
                visible: b.hovered || b.isArmed
                anchors.top: parent.bottom
                anchors.topMargin: 4
                anchors.horizontalCenter: parent.horizontalCenter
                text: b.isArmed ? "Sure?" : b.modelData.label
                fill: b.isArmed ? b.modelData.tint : Theme.card
                size: 20
                fontSize: 10
            }
        }
    }
}
