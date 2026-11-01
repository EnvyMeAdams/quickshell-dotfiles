import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.greet

// Island login screen for greetd. Started by run.sh inside a tiny
// Hyprland that only exists until you sign in.
ShellRoot {
    id: root

    GreetSession { id: greetSession }

    // the display that gets the keyboard first: the first Lock Display, else the first screen
    readonly property string firstScreen: {
        const names = Quickshell.screens.map(s => s.name);
        const picked = (Config.s.lockDisplays ?? []).find(n => names.includes(n));
        return picked ?? names[0] ?? "";
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "black"
            WlrLayershell.namespace: "island-greeter"
            WlrLayershell.layer: WlrLayer.Overlay
            // one display holds the keyboard; click another to type there
            WlrLayershell.keyboardFocus: modelData.name === root.firstScreen
                ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

            GreetSurface {
                anchors.fill: parent
                session: greetSession
                screenName: win.modelData.name
            }
        }
    }
}
