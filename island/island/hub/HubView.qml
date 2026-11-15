import QtQuick
import qs.services
import qs.theme
import qs.components
import qs.island.settings

Item {
    id: root

    // Messages and Tailscale only appear when they have something to show
    readonly property var tabs: [
        { id: "home", icon: "home", label: "Home" },
        { id: "sound", icon: "volume_up", label: "Sound" },
        { id: "control", icon: "tune", label: "Control" },
        { id: "notifications", icon: "notifications", label: "Alerts" }
    ].concat(Messages.available ? [{ id: "messages", icon: "chat", label: "Messages" }] : [])
     .concat(Tailscale.installed && Config.s.tsTab ? [{ id: "tailscale", icon: "hub", label: "Tailscale" }] : [])
     .concat([
        { id: "wallpaper", icon: "image", label: "Wallpaper" },
        { id: "settings", icon: "settings", label: "Settings" }
    ])

    Row {
        id: tabRow
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Repeater {
            model: root.tabs
            delegate: PButton {
                id: tab
                required property var modelData
                required property int index
                readonly property bool on: Island.hubTab === modelData.id
                icon: modelData.icon
                text: on ? modelData.label : ""
                checked: on
                tint: Theme.cycle[index % Theme.cycle.length]
                onClicked: Island.hubTab = modelData.id

                Rectangle {
                    // `tab`, not `parent`: PButton puts its children in an inner item
                    visible: !tab.on && ((tab.modelData.id === "notifications" && Notifs.count > 0)
                                      || (tab.modelData.id === "messages" && Messages.unread > 0))
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 4
                    width: 8; height: 8; radius: 4
                    color: Theme.pastels.pink
                    border.width: 1
                    border.color: Theme.line
                }
            }
        }
    }

    // Home only: power buttons on the left, tray + battery on the right
    readonly property bool home: Island.hubTab === "home"
    readonly property real side: (width - tabRow.width) / 2 - 14 - 10

    PowerBar {
        z: 5
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: tabRow.verticalCenter
        anchors.verticalCenterOffset: -1
        opacity: root.home ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(160) } }
    }
    StatusBar {
        z: 5
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: tabRow.verticalCenter
        anchors.verticalCenterOffset: -1
        maxWidth: root.side
        opacity: root.home ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(160) } }
    }

    Loader {
        anchors.top: tabRow.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.bottomMargin: 14
        sourceComponent: ({
            home: homeC, sound: soundC, control: controlC,
            notifications: notifC, wallpaper: wallC, settings: settingsC,
            messages: messagesC, tailscale: tailscaleC
        })[Island.hubTab] ?? homeC
    }

    Component { id: homeC; HomePage {} }
    Component { id: soundC; SoundPage {} }
    Component { id: controlC; ControlPage {} }
    Component { id: notifC; NotificationsPage {} }
    Component { id: wallC; WallpaperPage {} }
    Component { id: settingsC; SettingsPage {} }
    Component { id: messagesC; MessagesPage {} }
    Component { id: tailscaleC; TailscalePage {} }
}
