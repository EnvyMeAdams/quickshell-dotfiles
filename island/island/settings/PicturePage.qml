import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.components

// Profile picture browser: folders and photo thumbnails, starts in ~/Pictures.
Item {
    id: page

    property string browse: {
        const cur = Config.expand(Config.s.avatar);
        return cur ? cur.replace(/\/[^/]*$/, "") : Config.home + "/Pictures";
    }
    readonly property string current: Config.expand(Config.s.avatar) || Config.home + "/.face"

    Component.onCompleted: pathField.text = browse.replace(Config.home, "~")
    onBrowseChanged: pathField.text = browse.replace(Config.home, "~")

    FolderListModel {
        id: folder
        folder: "file://" + page.browse
        showDirs: true
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: false
        caseSensitive: false
        sortField: FolderListModel.Name
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.bmp"]
    }

    // header
    Row {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        spacing: 10
        PButton { icon: "arrow_back"; onClicked: page.StackView.view.pop() }
        Avatar {
            width: 34; height: 34
            anchors.verticalCenter: parent.verticalCenter
            source: "file://" + page.current
            letter: Config.s.userName || "?"
            fill: Theme.pastels.blue
        }
        PText { text: "Picture"; font.bold: true; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
    }
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        spacing: 6
        PButton { icon: "arrow_upward"; onClicked: page.browse = page.browse.replace(/\/[^/]+\/?$/, "") || "/" }
        PButton { icon: "photo_library"; onClicked: page.browse = Config.home + "/Pictures" }
        PButton {
            icon: "undo"
            text: "Reset"
            visible: Config.s.avatar !== ""
            onClicked: Config.s.avatar = ""
        }
    }

    PField {
        id: pathField
        anchors.top: header.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        icon: "folder"
        placeholder: "Folder"
        onAccepted: page.browse = Config.expand(text.trim())
    }

    GridView {
        id: grid
        anchors.top: pathField.bottom
        anchors.topMargin: 14
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        readonly property int cols: Math.max(1, Math.floor(width / 130))
        cellWidth: Math.floor(width / cols)
        cellHeight: cellWidth + 22
        model: folder
        ScrollIndicator.vertical: ScrollIndicator {}

        delegate: Item {
            id: cell
            required property string fileName
            required property string filePath
            required property bool fileIsDir
            readonly property bool picked: !fileIsDir && filePath === page.current
            width: grid.cellWidth
            height: grid.cellHeight

            Card {
                anchors.fill: parent
                anchors.margins: 5
                fill: cell.picked ? Theme.accent : (area.containsMouse ? Theme.hover : Theme.card)
                pressed: area.pressed && Config.s.pressEffect

                // photos are previewed as circles, like the real avatar
                Item {
                    id: thumb
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: 10
                    width: parent.width - 28
                    height: width

                    Avatar {
                        anchors.fill: parent
                        visible: !cell.fileIsDir
                        source: cell.fileIsDir ? "" : "file://" + cell.filePath
                        letter: cell.fileName
                        fill: Theme.sunk
                    }
                    Rectangle {
                        anchors.fill: parent
                        visible: cell.fileIsDir
                        radius: 14
                        color: Theme.sunk
                        border.width: Theme.outline
                        border.color: Theme.line
                        PIcon { anchors.centerIn: parent; name: "folder"; size: 38; color: Theme.sub }
                    }
                }
                PText {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 8
                    horizontalAlignment: Text.AlignHCenter
                    text: cell.fileName
                    font.pixelSize: 11
                    font.bold: cell.picked
                    color: cell.picked ? Theme.onPastel : Theme.ink
                }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (cell.fileIsDir) page.browse = cell.filePath;
                        else Config.s.avatar = cell.filePath.replace(Config.home, "~");
                    }
                }
            }
        }

        PText {
            anchors.centerIn: parent
            visible: folder.count === 0
            text: "No photos in " + page.browse.replace(Config.home, "~")
            color: Theme.sub
        }
    }
}
