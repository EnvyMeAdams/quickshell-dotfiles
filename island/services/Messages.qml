pragma Singleton
import QtQuick
import Quickshell

// What the Messages tab and the message popup show: Signal chats and
// Fluxer alerts, plus which chat is open and what's in the popup.
Singleton {
    id: root

    readonly property bool available: Signal.enabled || (Config.s.fluxerStyle && Notifs.fluxerCount > 0)
    readonly property int unread: (Signal.enabled ? Signal.unread : 0) + (Config.s.fluxerStyle ? Notifs.fluxerCount : 0)

    property string open: ""                // open Signal chat key ("" = list)
    property string source: "signal"        // signal | fluxer
    property bool focusReply: false         // the reply field takes the keyboard when the chat opens

    // popup
    property string popKey: ""
    property int popCount: 0                // messages since the popup appeared (bursts collapse)
    readonly property var popConv: popKey ? (Signal.convs[popKey] ?? null) : null

    function openChat(key, reply) {
        source = "signal";
        open = key ?? "";
        focusReply = !!reply && open !== "";
        Island.dismiss();
        Island.hubTab = "messages";
        Island.mode = "hub";
        if (open) Signal.markRead(open);
    }

    Connections {
        target: Signal
        function onIncoming(key, msg) {
            const c = Signal.convs[key];
            // the chat is already open in front of you: just mark it read
            if (Island.mode === "hub" && Island.hubTab === "messages" && root.open === key) { Signal.markRead(key); return; }
            const allowed = !Config.s.dnd || (Config.s.msgAllow ?? []).some(n => n && c?.name?.toLowerCase().includes(n.toLowerCase()));
            if (!allowed || LockState.locked) return;
            Sounds.play("message");
            if (!Config.s.msgPopups) return;
            // a burst from the same chat updates one popup instead of stacking
            if (Island.popup === "message" && root.popKey === key) root.popCount += 1;
            else { root.popKey = key; root.popCount = 1; }
            Island.flash("message", Math.max(4000, Config.s.notifTimeout + 1500));
        }
    }

    // preview text, respecting the privacy settings
    function preview(msg) {
        if (!msg) return "";
        if (!Config.s.msgPreviews) return "New Message";
        if (msg.text) return msg.text;
        return msg.attachments === 1 ? "📎 Attachment" : "📎 " + msg.attachments + " attachments";
    }
    function when(ts) {
        const d = new Date(ts), now = new Date();
        const h = d.getHours(), m = d.getMinutes();
        const t = Config.s.use24h ? h + ":" + (m < 10 ? "0" : "") + m
                                  : ((h % 12) || 12) + ":" + (m < 10 ? "0" : "") + m + (h < 12 ? " AM" : " PM");
        return d.toDateString() === now.toDateString() ? t : (d.getMonth() + 1) + "/" + d.getDate() + " " + t;
    }
}
