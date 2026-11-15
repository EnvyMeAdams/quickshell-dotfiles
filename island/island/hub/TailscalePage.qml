import QtQuick
import qs.services
import qs.theme
import qs.components
import qs.island.settings

// Hub › Tailscale: connect, your devices, exit nodes (Mullvad too), options.
Item {
    id: root

    property string section: "devices"      // devices | exit | options
    property bool helpOpen: false
    property string openCountry: ""
    readonly property string q: search.text.trim().toLowerCase()
    readonly property color aqua: Theme.pastels.aqua      // a real color, so .r/.g/.b work

    Component.onCompleted: { Tailscale.watching = true; Tailscale.refresh(); }
    Component.onDestruction: Tailscale.watching = false

    // ── header: status + the big switch ──
    Card {
        id: head
        visible: !root.helpOpen
        width: parent.width
        height: 66 + offset
        fill: Tailscale.up ? Qt.tint(Theme.card, Qt.rgba(root.aqua.r, root.aqua.g, root.aqua.b, 0.45)) : Theme.card

        Rectangle {
            id: bubble
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            width: 38; height: 38; radius: 19
            color: Tailscale.up ? Theme.pastels.aqua : Theme.sunk
            border.width: Theme.outline
            border.color: Theme.line
            PIcon {
                anchors.centerIn: parent
                name: Tailscale.exitNode ? "vpn_lock" : "hub"
                size: 20
                color: Tailscale.up ? Theme.onPastel : Theme.ink
            }
        }
        Column {
            anchors.left: bubble.right
            anchors.leftMargin: 12
            anchors.right: right.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            PText { width: parent.width; text: "Tailscale"; font.bold: true; font.pixelSize: 15 }
            PText {
                width: parent.width
                font.pixelSize: 11
                color: Theme.sub
                text: !Tailscale.daemon ? "Not Running"
                    : Tailscale.busy ? "Working…"
                    : Tailscale.state === "NeedsLogin" ? "Logged Out"
                    : Tailscale.state === "NeedsMachineAuth" ? "Waiting for Approval"
                    : !Tailscale.up ? "Disconnected"
                    : (Tailscale.exitNode ? "via " + Tailscale.flag(Tailscale.exitNode.code) + " " + (Tailscale.place(Tailscale.exitNode) || Tailscale.exitNode.name)
                                          : "Connected") + (Tailscale.tailnet ? " · " + Tailscale.tailnet : "")
            }
        }
        Row {
            id: right
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            PButton {
                visible: Tailscale.up && (Tailscale.self.ips?.length ?? 0) > 0
                text: Tailscale.self.ips?.[0] ?? ""
                icon: "content_copy"
                iconSize: 14
                faceHeight: 28
                offset: 3
                onClicked: Tailscale.copy(Tailscale.self.ips[0])
            }
            PButton {
                visible: Tailscale.daemon && (Tailscale.state === "NeedsLogin" || Tailscale.state === "NoState")
                text: "Log In"
                icon: "login"
                checked: true
                tint: Theme.pastels.aqua
                faceHeight: 30
                onClicked: Tailscale.login()
            }
            PButton {
                visible: !Tailscale.daemon || !Tailscale.isOperator
                text: "Set Up"
                icon: "help"
                faceHeight: 30
                tint: Theme.pastels.yellow
                checked: true
                onClicked: root.helpOpen = true
            }
            Item {
                width: sw.width; height: sw.height
                visible: Tailscale.daemon && Tailscale.state !== "NeedsLogin"
                anchors.verticalCenter: parent.verticalCenter
                PToggle {
                    id: sw
                    checked: Tailscale.up
                    tint: Theme.pastels.aqua
                    opacity: Tailscale.busy ? 0.45 : 1
                    onToggled: if (!Tailscale.busy) Tailscale.toggle()
                }
                PIcon {
                    anchors.centerIn: parent
                    visible: Tailscale.busy
                    name: "progress_activity"
                    size: 16
                    RotationAnimation on rotation { running: Tailscale.busy; loops: Animation.Infinite; from: 0; to: 360; duration: 900 }
                }
            }
        }
    }

    // ── problems, one line ──
    Card {
        id: errCard
        visible: !root.helpOpen && Tailscale.error !== ""
        anchors.top: head.bottom
        anchors.topMargin: 10
        width: parent.width
        height: visible ? 38 + offset : 0
        fill: Theme.pastels.pink
        PText {
            x: 14
            width: parent.width - 28
            anchors.verticalCenter: parent.verticalCenter
            text: Tailscale.error
            font.pixelSize: 12
            color: Theme.onPastel
        }
    }

    // ── section chips ──
    Row {
        id: tabs
        visible: !root.helpOpen && Tailscale.daemon
        anchors.top: errCard.visible ? errCard.bottom : head.bottom
        anchors.topMargin: 12
        spacing: 8
        Repeater {
            model: [
                { id: "devices", l: "Devices", i: "devices" },
                { id: "exit", l: "Exit Node", i: "public" },
                { id: "options", l: "Options", i: "tune" }
            ]
            delegate: PButton {
                required property var modelData
                text: modelData.l
                icon: modelData.i
                faceHeight: 30
                offset: 3
                checked: root.section === modelData.id
                tint: Theme.pastels.aqua
                onClicked: { root.section = modelData.id; if (modelData.id === "exit") Tailscale.findSuggestion(); }
            }
        }
    }
    PField {
        id: search
        visible: !root.helpOpen && root.section === "exit" && Tailscale.hasMullvad
        anchors.right: parent.right
        anchors.verticalCenter: tabs.verticalCenter
        width: 220
        height: 32
        icon: "search"
        placeholder: "Country or City"
    }

    PScroll {
        visible: !root.helpOpen && Tailscale.daemon
        anchors.top: tabs.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 8

        // ── Devices ──
        PText {
            visible: root.section === "devices" && Tailscale.peers.length === 0
            text: Tailscale.up ? "No Other Devices" : "Connect to See Your Devices"
            color: Theme.sub
        }
        Repeater {
            model: root.section === "devices" ? Tailscale.peers : []
            delegate: TsRow {
                required property var modelData
                width: parent ? parent.width : 0
                node: modelData
                icon: modelData.os === "android" || modelData.os === "iOS" ? "smartphone"
                    : modelData.os === "linux" ? "computer" : modelData.os === "windows" ? "desktop_windows"
                    : modelData.os === "macOS" ? "laptop_mac" : "devices"
                title: modelData.name
                sub: (modelData.ips[0] ?? "") + (modelData.online ? "" : (Tailscale.seen(modelData.lastSeen) ? " · seen " + Tailscale.seen(modelData.lastSeen) : " · offline"))
                    + (modelData.exit ? " · exit node" : "")
                tint: Theme.pastels.aqua
                active: modelData.exit
                buttons: [
                    { i: "content_copy", t: "IP", act: () => Tailscale.copy(modelData.ips[0] ?? "") },
                    { i: "dns", t: "Name", act: () => Tailscale.copy(modelData.dns) }
                ]
            }
        }

        // ── Exit node ──
        TsRow {
            visible: root.section === "exit" && root.q === ""
            width: parent.width
            icon: "block"
            title: "None"
            sub: "Traffic goes straight out"
            active: !Tailscale.exitNode
            tint: Theme.pastels.aqua
            onPicked: Tailscale.useExit(null)
        }
        SectionLabel { visible: root.section === "exit" && root.q === "" && mineExit.count > 0; text: "Your Devices" }
        Repeater {
            id: mineExit
            model: root.section === "exit" && root.q === "" ? Tailscale.peers.filter(p => p.exitOption) : []
            delegate: TsRow {
                required property var modelData
                width: parent ? parent.width : 0
                node: modelData
                icon: "router"
                title: modelData.name
                sub: modelData.online ? "Online" : "Offline"
                active: modelData.exit
                dim: !modelData.online
                tint: Theme.pastels.aqua
                onPicked: Tailscale.useExit(modelData)
            }
        }

        // Mullvad: suggested, then countries that open into servers
        SectionLabel { visible: root.section === "exit" && Tailscale.hasMullvad; text: "Mullvad" }
        TsRow {
            readonly property var hit: Tailscale.mullvad.find(m => m.dns === Tailscale.suggested || m.name === Tailscale.suggested.split(".")[0]) ?? null
            visible: root.section === "exit" && root.q === "" && hit !== null
            width: parent.width
            node: hit
            icon: "auto_awesome"
            title: "Suggested · " + Tailscale.flag(hit?.code ?? "") + " " + Tailscale.place(hit)
            sub: hit?.name ?? ""
            active: hit !== null && (Tailscale.exitNode?.id === hit.id)
            tint: Theme.pastels.lavender
            onPicked: Tailscale.useExit(hit)
        }
        Toggle {
            visible: root.section === "exit" && Tailscale.exitNode !== null
            label: "Allow LAN Access"
            hint: "Keep reaching your NAS, router and printer while on an exit node"
            on: !!Tailscale.prefs.ExitNodeAllowLANAccess
            onFlip: Tailscale.setPref("exit-node-allow-lan-access", !on)
        }
        Repeater {
            model: {
                if (root.section !== "exit") return [];
                // one row per country (or per server while searching)
                if (root.q !== "") return Tailscale.mullvad.filter(m =>
                    (m.country + " " + m.city + " " + m.code + " " + m.name).toLowerCase().includes(root.q)).slice(0, 60)
                    .map(m => ({ server: m }));
                const byC = {};
                for (const m of Tailscale.mullvad) (byC[m.country] = byC[m.country] || []).push(m);
                const out = [];
                for (const c of Object.keys(byC).sort()) {
                    out.push({ country: c, list: byC[c] });
                    if (root.openCountry === c) byC[c].forEach(m => out.push({ server: m, nested: true }));
                }
                return out;
            }
            delegate: TsRow {
                required property var modelData
                readonly property var s: modelData.server ?? null
                readonly property bool here: s ? Tailscale.exitNode?.id === s.id
                                               : (!!Tailscale.exitNode?.code && Tailscale.exitNode.country === modelData.country)
                width: parent ? parent.width - (modelData.nested ? 24 : 0) : 0
                x: modelData.nested ? 24 : 0
                node: s
                emoji: Tailscale.flag(s ? s.code : modelData.list[0].code)
                title: s ? (s.city || s.country) : modelData.country
                sub: s ? s.name + (s.online ? "" : " · offline")
                       : modelData.list.length + (modelData.list.length === 1 ? " server" : " servers")
                         + (here ? " · in use" : "")
                active: here
                dim: s ? !s.online : false
                chevron: !s
                open: !s && root.openCountry === modelData.country
                tint: Theme.pastels.lavender
                onPicked: {
                    if (s) Tailscale.useExit(s);
                    else root.openCountry = root.openCountry === modelData.country ? "" : modelData.country;
                }
            }
        }
        PText {
            visible: root.section === "exit" && !Tailscale.hasMullvad && mineExit.count === 0 && root.q === ""
            width: parent.width
            wrapMode: Text.Wrap
            text: "No exit nodes on your tailnet yet. Turn on Advertise as Exit Node on a device (Options), or add Mullvad to your tailnet."
            color: Theme.sub
            font.pixelSize: 12
        }

        // ── Options ──
        Toggle { visible: root.section === "options"; label: "Use Tailscale DNS"; hint: "MagicDNS names; turn off if Pi-hole should answer"; on: !!Tailscale.prefs.CorpDNS; onFlip: Tailscale.setPref("accept-dns", !on) }
        Toggle { visible: root.section === "options"; label: "Accept Routes"; hint: "Reach subnets other devices share"; on: !!Tailscale.prefs.RouteAll; onFlip: Tailscale.setPref("accept-routes", !on) }
        Toggle { visible: root.section === "options"; label: "Shields Up"; hint: "Block incoming connections from your tailnet"; on: !!Tailscale.prefs.ShieldsUp; onFlip: Tailscale.setPref("shields-up", !on) }
        Toggle { visible: root.section === "options"; label: "Advertise as Exit Node"; hint: "Let your other devices route through this one"; on: Tailscale.advertisingExit; onFlip: Tailscale.setPref("advertise-exit-node", !on) }
        Toggle { visible: root.section === "options"; label: "Save Taildrop Files"; hint: "Files sent here go to " + Config.s.tsTaildropDir; on: Config.s.tsTaildrop; onFlip: Config.s.tsTaildrop = !Config.s.tsTaildrop }
        TsRow {
            visible: root.section === "options" && Tailscale.user !== ""
            width: parent.width
            icon: "account_circle"
            title: Tailscale.user
            sub: Tailscale.self.name + (Tailscale.self.dns ? " · " + Tailscale.self.dns : "")
            tint: Theme.pastels.aqua
            buttons: [{ i: "logout", t: "Log Out", act: () => Tailscale.run(["logout"]) }]
        }
    }

    // not running / not installed right: what to do (own panel, not inline)
    Item {
        anchors.fill: parent
        visible: root.helpOpen || !Tailscale.daemon
        Row {
            id: helpHead
            spacing: 10
            PButton { visible: root.helpOpen; icon: "arrow_back"; onClicked: root.helpOpen = false }
            PText { text: root.helpOpen ? "Set Up Tailscale" : ""; font.bold: true; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
        }
        PScroll {
            visible: root.helpOpen
            anchors.top: helpHead.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            TsHelp { width: parent.width }
        }
        PText {
            visible: !root.helpOpen && !Tailscale.daemon
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 30
            text: "tailscaled isn't running. Set Up shows how to start it."
            color: Theme.sub
        }
    }

    // ── small pieces ──
    component SectionLabel: PText {
        topPadding: 6
        font.bold: true
        font.pixelSize: 12
        color: Theme.sub
    }

    component Toggle: Card {
        id: tg
        property string label: ""
        property string hint: ""
        property bool on: false
        signal flip()
        width: parent ? parent.width : 0
        height: 54 + offset
        Column {
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 100
            PText { width: parent.width; text: tg.label; font.bold: true }
            PText { width: parent.width; text: tg.hint; visible: text !== ""; font.pixelSize: 11; color: Theme.sub }
        }
        PToggle {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            checked: tg.on
            tint: Theme.pastels.aqua
            opacity: Tailscale.busy ? 0.45 : 1
            onToggled: if (!Tailscale.busy) tg.flip()
        }
    }
}
