import QtQuick
import QtQuick.Controls
import qs.theme
import qs.components

// One iOS-style settings page: back button, title, scrolling rows.
Item {
    id: page

    property string title: ""
    default property alias content: rows.data

    Row {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        spacing: 10
        PButton {
            icon: "arrow_back"
            onClicked: page.StackView.view.pop()
        }
        PText {
            text: page.title
            font.bold: true
            font.pixelSize: 16
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    Flickable {
        id: flick
        anchors.top: header.bottom
        anchors.topMargin: 14
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        contentWidth: width
        contentHeight: rows.implicitHeight + 8
        interactive: contentHeight > height

        Column {
            id: rows
            width: flick.width - 12
            spacing: 8
        }

        ScrollIndicator.vertical: ScrollIndicator {
            contentItem: Rectangle { implicitWidth: 4; radius: 2; color: Theme.sub; opacity: 0.6 }
        }
    }
}
