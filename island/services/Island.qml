pragma Singleton
import QtQuick
import Quickshell

// One source of truth for what the pill is doing.
//   mode:      idle | launcher | hub   (things you opened on purpose)
//   popup: "" | volume | notif | workspace | activity | message   (short popups, only while idle)
Singleton {
    id: root

    property string mode: "idle"
    property string hubTab: "home"
    property string popup: ""
    property bool held: false

    // live activity: a short card in the pill (Tailscale exit node, …)
    //   { icon, emoji, title, sub, tint, tab }  — tab: hub tab a click opens
    property var activity: ({})
    function showActivity(a, ms) {
        activity = a;
        flash("activity", ms || 2600);
    }

    function toggle(m) {
        mode = (mode === m) ? "idle" : m;
        popup = "";
    }
    function toggleHub(tab) {
        if (mode === "hub" && hubTab === tab) mode = "idle";
        else { hubTab = tab; mode = "hub"; }
        popup = "";
    }
    function close() { mode = "idle"; }

    function flash(kind, ms) {
        if (mode !== "idle") return;
        popup = kind;
        timer.interval = ms;
        if (!held) timer.restart();
    }
    function hold() { held = true; timer.stop(); }
    function release() { held = false; if (popup !== "") timer.restart(); }
    function dismiss() { timer.stop(); popup = ""; }

    Timer {
        id: timer
        onTriggered: root.popup = ""
    }
}
