import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.services
import qs.theme
import qs.components

// System tray (Discord, Steam, …). Left click = open, right click = menu,
// middle click = secondary action. Scroll sideways if there are many.
Card {
    id: root

    property real maxWidth: 220
    readonly property var items: SystemTray.items.values

    visible: items.length > 0
    width: Math.min(maxWidth, list.contentWidth + 16) + offset
    height: 30 + offset
    offset: 3
    radius: 15

    ListView {
        id: list
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        orientation: ListView.Horizontal
        spacing: 6
        clip: true
        interactive: contentWidth > width
        boundsBehavior: Flickable.StopAtBounds
        model: root.items

        WheelHandler {
            target: null
            onWheel: ev => {
                const max = Math.max(0, list.contentWidth - list.width);
                list.contentX = Math.max(0, Math.min(max, list.contentX - (ev.angleDelta.y || ev.angleDelta.x) / 2));
            }
        }

        delegate: Item {
            id: cell
            required property var modelData
            width: 20
            height: list.height

            IconImage {
                anchors.centerIn: parent
                implicitSize: 18
                source: {
                    const ic = cell.modelData.icon ?? "";
                    // some apps send "name?path=/dir": look the name up in that folder
                    if (ic.includes("?path=")) {
                        const parts = ic.split("?path=");
                        const name = parts[0].split("/").pop();
                        return "file://" + parts[1] + "/" + name + ".png";
                    }
                    return ic;
                }
                opacity: cell.modelData.status === Status.Passive ? 0.5 : 1
            }

            // the app's own right-click menu, opened just under the icon
            QsMenuAnchor {
                id: menu
                menu: cell.modelData.menu
                anchor.item: cell
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom
            }

            MouseArea {
                id: area
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                // a tiny drag shouldn't turn a click into a scroll of the row
                preventStealing: true
                onClicked: m => {
                    const item = cell.modelData;
                    try {
                        if (m.button === Qt.MiddleButton) {
                            item.secondaryActivate();
                        } else if (m.button === Qt.RightButton || item.onlyMenu) {
                            if (item.hasMenu) menu.open();
                            else item.activate();      // no menu: treat as a normal click
                        } else {
                            item.activate();
                            // let the app receive the click before the hub closes
                            Qt.callLater(Island.close);
                        }
                    } catch (e) {
                        console.warn("tray: click on", item.id, "failed:", e);
                    }
                }
                onWheel: w => cell.modelData.scroll(w.angleDelta.y, false)
            }

            Chip {
                z: 50
                visible: area.containsMouse && text !== ""
                anchors.top: parent.bottom
                anchors.topMargin: 6
                anchors.horizontalCenter: parent.horizontalCenter
                text: cell.modelData.tooltipTitle || cell.modelData.title || ""
                fill: Theme.card
                size: 20
                fontSize: 10
            }
        }
    }
}
