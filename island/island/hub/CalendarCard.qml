import QtQuick
import qs.services
import qs.theme
import qs.components

Card {
    id: root

    property int monthOffset: 0
    readonly property date today: Clock.now
    readonly property date shownMonth: new Date(today.getFullYear(), today.getMonth() + monthOffset, 1)
    readonly property var days: {
        const y = shownMonth.getFullYear(), m = shownMonth.getMonth();
        const start = new Date(y, m, 1 - new Date(y, m, 1).getDay());
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
            out.push({ day: d.getDate(), inMonth: d.getMonth() === m,
                       today: d.toDateString() === root.today.toDateString() });
        }
        return out;
    }

    Item {
        anchors.fill: parent
        anchors.margins: 10

        PText {
            id: title
            anchors.left: parent.left
            anchors.verticalCenter: nav.verticalCenter
            anchors.right: nav.left
            text: Qt.formatDate(root.shownMonth, "MMM yyyy")
            font.bold: true
        }
        Row {
            id: nav
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 4
            PButton { icon: "chevron_left"; faceHeight: 22; offset: 2; pad: 2; iconSize: 15; checked: true; tint: Theme.pastels.pink; onClicked: root.monthOffset-- }
            PButton { icon: "chevron_right"; faceHeight: 22; offset: 2; pad: 2; iconSize: 15; checked: true; tint: Theme.pastels.green; onClicked: root.monthOffset++ }
        }

        Grid {
            id: grid
            anchors.top: nav.bottom
            anchors.topMargin: 6
            anchors.horizontalCenter: parent.horizontalCenter
            columns: 7
            readonly property real cell: Math.floor(parent.width / 7)

            Repeater {
                model: ["S", "M", "T", "W", "T", "F", "S"]
                PText {
                    required property string modelData
                    width: grid.cell; height: 18
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.sub
                    font.pixelSize: 10
                    font.bold: true
                }
            }
            Repeater {
                model: root.days
                Item {
                    required property var modelData
                    width: grid.cell
                    height: 22
                    Rectangle {
                        anchors.centerIn: parent
                        width: 21; height: 21; radius: 10.5
                        visible: parent.modelData.today
                        color: Theme.pastels.green
                        border.width: Theme.outline
                        border.color: Theme.line
                    }
                    PText {
                        anchors.centerIn: parent
                        text: parent.modelData.day
                        font.pixelSize: 10
                        font.bold: parent.modelData.today
                        color: parent.modelData.today ? Theme.onPastel : Theme.ink
                        opacity: parent.modelData.inMonth ? 1 : 0.3
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: grid
            acceptedButtons: Qt.NoButton
            onWheel: w => { root.monthOffset += w.angleDelta.y > 0 ? -1 : 1; }
        }
    }
}
