import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import qs.services
import qs.theme
import qs.components

// ALT+SPACE. Type to find apps.
//   = 2*(3+4)   calculator (Enter copies)
//   !g cats     DuckDuckGo bang       ? cats   web search (your engine, DuckDuckGo if it's down)
//   /notes      file and folder search (fd, falls back to find)
Item {
    id: root

    property int current: 0
    property var fileHits: []
    readonly property string q: field.text.trim()
    readonly property var results: build(q, fileHits)

    Component.onCompleted: field.input.forceActiveFocus()

    onQChanged: {
        current = 0;
        if (q.startsWith("/") && Config.s.launcherFiles) debounce.restart();
        else fileHits = [];
    }

    function calc(text) {
        const forced = text.startsWith("=");
        const e = forced ? text.slice(1) : text;
        if (!/^[\d\s+\-*/().%^]+$/.test(e) || !/\d/.test(e)) return null;
        if (!forced && !/[+\-*/%^]/.test(e)) return null;
        try {
            const r = Function('"use strict"; return (' + e.replace(/\^/g, "**") + ");")();
            return Number.isFinite(r) ? Math.round(r * 1e10) / 1e10 : null;
        } catch (err) { return null; }
    }

    function score(a, ql) {
        if (!ql) return 1;
        const n = (a.name ?? "").toLowerCase();
        if (n.startsWith(ql)) return 100;
        if (n.split(/\s+/).some(w => w.startsWith(ql))) return 70;
        if (n.includes(ql)) return 50;
        const extra = [a.genericName ?? "", a.comment ?? "", Array.from(a.keywords ?? []).join(" ")].join(" ").toLowerCase();
        return extra.includes(ql) ? 20 : 0;
    }

    function build(text, files) {
        const out = [];
        if (text.startsWith("!") || text.startsWith("?")) {
            const bang = text.startsWith("!");
            const term = bang ? text : text.slice(1).trim();
            if (term.length > 1)
                out.push({ icon: "travel_explore", title: bang ? "Bang" : "Web Search", sub: term,
                           run: () => root.webSearch(term, bang) });
            return out;
        }
        if (text.startsWith("/")) {
            files.forEach(f => out.push({ icon: "description", title: f.split("/").filter(s => s).pop() ?? f, sub: f.replace(Config.home, "~"),
                                         run: () => Quickshell.execDetached(["xdg-open", f]) }));
            return out;
        }
        const c = calc(text);
        if (c !== null)
            out.push({ icon: "calculate", title: "= " + c, sub: "Enter to copy",
                       run: () => Quickshell.execDetached(["wl-copy", String(c)]) });

        const ql = text.toLowerCase();
        DesktopEntries.applications.values
            .filter(a => !a.noDisplay)
            .map(a => ({ a: a, s: score(a, ql) }))
            .filter(x => x.s > 0)
            .sort((x, y) => (y.s - x.s) || x.a.name.localeCompare(y.a.name))
            .slice(0, 40)
            .forEach(x => out.push({ app: x.a, title: x.a.name, sub: x.a.genericName || x.a.comment || "",
                                    run: () => x.a.execute() }));
        // always offer a web search as the last row
        if (text.length > 1)
            out.push({ icon: "travel_explore", title: "Web Search", sub: text, run: () => root.webSearch(text, false) });
        return out;
    }

    // Bangs go to the backup engine (DuckDuckGo). Everything else goes to your
    // engine, or the backup when your engine is empty or can't be reached.
    function webSearch(term, bang) {
        const primary = (Config.s.searchEngine ?? "").trim();
        const backup = (Config.s.backupEngine ?? "").trim() || "https://duckduckgo.com/?q=";
        const q = encodeURIComponent(term);
        if (bang || !primary) { Quickshell.execDetached(["xdg-open", backup + q]); return; }
        const origin = (primary.match(/^https?:\/\/[^\/]+/) ?? [primary])[0];
        Quickshell.execDetached(["sh", "-c",
            "if curl -fsS -m 2 -o /dev/null \"$1\"; then xdg-open \"$2\"; else xdg-open \"$3\"; fi",
            "sh", origin, primary + q, backup + q]);
    }

    function launch(i) {
        const r = results[i];
        if (!r) return;
        Island.close();
        r.run();
    }
    function move(d) {
        if (results.length === 0) return;
        current = (current + d + results.length) % results.length;
        list.positionViewAtIndex(current, ListView.Contain);
    }

    Process {
        id: finder
        stdout: StdioCollector { onStreamFinished: root.fileHits = text.split("\n").filter(s => s) }
    }
    Timer {
        id: debounce
        interval: 220
        onTriggered: {
            const t = root.q.slice(1).trim();
            if (t.length < 2) { root.fileHits = []; return; }
            finder.running = false;
            finder.command = ["sh", "-c",
                "if command -v fd >/dev/null; then fd -i --max-results 30 -- \"$1\" \"$HOME\"; " +
                "else find \"$HOME\" -not -path '*/.*' -iname \"*$1*\" 2>/dev/null | head -30; fi", "sh", t];
            finder.running = true;
        }
    }

    PField {
        id: field
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 14
        height: 46
        icon: "search"
        placeholder: "Apps   = math   ! web   / files"
        offset: Theme.shadow
        fill: Theme.base

        onKeyPressed: e => {
            if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab) { root.move(1); e.accepted = true; }
            else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab) { root.move(-1); e.accepted = true; }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.launch(root.current); e.accepted = true; }
            else if (e.key === Qt.Key_Escape) { Island.close(); e.accepted = true; }
        }
    }

    ListView {
        id: list
        anchors.top: field.bottom
        anchors.topMargin: 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.bottomMargin: 10
        clip: true
        spacing: 4
        boundsBehavior: Flickable.StopAtBounds
        model: root.results

        delegate: Card {
            id: row
            required property var modelData
            required property int index
            readonly property bool sel: index === root.current

            width: list.width
            height: 46 + offset
            offset: sel ? Theme.shadow : 0
            fill: sel ? Theme.accent : "transparent"
            borderWidth: sel ? Theme.outline : 0

            IconImage {
                id: appIcon
                visible: !!row.modelData.app
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                implicitSize: 28
                source: row.modelData.app ? Quickshell.iconPath(row.modelData.app.icon, "application-x-executable") : ""
            }
            Rectangle {
                visible: !row.modelData.app
                anchors.centerIn: appIcon
                width: 30; height: 30; radius: 15
                color: Theme.card
                border.width: Theme.outline
                border.color: Theme.line
                PIcon { anchors.centerIn: parent; name: row.modelData.icon ?? ""; size: 17 }
            }

            Column {
                anchors.left: appIcon.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                PText {
                    width: parent.width
                    text: row.modelData.title
                    font.bold: true
                    color: row.sel ? Theme.onPastel : Theme.ink
                }
                PText {
                    width: parent.width
                    text: row.modelData.sub
                    visible: text !== ""
                    font.pixelSize: 11
                    color: row.sel ? Theme.onPastel : Theme.sub
                    opacity: row.sel ? 0.75 : 1
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.current = row.index
                onClicked: root.launch(row.index)
            }
        }

        PText {
            anchors.centerIn: parent
            visible: list.count === 0
            text: root.q.startsWith("/") ? "No Files" : "No Results"
            color: Theme.sub
        }
    }
}
