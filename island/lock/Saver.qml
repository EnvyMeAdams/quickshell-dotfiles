import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.components
import qs.media

// Screensaver: full-screen video on top of everything. A click or key ends it.
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property ShellScreen modelData
            screen: modelData

            visible: LockState.saver && !LockState.locked && Wallpaper.onDisplay(Config.s.saverDisplays, modelData.name)
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: "black"
            WlrLayershell.namespace: "island-saver"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Item {
                id: content
                anchors.fill: parent
                focus: true
                opacity: 0

                Backdrop {
                    id: saverBg
                    anchors.fill: parent
                    path: Config.s.saverVideo
                    kind: "video"
                    screenName: win.modelData.name
                    playing: win.visible
                }

                Card {
                    visible: Config.s.saverClock
                    glassSource: Config.s.lockGlass ? saverBg : null
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 48
                    width: row.implicitWidth + 40 + offset
                    height: 74 + offset
                    radius: 24
                    Row {
                        id: row
                        anchors.centerIn: parent
                        spacing: 8
                        PText { text: Clock.hm; font.pixelSize: 34; font.bold: true }
                        Chip {
                            visible: Clock.ampm !== ""
                            text: Clock.ampm
                            fill: Theme.pastels.lilac
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 6
                        }
                    }
                }

                Keys.onPressed: e => { LockState.stopSaver(); e.accepted = true; }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    cursorShape: Qt.BlankCursor
                    onPressed: LockState.stopSaver()
                }
            }

            onVisibleChanged: {
                if (visible) { content.forceActiveFocus(); fadeIn.restart(); }
                else content.opacity = 0;
            }
            NumberAnimation { id: fadeIn; target: content; property: "opacity"; from: 0; to: 1; duration: 700; easing.type: Easing.OutCubic }
        }
    }
}
