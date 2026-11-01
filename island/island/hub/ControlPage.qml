import QtQuick
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    property bool wifiOpen: false
    readonly property real tileW: Math.floor((scroll.width - 12 - 24) / 3)

    PScroll {
        id: scroll
        anchors.fill: parent
        visible: !root.wifiOpen
        spacing: 14

        Flow {
            width: parent.width
            spacing: 12

            Tile {
                width: root.tileW
                icon: Network.kind === "ethernet" ? "lan" : (Network.wifiEnabled ? "wifi" : "wifi_off")
                title: Network.kind === "ethernet" ? "Ethernet" : "Wi-Fi"
                sub: Network.name || (Network.wifiEnabled ? "Offline" : "Off")
                active: Network.kind !== "none"
                tint: Theme.pastels.blue
                chevron: Network.hasWifi
                onClicked: if (Network.hasWifi) { root.wifiOpen = true; Network.rescan(); }
            }
            Tile {
                width: root.tileW
                visible: Bt.available
                icon: Bt.enabled ? "bluetooth" : "bluetooth_disabled"
                title: "Bluetooth"
                sub: Bt.enabled ? "On" : "Off"
                active: Bt.enabled
                tint: Theme.pastels.lilac
                onClicked: Bt.setEnabled(!Bt.enabled)
            }
            Tile {
                width: root.tileW
                icon: Config.s.dnd ? "notifications_off" : "notifications"
                title: "Focus"
                sub: Config.s.dnd ? "On" : "Off"
                active: Config.s.dnd
                tint: Theme.pastels.rose
                onClicked: Config.s.dnd = !Config.s.dnd
            }
            Tile {
                width: root.tileW
                icon: "bedtime"
                title: "Night Light"
                sub: Config.s.nightLight ? "On" : "Off"
                active: Config.s.nightLight
                tint: Theme.pastels.yellow
                onClicked: ControlActions.toggleNight()
            }
            Tile {
                width: root.tileW
                icon: Audio.micMuted ? "mic_off" : "mic"
                title: "Mic"
                sub: Audio.micMuted ? "Muted" : "On"
                active: !Audio.micMuted
                tint: Theme.pastels.green
                onClicked: Audio.toggleMic()
            }
            Tile {
                width: root.tileW
                icon: Recorder.recording ? "stop_circle" : "screen_record"
                title: Recorder.recording ? "Stop" : "Record"
                sub: Recorder.recording ? Recorder.elapsed
                   : (Config.s.recordMode === "region" ? "Region" : "Screen")
                     + (Config.s.recordMic ? " · Mic" : "") + (Config.s.recordDesktop ? " · Sound" : "")
                active: Recorder.recording
                tint: Theme.pastels.coral
                onClicked: Recorder.toggle()
            }
            Tile {
                width: root.tileW
                icon: "coffee"
                title: "Keep Awake"
                sub: Awake.keepAwake ? "On" : (Awake.reason ? "Auto · " + Awake.reason : "Off")
                active: Awake.keepAwake
                tint: Theme.pastels.butter
                onClicked: Awake.keepAwake = !Awake.keepAwake
            }
            Tile {
                width: root.tileW
                icon: "screenshot_region"
                title: "Screenshot"
                sub: "Region"
                tint: Theme.pastels.peach
                onClicked: ControlActions.screenshot()
            }
        }

        Card {
            width: parent.width
            height: sliders.implicitHeight + 28 + offset

            Column {
                id: sliders
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 14
                spacing: 12

                SliderRow {
                    width: parent.width
                    icon: Audio.icon(Audio.volume, Audio.muted)
                    value: Audio.muted ? 0 : Audio.volume
                    tint: Theme.pastels.pink
                    onMoved: v => Audio.setVolume(v)
                    onIconClicked: Audio.toggleMute()
                }
                SliderRow {
                    width: parent.width
                    visible: Brightness.available
                    icon: "light_mode"
                    value: Brightness.value
                    tint: Theme.pastels.yellow
                    onMoved: v => Brightness.set(v)
                }
            }
        }

        Row {
            width: parent.width
            spacing: 12
            readonly property real bw: Math.floor((width - 48) / 5)

            PowerButton { width: parent.bw; icon: "lock"; label: "Lock"; kind: "lock"; tint: Theme.pastels.blue }
            PowerButton { width: parent.bw; icon: "movie"; label: "Saver"; kind: "saver"; tint: Theme.pastels.green }
            PowerButton { width: parent.bw; icon: "dark_mode"; label: "Sleep"; kind: "sleep"; tint: Theme.pastels.lilac }
            PowerButton { width: parent.bw; icon: "restart_alt"; label: "Reboot"; kind: "reboot"; confirm: true; tint: Theme.pastels.peach }
            PowerButton { width: parent.bw; icon: "power_settings_new"; label: "Power"; kind: "poweroff"; confirm: true; tint: Theme.pastels.pink }
        }
    }

    WifiPanel {
        anchors.fill: parent
        visible: root.wifiOpen
        onBack: root.wifiOpen = false
    }
}
