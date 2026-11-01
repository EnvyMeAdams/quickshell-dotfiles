import QtQuick
import QtQuick.Controls
import qs.theme

// The ONLY vertical scroller used in the island. Stops at bounds, never
// overshoots, and nothing inside it eats the wheel by default.
Flickable {
    id: root

    default property alias content: col.data
    property alias spacing: col.spacing

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    flickableDirection: Flickable.VerticalFlick
    contentWidth: width
    contentHeight: col.implicitHeight + 8
    interactive: contentHeight > height

    Column {
        id: col
        width: root.width - 12
        spacing: 10
    }

    ScrollIndicator.vertical: ScrollIndicator {
        contentItem: Rectangle {
            implicitWidth: 4
            radius: 2
            color: Theme.sub
            opacity: 0.6
        }
    }
}
