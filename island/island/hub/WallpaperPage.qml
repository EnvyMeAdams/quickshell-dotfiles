import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.components

// Desktop (photo or video, per display), Lock (photo or video), Saver (video).
// Click a folder to walk in, a thumbnail to apply. Wheel scrolls sideways.
Item {
    id: root

    property string target: "desktop"                 // desktop | lock | saver
    property string display: "*"                      // desktop only
    property string kind: "photo"
    readonly property string effKind: target === "saver" ? "video" : kind
    readonly property string homeDir: Config.expand(effKind === "photo" ? Config.s.photoDir : Config.s.videoDir)
    property string browse: homeDir
    property bool thumbsReady: false
    readonly property string thumbDir: Config.home + "/.cache/island/thumbs"

    readonly property string currentPath: target === "lock" ? Config.s.lockBg
        : target === "saver" ? Config.s.saverVideo
        : (Wallpaper.current(display)?.path ?? "")

    Component.onCompleted: {
        const cur = Wallpaper.current("*");
        if (cur?.kind === "video") kind = "video";
        pathField.text = browse.replace(Config.home, "~");
        makeThumbs();
    }
    onHomeDirChanged: browse = homeDir
    onBrowseChanged: { pathField.text = browse.replace(Config.home, "~"); makeThumbs(); }

    function pick(path) {
        if (target === "desktop") Wallpaper.apply(path, effKind, display);
        else if (target === "lock") Wallpaper.setLock(path, effKind);
        else Wallpaper.setSaver(path);
    }

    function makeThumbs() {
        if (effKind !== "video") return;
        thumbsReady = false;
        thumber.running = false;
        thumber.command = ["sh", "-c",
            "command -v ffmpegthumbnailer >/dev/null || exit 0; d=\"$2\"; mkdir -p \"$d\"; " +
            "for f in \"$1\"/*; do case \"$f\" in *.mp4|*.MP4|*.mkv|*.MKV|*.webm|*.WEBM|*.mov|*.MOV) " +
            "t=\"$d/$(basename \"$f\").jpg\"; [ -f \"$t\" ] || ffmpegthumbnailer -i \"$f\" -o \"$t\" -s 480 -q 6 >/dev/null 2>&1;; esac; done",
            "sh", browse, thumbDir];
        thumber.running = true;
    }
    Process { id: thumber; onExited: root.thumbsReady = true }

    FolderListModel {
        id: folder
        folder: "file://" + root.browse
        showDirs: true
        showDirsFirst: true
        showDotAndDotDot: false
        showHidden: false
        caseSensitive: false
        sortField: FolderListModel.Name
        nameFilters: root.effKind === "photo" ? ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.bmp"]
                                              : ["*.mp4", "*.mkv", "*.webm", "*.mov", "*.m4v", "*.avi"]
    }

    // ── row 1: where it goes + photo/video ──
    Row {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        spacing: 8
        PButton { icon: "desktop_windows"; text: "Desktop"; checked: root.target === "desktop"; tint: Theme.pastels.peach; onClicked: root.target = "desktop" }
        PButton { icon: "lock"; text: "Lock"; checked: root.target === "lock"; tint: Theme.pastels.blue; onClicked: root.target = "lock" }
        PButton { icon: "movie"; text: "Saver"; checked: root.target === "saver"; tint: Theme.pastels.green; onClicked: root.target = "saver" }
    }
    Row {
        anchors.top: parent.top
        anchors.right: parent.right
        spacing: 8
        visible: root.target !== "saver"
        PButton { icon: "photo"; text: "Photos"; checked: root.kind === "photo"; tint: Theme.pastels.rose; onClicked: root.kind = "photo" }
        PButton { icon: "videocam"; text: "Videos"; checked: root.kind === "video"; tint: Theme.pastels.lilac; onClicked: root.kind = "video" }
    }

    // ── row 2: display (desktop) or reset (lock) ──
    readonly property bool showDisplays: target === "desktop" && Wallpaper.displays.length > 1
    readonly property bool showReset: target === "lock" && Config.s.lockBg !== ""

    Row {
        id: subBar
        anchors.top: topBar.bottom
        anchors.topMargin: visible ? 10 : 0
        anchors.left: parent.left
        spacing: 6
        visible: root.showDisplays || root.showReset
        height: visible ? implicitHeight : 0

        Repeater {
            model: root.showDisplays ? ["*"].concat(Wallpaper.displays) : []
            delegate: PButton {
                required property string modelData
                text: modelData === "*" ? "All" : modelData
                faceHeight: 26
                offset: 3
                checked: root.display === modelData
                tint: Theme.pastels.yellow
                onClicked: root.display = modelData
            }
        }
        PButton {
            visible: root.showReset
            icon: "undo"
            text: "Use Desktop"
            faceHeight: 26
            offset: 3
            onClicked: Wallpaper.setLock("", "photo")
        }
    }

    Chip {
        z: 5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.effKind === "video" && !Wallpaper.videoOk
        text: "Videos need Qt Multimedia"
        fill: Theme.pastels.pink
    }

    // ── row 3: folder ──
    PField {
        id: pathField
        anchors.top: subBar.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: folderBtns.left
        anchors.rightMargin: 8
        icon: "folder"
        placeholder: "Folder"
        onAccepted: root.browse = Config.expand(text.trim())
    }
    Row {
        id: folderBtns
        anchors.right: parent.right
        anchors.verticalCenter: pathField.verticalCenter
        anchors.verticalCenterOffset: 2
        spacing: 6
        PButton { icon: "arrow_upward"; onClicked: root.browse = root.browse.replace(/\/[^/]+\/?$/, "") || "/" }
        PButton { icon: "home"; onClicked: root.browse = root.homeDir }
        PButton {
            icon: "keep"
            text: "Set"
            visible: root.browse !== root.homeDir
            onClicked: {
                const p = root.browse.replace(Config.home, "~");
                if (root.effKind === "photo") Config.s.photoDir = p; else Config.s.videoDir = p;
            }
        }
    }

    ListView {
        id: list
        anchors.top: pathField.bottom
        anchors.topMargin: 14
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        orientation: ListView.Horizontal
        spacing: 14
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: folder

        WheelHandler {
            target: null
            onWheel: ev => {
                const d = ev.angleDelta.y !== 0 ? ev.angleDelta.y : ev.angleDelta.x;
                const max = Math.max(0, list.contentWidth - list.width);
                list.contentX = Math.max(list.originX, Math.min(list.originX + max, list.contentX - d));
            }
        }

        delegate: Card {
            id: tile
            required property string fileName
            required property string filePath
            required property bool fileIsDir
            readonly property bool current: filePath === root.currentPath

            width: 240 + offset
            height: list.height - 6
            fill: current ? Theme.accent : (area.containsMouse ? Theme.hover : Theme.card)
            pressed: area.pressed && Config.s.pressEffect

            ClippingRectangle {
                id: thumb
                x: 10; y: 10
                width: parent.width - 20
                height: parent.height - 52
                radius: 12
                color: Theme.sunk

                Image {
                    id: img
                    anchors.fill: parent
                    visible: !tile.fileIsDir
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize: Qt.size(480, 300)
                    source: tile.fileIsDir ? ""
                          : root.effKind === "photo" ? "file://" + tile.filePath
                          : root.thumbsReady ? "file://" + root.thumbDir + "/" + tile.fileName + ".jpg" : ""
                }
                PIcon {
                    anchors.centerIn: parent
                    visible: tile.fileIsDir || img.status !== Image.Ready
                    name: tile.fileIsDir ? "folder" : (root.effKind === "video" ? "movie" : "image")
                    size: 42
                    color: Theme.sub
                }
            }
            Rectangle {
                anchors.fill: thumb
                radius: thumb.radius
                color: "transparent"
                border.width: Theme.outline
                border.color: Theme.line
            }
            Chip {
                visible: tile.current
                anchors.top: thumb.top
                anchors.right: thumb.right
                anchors.margins: 8
                text: "✓"
                fill: Theme.pastels.green
            }

            PText {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 12
                text: tile.fileName
                font.bold: tile.current
                color: tile.current ? Theme.onPastel : Theme.ink
                font.pixelSize: 12
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (tile.fileIsDir) root.browse = tile.filePath;
                    else root.pick(tile.filePath);
                }
            }
        }

        PText {
            anchors.centerIn: parent
            visible: folder.count === 0
            width: list.width - 40
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            text: "No " + (root.effKind === "photo" ? "photos" : "videos") + " in " + root.browse.replace(Config.home, "~")
            color: Theme.sub
        }
    }
}
