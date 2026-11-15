import QtQuick
import qs.services
import qs.theme
import qs.components

// Linking Signal + the steps. Shown from Hub › Messages › Set Up and from
// Settings › Messages › Signal.
Column {
    id: root
    spacing: 10

    // live status
    Card {
        width: parent.width
        height: stRow.implicitHeight + 24 + offset
        fill: Signal.connected ? Theme.pastels.mint : Theme.card
        Column {
            id: stRow
            x: 14; y: 12
            width: parent.width - 28
            spacing: 2
            PText {
                font.bold: true
                color: Signal.connected ? Theme.onPastel : Theme.ink
                text: !Signal.installed ? "signal-cli: not found (" + Config.s.signalCli + " or Flatpak)"
                    : Signal.connected ? "Connected as " + Config.s.signalAccount
                    : Config.s.signalAccount ? "Linked as " + Config.s.signalAccount + (Config.s.signalOn ? "" : " · turned off")
                    : "Not linked"
            }
            PText {
                visible: Signal.installed
                text: "Using " + (Signal.kind === "flatpak" ? "the Flatpak (" + Signal.flatpakId + ")" : "signal-cli from your system")
                font.pixelSize: 11
                color: Signal.connected ? Theme.onPastel : Theme.sub
            }
            PText {
                width: parent.width
                visible: text !== "" && !Signal.connected
                text: Signal.status
                wrapMode: Text.Wrap
                font.pixelSize: 11
                color: Theme.sub
            }
        }
    }

    // linking: the QR code appears here
    Card {
        width: parent.width
        visible: !Config.s.signalAccount
        height: linkCol.implicitHeight + 28 + offset
        Column {
            id: linkCol
            x: 14; y: 14
            width: parent.width - 28
            spacing: 10
            PText {
                width: parent.width
                wrapMode: Text.Wrap
                font.pixelSize: 12
                text: !Signal.installed
                    ? "The island can't find signal-cli. It looks for \"" + Config.s.signalCli + "\" in your PATH, then the Flatpak " + Signal.flatpakId + ". Check in a terminal:\n   flatpak info " + Signal.flatpakId + "\nthen press Check Again."
                    : Signal.linking
                    ? "On your phone: Signal › Settings › Linked Devices › Link New Device, then scan this."
                    : "Links this computer to your phone's Signal, like Signal Desktop. Your messages stay end-to-end encrypted."
            }
            Image {
                visible: Signal.linkQr !== ""
                source: Signal.linkQr
                width: 220; height: 220
                fillMode: Image.PreserveAspectFit
                smooth: false
                cache: false
            }
            PText {
                visible: Signal.linkError !== ""
                width: parent.width
                wrapMode: Text.Wrap
                text: Signal.linkError
                font.pixelSize: 11
                color: Theme.danger
            }
            Row {
                spacing: 8
                PButton {
                    visible: !Signal.installed
                    text: "Check Again"
                    icon: "refresh"
                    onClicked: Signal.detect()
                }
                PButton {
                    visible: Signal.installed && !Signal.linking
                    text: "Link This Computer"
                    icon: "qr_code_2"
                    checked: true
                    tint: Theme.pastels.mint
                    onClicked: Signal.startLink()
                }
                PButton {
                    visible: Signal.linking
                    text: "Cancel"
                    icon: "close"
                    onClicked: Signal.cancelLink()
                }
            }
        }
    }

    HelpCard {
        width: parent.width
        text: "What you need (Gentoo):\n" +
              "• signal-cli, either one works:\n" +
              "   Flatpak (brings its own Java, updates quickly): flatpak install flathub org.asamk.SignalCli\n" +
              "   Gentoo: doas emerge --ask net-im/signal-cli-bin (needs a recent Java; can trail upstream)\n" +
              "   signal-cli releases older than about three months can stop working, so keep it updated.\n" +
              "• qrencode, to draw the linking code: doas emerge --ask media-gfx/qrencode\n\n" +
              "Then press Link This Computer and scan the code. The island fills in your number and turns Signal on.\n\n" +
              "How it runs: the island starts \"signal-cli daemon --socket\" itself (Settings › Messages › Signal › Start signal-cli), " +
              "so there's no service to set up. Keep it running: Signal unlinks devices that stay offline for weeks.\n\n" +
              "Privacy: signal-cli keeps its keys in " + Signal.dataDir.replace(Config.home, "~") + ", as private as Signal Desktop's folder " +
              "(your disk encryption covers it). Chats you get here are saved in ~/.local/share/island/signal-chats.json, " +
              "in a folder only you can open, so they survive restarts. Turn off Keep Chats to keep them in memory only " +
              "(that also deletes the file). Older history stays on your phone.\n\n" +
              "If you also use Signal Desktop, turn on Hide Signal Desktop Alerts so messages don't pop up twice.\n\n" +
              "To remove it: Settings › Messages › Signal › Forget Account, then remove \"Island\" under Linked Devices on your phone."
    }
}
