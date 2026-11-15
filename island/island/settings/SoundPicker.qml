import QtQuick
import QtQuick.Controls
import Qt.labs.folderlistmodel
import qs.services
import qs.theme
import qs.components

// Sound browser for one event: folders and audio files, starts where the
// current sound is (else Settings > Sounds > Sound Folder).
// Click a file to use it (and hear it); ▶ previews without choosing.
Item {
    id: page

    property string event: ""           // Sounds.events key, e.g. "lock"
    property string title: ""
    readonly property string current: Config.expand(Sounds.fileFor(event))

    property string browse: current ? current.replace(/\/[^/]*$/, "") : (Config.expand(Config.s.soundDir) || Config.home)

    Component.onCompleted: pathField.text = browse.replace(Config.home, "~")
    onBrowseChanged: pathField.text = browse.replace(Config.home, "~")
    StackView.onRemoved: Sounds.stopAll()

    FolderListModel {
        id: folder
        folder: "file://" + page.browse
        showDirs: true
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: false
        caseSensitive: false
        sortField: FolderListModel.Name
        nameFilters: Sounds.formats
    }

    // header
    Row {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        spacing: 10
        PButton { icon: "arrow_back"; onClicked: page.StackView.view.pop() }
        PText { text: page.title; font.bold: true; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
    }
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        spacing: 6
        PButton { icon: "arrow_upward"; onClicked: page.browse = page.browse.replace(/\/[^/]+\/?$/, "") || "/" }
        PButton { icon: "library_music"; onClicked: page.browse = Config.expand(Config.s.soundDir) || Config.home }
        PButton {
            icon: "volume_off"
            text: "None"
            checked: page.current === ""
            onClicked: { Sounds.stopAll(); Sounds.setFile(page.event, ""); }
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

    ListView {
        id: list
        anchors.top: pathField.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds
        model: folder
        ScrollIndicator.vertical: ScrollIndicator {}

        delegate: Card {
            id: row
            required property string fileName
            required property string filePath
            required property bool fileIsDir
            readonly property bool picked: !fileIsDir && filePath === page.current
            width: list.width
            height: 48 + offset
            radius: 16
            fill: picked ? Theme.accent : (area.containsMouse ? Theme.hover : Theme.card)
            pressed: area.pressed && Config.s.pressEffect

            PIcon {
                id: kind
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                name: row.fileIsDir ? "folder" : row.picked ? "check_circle" : "music_note"
                size: 20
                color: row.picked ? Theme.onPastel : Theme.sub
            }
            PText {
                anchors.left: kind.right
                anchors.leftMargin: 12
                anchors.right: play.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: row.fileName
                font.bold: row.picked
                color: row.picked ? Theme.onPastel : Theme.ink
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (row.fileIsDir) { page.browse = row.filePath; return; }
                    Sounds.setFile(page.event, row.filePath);
                    Sounds.playFile(row.filePath);
                }
            }
            PButton {
                id: play
                visible: !row.fileIsDir
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                icon: "play_arrow"
                faceHeight: 30
                offset: 3
                pad: 4
                onClicked: Sounds.playFile(row.filePath)
            }
        }

        PText {
            anchors.centerIn: parent
            visible: folder.count === 0
            text: "No sounds in " + page.browse.replace(Config.home, "~")
            color: Theme.sub
        }
    }
}
