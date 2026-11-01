import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 14
        orientation: ListView.Horizontal
        spacing: 10
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: Windows.list
        currentIndex: Windows.index
        highlightMoveDuration: 120
        preferredHighlightBegin: width / 2 - 70
        preferredHighlightEnd: width / 2 + 70
        highlightRangeMode: ListView.ApplyRange

        delegate: Card {
            id: tile
            required property var modelData
            required property int index
            readonly property bool sel: index === Windows.index

            width: 140 + offset
            height: list.height
            offset: sel ? Theme.shadow : 2
            fill: sel ? Theme.accent : (area.containsMouse ? Theme.hover : Theme.card)

            IconImage {
                id: ic
                anchors.horizontalCenter: parent.horizontalCenter
                y: 16
                implicitSize: 48
                source: Quickshell.iconPath(DesktopEntries.heuristicLookup(Windows.appId(tile.modelData))?.icon ?? Windows.appId(tile.modelData), "application-x-executable")
            }
            PText {
                anchors.top: ic.bottom
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                horizontalAlignment: Text.AlignHCenter
                text: Windows.title(tile.modelData)
                font.pixelSize: 11
                font.bold: tile.sel
                color: tile.sel ? Theme.onPastel : Theme.ink
            }
            Chip {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                text: Windows.where(tile.modelData)
                visible: text !== ""
                size: 18
                fontSize: 9
                fill: Theme.card
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Windows.pick(tile.index)
            }
        }
    }

    PText {
        anchors.centerIn: parent
        visible: list.count === 0
        text: "No Windows"
        color: Theme.sub
    }
}
