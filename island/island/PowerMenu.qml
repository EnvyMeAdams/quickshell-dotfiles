import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.theme
import qs.components
import qs.island.hub      // ControlActions (lock, sleep, reboot, …) lives here

// Power menu in the middle of the display you're on: the screen dims and a
// row (or column, Settings › Home › Power Menu) of big buttons pops in.
// Mouse or keys: arrows move, Enter/Space picks, 1–6 jump straight to one,
// Esc or a click outside closes. Log Out / Reboot / Power ask "Sure?" first.
PanelWindow {
    id: win

    required property ShellScreen modelData
    screen: modelData

    readonly property bool mine: Island.powerMenu && modelData.name === Compositor.focused
    readonly property bool vertical: Config.s.powerMenuLayout === "vertical"

    readonly property var all: ({
        lock:     { kind: "lock",     icon: "lock",               label: "Lock",    tint: "blue",   confirm: false },
        saver:    { kind: "saver",    icon: "movie",              label: "Saver",   tint: "green",  confirm: false },
        sleep:    { kind: "sleep",    icon: "dark_mode",          label: "Sleep",   tint: "lilac",  confirm: false },
        logout:   { kind: "logout",   icon: "logout",             label: "Log Out", tint: "butter", confirm: true },
        reboot:   { kind: "reboot",   icon: "restart_alt",        label: "Reboot",  tint: "peach",  confirm: true },
        poweroff: { kind: "poweroff", icon: "power_settings_new", label: "Power",   tint: "pink",   confirm: true }
    })
    // your order, minus the ones you hid; anything new goes at the end
    readonly property var items: {
        const order = (Config.s.powerMenuOrder ?? []).filter(k => all[k]);
        for (const k of Object.keys(all)) if (!order.includes(k)) order.push(k);
        const hidden = Config.s.powerMenuHidden ?? [];
        return order.filter(k => !hidden.includes(k)).map(k => all[k]);
    }

    property int current: 0
    property string armed: ""
    Timer { id: disarm; interval: 3000; onTriggered: win.armed = "" }

    visible: mine || scrim.opacity > 0.01
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "island-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: mine ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onMineChanged: {
        if (mine) {
            current = Math.max(0, items.findIndex(i => i.kind === "lock"));
            armed = "";
            keys.forceActiveFocus();
            intro.restart();
        }
    }

    function close() { Island.powerMenu = false; armed = ""; }
    // never stay on top of the lock screen
    Connections {
        target: LockState
        function onLockedChanged() { if (LockState.locked) win.close(); }
    }
    function pick(i) {
        const it = items[i];
        if (!it) return;
        current = i;
        if (it.confirm && Config.s.powerConfirm && armed !== it.kind) {
            armed = it.kind;
            disarm.restart();
            return;
        }
        close();
        ControlActions.power(it.kind);
    }

    // dim everything; a click anywhere outside the buttons closes
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: "black"
        opacity: win.mine ? Math.max(0, Math.min(90, Config.s.powerMenuDim)) / 100 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.dur(220) } }
        MouseArea { anchors.fill: parent; onClicked: win.close() }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            const n = win.items.length;
            const next = win.vertical ? Qt.Key_Down : Qt.Key_Right;
            const prev = win.vertical ? Qt.Key_Up : Qt.Key_Left;
            if (e.key === Qt.Key_Escape) win.close();
            else if (e.key === next || e.key === Qt.Key_Tab) { win.current = (win.current + 1) % n; win.armed = ""; }
            else if (e.key === prev || e.key === Qt.Key_Backtab) { win.current = (win.current + n - 1) % n; win.armed = ""; }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) win.pick(win.current);
            else if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) win.pick(e.key - Qt.Key_1);
            else return;
            e.accepted = true;
        }
    }

    Card {
        id: tray
        anchors.centerIn: parent
        radius: 40
        fill: Theme.glass ? Theme.panel : Qt.rgba(Theme.card.r, Theme.card.g, Theme.card.b, 0.88)
        frost: true
        frostScreen: win.modelData.name
        width: (win.vertical ? col.implicitWidth : row.implicitWidth) + 48 + offset
        height: (win.vertical ? col.implicitHeight : row.implicitHeight) + 48 + offset
        opacity: win.mine ? 1 : 0
        scale: win.mine ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: Theme.dur(200) } }
        Behavior on scale { NumberAnimation { duration: Theme.dur(320); easing.type: Easing.OutBack } }
        // clicks on the tray itself don't close the menu
        MouseArea { anchors.fill: parent }

        Row {
            id: row
            visible: !win.vertical
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -tray.offset / 2
            anchors.verticalCenterOffset: -tray.offset / 2
            spacing: 14
            Repeater { model: win.vertical ? [] : win.items; delegate: RoundButton {} }
        }
        Column {
            id: col
            visible: win.vertical
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -tray.offset / 2
            anchors.verticalCenterOffset: -tray.offset / 2
            spacing: 10
            Repeater { model: win.vertical ? win.items : []; delegate: WideButton {} }
        }
    }
    PText {
        visible: Config.s.powerMenuHints
        anchors.top: tray.bottom
        anchors.topMargin: 16
        anchors.horizontalCenter: tray.horizontalCenter
        opacity: tray.opacity * 0.8
        color: "white"
        font.pixelSize: 12
        text: (win.vertical ? "↑ ↓" : "← →") + " move · Enter pick · 1–" + win.items.length + " jump · Esc close"
    }

    // buttons pop in one after another
    property real popT: 0
    NumberAnimation { id: intro; target: win; property: "popT"; from: 0; to: 1; duration: Theme.dur(420) }

    // ── horizontal: big round buttons with the name underneath ──
    component RoundButton: Item {
        id: rb
        required property var modelData
        required property int index
        readonly property bool sel: win.current === index
        readonly property bool sure: win.armed === modelData.kind
        readonly property color tint: Theme.pastels[modelData.tint]
        width: 100
        height: 128
        opacity: Math.min(1, win.popT * (win.items.length + 2) - index)
        scale: 0.6 + 0.4 * Math.max(0, Math.min(1, win.popT * (win.items.length + 2) - index))

        Card {
            id: disc
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: -offset / 2
            width: 84 + offset
            height: 84 + offset
            radius: 42
            fill: rb.sure ? rb.tint : rb.sel ? Theme.hover : Theme.card
            borderColor: rb.sure ? Theme.edge(rb.tint) : Theme.line
            scale: rb.sel ? 1.08 : 1
            Behavior on scale { NumberAnimation { duration: Theme.dur(160); easing.type: Easing.OutBack } }
            Rectangle {
                // `disc`, not `parent`: a Card puts its children in an inner item
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -disc.offset / 2
                anchors.verticalCenterOffset: -disc.offset / 2
                width: 52; height: 52; radius: 26
                color: rb.tint
                border.width: Theme.outline
                border.color: Theme.edge(rb.tint)
                PIcon { anchors.centerIn: parent; name: rb.sure ? "check" : rb.modelData.icon; size: 26; color: Theme.onPastel }
            }
        }
        PText {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            text: rb.sure ? "Sure?" : rb.modelData.label
            font.bold: true
            font.pixelSize: 13
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: if (win.current !== rb.index) { win.current = rb.index; if (win.armed !== rb.modelData.kind) win.armed = ""; }
            onClicked: win.pick(rb.index)
        }
    }

    // ── vertical: wide rows, room for "Reboot? Click again" ──
    component WideButton: Card {
        id: wb
        required property var modelData
        required property int index
        readonly property bool sel: win.current === index
        readonly property bool sure: win.armed === modelData.kind
        readonly property color tint: Theme.pastels[modelData.tint]
        width: 250 + offset
        height: 70 + offset
        radius: 24
        fill: sure ? tint : sel ? Theme.hover : Theme.card
        borderColor: sure ? Theme.edge(tint) : Theme.line
        opacity: Math.min(1, win.popT * (win.items.length + 2) - index)
        transform: Translate { x: 30 * (1 - Math.max(0, Math.min(1, win.popT * (win.items.length + 2) - wb.index))) }

        Rectangle {
            id: wdot
            x: 14
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -wb.offset / 2
            width: 42; height: 42; radius: 21
            color: wb.tint
            border.width: Theme.outline
            border.color: Theme.edge(wb.tint)
            PIcon { anchors.centerIn: parent; name: wb.sure ? "check" : wb.modelData.icon; size: 21; color: Theme.onPastel }
        }
        PText {
            anchors.left: wdot.right
            anchors.leftMargin: 14
            anchors.verticalCenter: wdot.verticalCenter
            text: wb.sure ? wb.modelData.label + "? Click again" : wb.modelData.label
            font.bold: true
            font.pixelSize: 15
            color: wb.sure ? Theme.onPastel : Theme.ink
        }
        PText {
            anchors.right: parent.right
            anchors.rightMargin: 18 + wb.offset
            anchors.verticalCenter: wdot.verticalCenter
            visible: Config.s.powerMenuHints && !wb.sure
            text: wb.index + 1
            color: Theme.sub
            font.pixelSize: 12
        }
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: if (win.current !== wb.index) { win.current = wb.index; if (win.armed !== wb.modelData.kind) win.armed = ""; }
            onClicked: win.pick(wb.index)
        }
    }
}
