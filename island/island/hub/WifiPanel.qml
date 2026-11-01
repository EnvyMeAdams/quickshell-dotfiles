import QtQuick
import qs.services
import qs.theme
import qs.components

Item {
    id: root

    signal back()

    Row {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        PButton { icon: "arrow_back"; onClicked: root.back() }
        PText { text: "Wi-Fi"; font.bold: true; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
    }
    Row {
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 10
        PButton {
            icon: "refresh"
            text: Network.scanning ? "…" : "Scan"
            onClicked: Network.rescan()
        }
        PToggle {
            anchors.verticalCenter: parent.verticalCenter
            checked: Network.wifiEnabled
            tint: Theme.pastels.blue
            onToggled: Network.setWifi(!Network.wifiEnabled)
        }
    }

    PScroll {
        anchors.top: header.bottom
        anchors.topMargin: 14
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        spacing: 8

        PText {
            visible: Network.networks.length === 0
            text: Network.wifiEnabled ? "No Networks" : "Wi-Fi Off"
            color: Theme.sub
        }

        Repeater {
            model: Network.wifiEnabled ? Network.networks : []
            delegate: Card {
                id: row
                required property var modelData
                readonly property bool askPw: Network.needsPassword === modelData.ssid
                width: parent ? parent.width : 0
                height: (askPw ? 96 : 52) + offset
                fill: modelData.active ? Theme.pastels.blue : (area.containsMouse ? Theme.hover : Theme.card)
                Behavior on height { NumberAnimation { duration: Theme.dur(160) } }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: row.modelData.active ? Network.disconnect(row.modelData.ssid) : Network.connect(row.modelData.ssid, "")
                }

                Row {
                    x: 14
                    y: 14
                    spacing: 10
                    PIcon { name: Network.signalIcon(row.modelData.signal); color: row.modelData.active ? Theme.onPastel : Theme.ink }
                    PText {
                        width: 420
                        text: row.modelData.ssid
                        font.bold: row.modelData.active
                        color: row.modelData.active ? Theme.onPastel : Theme.ink
                    }
                }
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    y: 14
                    spacing: 8
                    PText {
                        visible: Network.connecting === row.modelData.ssid
                        text: "Joining"
                        color: Theme.sub
                        font.pixelSize: 11
                    }
                    PIcon { visible: row.modelData.secure; name: "lock"; size: 15; color: row.modelData.active ? Theme.onPastel : Theme.sub }
                    PIcon { visible: row.modelData.active; name: "check"; size: 17; color: Theme.onPastel }
                }

                PField {
                    id: pw
                    visible: row.askPw
                    x: 14
                    y: 50
                    width: parent.width - 28 - 90
                    height: 34
                    password: true
                    placeholder: "Password"
                    onAccepted: Network.connect(row.modelData.ssid, text)
                    onVisibleChanged: if (visible) input.forceActiveFocus()
                }
                PButton {
                    visible: row.askPw
                    anchors.left: pw.right
                    anchors.leftMargin: 8
                    y: 50
                    text: "Join"
                    checked: true
                    onClicked: Network.connect(row.modelData.ssid, pw.text)
                }
            }
        }
    }
}
