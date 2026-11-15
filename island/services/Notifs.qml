pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: list.length
    // Fluxer (open-source Discord-style chat) alerts, shown in Messages too
    readonly property var fluxerList: list.filter(n => isFluxer(n))
    readonly property int fluxerCount: fluxerList.length
    property Notification latest: null

    NotificationServer {
        id: server
        keepOnReload: true
        imageSupported: true
        actionsSupported: true
        persistenceSupported: true
        bodyMarkupSupported: false

        onNotification: n => {
            // Signal Desktop's own alerts would double up with the island's Signal
            try {
                if (Config.s.signalHideDesktop && Signal.connected && root.isSignalDesktop(n)) return;
            } catch (e) {}
            n.tracked = true;
            const critical = n.urgency === NotificationUrgency.Critical;
            if (Config.s.fluxerStyle && root.isFluxer(n) && !critical) {
                const t = ((n.summary ?? "") + " " + (n.body ?? "")).toLowerCase();
                if ((Config.s.fluxerMuted ?? []).some(w => w && t.includes(w.toLowerCase()))) return;   // kept, silent
                if (!Config.s.fluxerPopups) return;
            }
            if (!Config.s.dnd || critical) Sounds.play("notification");
            if (Config.s.notifPopups && (!Config.s.dnd || critical)) {
                root.latest = n;
                Island.flash("notif", Config.s.notifTimeout);
            }
        }
    }

    function isFluxer(n) { return /fluxer/i.test((n?.appName ?? "") + " " + (n?.desktopEntry ?? "")); }
    function isSignalDesktop(n) { return /^signal/i.test(n?.appName ?? "") || /signal/i.test(n?.desktopEntry ?? ""); }

    // chat apps: a click jumps into the app (their "default" action) instead of the hub
    function openApp(n) {
        if (!n || !(isFluxer(n) || isSignalDesktop(n))) return false;
        const a = (n.actions ?? []).find(x => x.identifier === "default") ?? (n.actions ?? [])[0];
        if (!a) return false;
        a.invoke();
        return true;
    }

    function clearAll() { server.trackedNotifications.values.slice().forEach(n => n.dismiss()); }

    function imageFor(n) {
        if (!n) return "";
        if (n.image) return n.image;
        const ic = n.appIcon ?? "";
        if (!ic) return "";
        if (ic.startsWith("/")) return "file://" + ic;
        if (ic.startsWith("file://")) return ic;
        return Quickshell.iconPath(ic, true);
    }
}
