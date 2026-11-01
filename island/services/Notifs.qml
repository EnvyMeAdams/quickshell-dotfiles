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
            n.tracked = true;
            const critical = n.urgency === NotificationUrgency.Critical;
            if (Config.s.notifPopups && (!Config.s.dnd || critical)) {
                root.latest = n;
                Island.flash("notif", Config.s.notifTimeout);
            }
        }
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
