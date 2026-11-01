import QtQuick
import qs.services
import qs.theme
import qs.components
import qs.island.settings

Item {
    id: root

    readonly property var tabs: [
        { id: "home", icon: "home", label: "Home" },
        { id: "sound", icon: "volume_up", label: "Sound" },
        { id: "control", icon: "tune", label: "Control" },
        { id: "notifications", icon: "notifications", label: "Alerts" },
        { id: "wallpaper", icon: "image", label: "Wallpaper" },
        { id: "settings", icon: "settings", label: "Settings" }
    ]

    Row {
        id: tabRow
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Repeater {
            model: root.tabs
            delegate: PButton {
                required property var modelData
                required property int index
                readonly property bool on: Island.hubTab === modelData.id
                icon: modelData.icon
                text: on ? modelData.label : ""
                checked: on
                tint: Theme.cycle[index % Theme.cycle.length]
                onClicked: Island.hubTab = modelData.id

                Rectangle {
                    visible: parent.modelData.id === "notifications" && Notifs.count > 0 && !parent.on
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
            notifications: notifC, wallpaper: wallC, settings: settingsC
        })[Island.hubTab] ?? homeC
    }

    Component { id: homeC; HomePage {} }
    Component { id: soundC; SoundPage {} }
    Component { id: controlC; ControlPage {} }
    Component { id: notifC; NotificationsPage {} }
    Component { id: wallC; WallpaperPage {} }
    Component { id: settingsC; SettingsPage {} }
}
