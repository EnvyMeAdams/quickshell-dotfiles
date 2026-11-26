import QtQuick
import Quickshell
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
                visible: Tailscale.installed
                icon: Tailscale.exitNode ? "vpn_lock" : "hub"
                title: "Tailscale"
                sub: !Tailscale.daemon ? "Not Running"
                   : Tailscale.state === "NeedsLogin" ? "Logged Out"
                   : !Tailscale.up ? "Off"
                   : Tailscale.exitNode ? Tailscale.flag(Tailscale.exitNode.code) + " " + (Tailscale.exitNode.city || Tailscale.exitNode.name)
                   : "On"
                active: Tailscale.up
                tint: Theme.pastels.aqua
                chevron: true
                onClicked: Island.hubTab = "tailscale"
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
                onClicked: NightLight.toggle()
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
                    icon: Brightness.icon
                    value: Brightness.value
                    tint: Theme.pastels.yellow
                    onMoved: v => Brightness.set(v)
                }
                // warmth only matters while night light is on
                SliderRow {
                    width: parent.width
                    visible: Config.s.nightLight
                    icon: "bedtime"
                    value: NightLight.warmth
                    tint: Theme.pastels.coral
                    onMoved: v => NightLight.setWarmth(v)
                    onIconClicked: NightLight.toggle()
                }
            }
        }

        // Display scaling: one row per display, the name only shows with 2+
        Card {
            width: parent.width
            height: scales.implicitHeight + 28 + offset

            Column {
                id: scales
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 14
                spacing: 10

                Row {
                    spacing: 8
                    PIcon {
                        name: "aspect_ratio"
                        size: 18
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    PText {
                        text: "Scaling"
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Repeater {
                    model: Quickshell.screens
                    delegate: Column {
                        id: disp
                        required property var modelData
                        readonly property real now: DisplayScale.current(modelData.name)
                        width: scales.width
                        spacing: 6

                        PText {
                            visible: Quickshell.screens.length > 1
                            text: disp.modelData.name
                            font.pixelSize: 11
                            opacity: 0.7
                        }
                        Flow {
                            width: parent.width
                            spacing: 6
                            Repeater {
                                model: DisplayScale.options
                                delegate: PButton {
                                    required property real modelData
                                    text: DisplayScale.label(modelData)
                                    faceHeight: 28
                                    offset: 3
                                    pad: 10
                                    checked: Math.abs(disp.now - modelData) < 0.01
                                    tint: Theme.pastels.blue
                                    onClicked: DisplayScale.set(disp.modelData.name, modelData)
                                }
                            }
                        }
                    }
                }
            }
        }

    }

    WifiPanel {
        anchors.fill: parent
        visible: root.wifiOpen
        onBack: root.wifiOpen = false
    }
}
