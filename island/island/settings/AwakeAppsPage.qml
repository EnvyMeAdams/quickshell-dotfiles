import QtQuick
import qs.services
import qs.theme
import qs.components

// Apps that stop the screensaver and auto-lock.
//   Sound:   while the app is playing audio (videos, calls, music)
//   Open:    while any of its windows exist
//   Focused: while you're looking at it
SPage {
    id: page
    title: "Apps"

    property string draft: ""

    SRow {
        label: "Right Now"
        hint: Awake.reason ? "Waiting: " + Awake.reason : "Counting down"
    }

    // your list
    Repeater {
        model: Config.s.awakeApps ?? []
        delegate: Card {
            id: row
            required property var modelData
            required property int index
            width: parent ? parent.width : 400
            height: 54 + offset
            fill: Awake.matchedRule && Awake.matchedRule.app === modelData.app
                  ? Qt.tint(Theme.card, Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4)) : Theme.card

            PText {
                x: 16
                anchors.verticalCenter: parent.verticalCenter
                width: 200
                text: row.modelData.app
                font.bold: true
            }
            Row {
                anchors.right: del.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Repeater {
                    model: [{ v: "sound", l: "Sound", i: "volume_up" }, { v: "open", l: "Open", i: "web_asset" },
                            { v: "focused", l: "Focused", i: "center_focus_strong" }]
                    delegate: PButton {
                        required property var modelData
                        icon: modelData.i
                        text: modelData.l
                        iconSize: 15
                        faceHeight: 28
                        offset: 3
                        pad: 8
                        checked: row.modelData.when === modelData.v
                        tint: Theme.pastels.butter
                        onClicked: Awake.setWhen(row.index, modelData.v)
                    }
                }
            }
            PButton {
                id: del
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                icon: "close"
                iconSize: 15
                faceHeight: 28
                offset: 3
                pad: 2
                onClicked: Awake.removeApp(row.index)
            }
        }
    }

    // add by name
    Card {
        width: parent ? parent.width : 400
        height: 56 + offset
        PField {
            id: field
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - addBtn.width - 36
            icon: "add"
            placeholder: "App name (e.g. mpv, discord)"
            onAccepted: { Awake.addApp(text, "sound"); text = ""; }
        }
        PButton {
            id: addBtn
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "Add"
            checked: true
            onClicked: { Awake.addApp(field.text, "sound"); field.text = ""; }
        }
    }

    // one-click suggestions from what's running now
    PText {
        visible: suggest.count > 0
        text: "Running now"
        color: Theme.sub
        font.pixelSize: 11
    }
    Flow {
        width: parent ? parent.width : 400
        spacing: 8
        Repeater {
            id: suggest
            model: {
                const have = (Config.s.awakeApps ?? []).map(r => r.app);
                const s = new Set(Awake.soundApps.concat(Awake.openApps));
                return Array.from(s).filter(a => !have.includes(a)).sort();
            }
            delegate: PButton {
                required property string modelData
                icon: Awake.soundApps.includes(modelData) ? "volume_up" : "add"
                text: modelData
                iconSize: 15
                faceHeight: 28
                offset: 3
                onClicked: Awake.addApp(modelData, Awake.soundApps.includes(modelData) ? "sound" : "focused")
            }
        }
    }
}
