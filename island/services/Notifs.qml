pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: list.length
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
            if (!Config.s.dnd || critical) Sounds.play("notification");
            if (Config.s.notifPopups && (!Config.s.dnd || critical)) {
                root.latest = n;
                Island.flash("notif", Config.s.notifTimeout);
            }
        }
    }

    function isSignalDesktop(n) { return /^signal/i.test(n?.appName ?? "") || /signal/i.test(n?.desktopEntry ?? ""); }

    // Signal Desktop: a click jumps into the app (its "default" action) instead of the hub
    function openApp(n) {
        if (!n || !isSignalDesktop(n)) return false;
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
