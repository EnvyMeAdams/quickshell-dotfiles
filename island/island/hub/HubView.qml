import QtQuick
import qs.services
import qs.theme
import qs.components
import qs.island.settings

Item {
    id: root

    // Tailscale only appears when it's installed.
    // Each optional tab is checked on its own: if one of them errors, only
    // that tab is skipped (and the reason goes to the log), never the row.
    readonly property var tabs: {
        const t = [
            { id: "home", icon: "home", label: "Home" },
            { id: "sound", icon: "volume_up", label: "Sound" },
            { id: "control", icon: "tune", label: "Control" },
            { id: "notifications", icon: "notifications", label: "Alerts" }
        ];
        try { if (Tailscale.installed && Config.s.tsTab) t.push({ id: "tailscale", icon: "hub", label: "Tailscale" }); }
        catch (e) { console.warn("island: Tailscale tab skipped:", e); }
        t.push({ id: "wallpaper", icon: "image", label: "Wallpaper" },
               { id: "settings", icon: "settings", label: "Settings" });
        return t;
    }

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
                    visible: {
                        if (tab.on) return false;
                        if (tab.modelData.id === "notifications") return Notifs.count > 0;
                        return false;
                    }
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 4
                    width: 8; height: 8; radius: 4
                    color: Theme.strong(Theme.pastels.pink)
                    border.width: Theme.glass ? 0 : 1
                    border.color: Theme.line
                }
            }
        }
    }

    // power button on the left; tray + battery on the right (Home only)
    readonly property bool home: Island.hubTab === "home"
    readonly property real side: (width - tabRow.width) / 2 - 14 - 10

    // one power button (every tab); the menu opens in the middle of the screen
    PButton {
        z: 5
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: tabRow.verticalCenter
        anchors.verticalCenterOffset: -1
        icon: "power_settings_new"
        tint: Theme.pastels.pink
        checked: Island.powerMenu
        onClicked: Island.openPower()
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
            tailscale: tailscaleC
        })[Island.hubTab] ?? homeC
    }

    Component { id: homeC; HomePage {} }
    Component { id: soundC; SoundPage {} }
    Component { id: controlC; ControlPage {} }
    Component { id: notifC; NotificationsPage {} }
    Component { id: wallC; WallpaperPage {} }
    Component { id: settingsC; SettingsPage {} }
    Component { id: tailscaleC; TailscalePage {} }
}
