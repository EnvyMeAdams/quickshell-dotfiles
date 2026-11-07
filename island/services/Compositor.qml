pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

// Everything that differs between compositors goes through here, so the rest
// of the island never talks to Hyprland or MangoWM directly.
//
//   Hyprland  compositor/Hypr.qml   workspaces, focused display, global shortcuts
//   MangoWM   compositor/Mango.qml  tags (via mmsg), focused display
//   other     no workspaces; the focused display follows the active window
//
// Windows, focus and fullscreen use the standard Wayland window list
// (ToplevelManager), which works the same everywhere.
Singleton {
    id: root

    readonly property string kind: {
        const d = (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase();
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || d.includes("hyprland")) return "hyprland";
        if (Quickshell.env("MANGO_INSTANCE_SIGNATURE") || d.includes("mango")) return "mango";
        return "other";
    }
    readonly property string label: ({ hyprland: "Hyprland", mango: "MangoWM" })[kind] ?? "Other"

    property var backend: null
    property string backendError: ""
    readonly property bool hasWorkspaces: backend !== null && backendError === ""

    // the display you're using
    readonly property string activeScreen: ToplevelManager.activeToplevel?.screens?.[0]?.name ?? ""
    readonly property string focused: backend?.focused || activeScreen || (Quickshell.screens[0]?.name ?? "")

    // workspace (Hyprland) or tag (MangoWM) shown on a display, 0 if unknown
    function workspace(screen) { return backend?.active?.[screen] ?? 0; }
    // the ones that exist / have windows on a display, sorted
    function workspaces(screen) { return backend?.occupied?.[screen] ?? []; }

    // the focused window is fullscreen
    readonly property bool fullscreen: ToplevelManager.toplevels.values.some(t => t.activated && t.fullscreen)

    Component.onCompleted: {
        const file = ({ hyprland: "../compositor/Hypr.qml", mango: "../compositor/Mango.qml" })[kind];
        if (!file) return;
        const c = Qt.createComponent(Qt.resolvedUrl(file));
        if (c.status !== Component.Ready) {
            backendError = c.errorString().split("\n")[0];
            console.warn("island: compositor support didn't load:", backendError);
            return;
        }
        backend = c.createObject(root);
    }

    // ── commands that depend on the compositor ──
    // An empty setting means "automatic". A Hyprland-only default saved on
    // another machine is also treated as automatic, so a settings file copied
    // from a Hyprland machine doesn't break a MangoWM one.
    readonly property string scripts: Qt.resolvedUrl("../scripts").toString().replace(/^file:\/\//, "")
    function pick(user, hyprDefault, other) {
        const u = (user ?? "").trim();
        if (u && !(kind !== "hyprland" && u === hyprDefault)) return u;
        return kind === "hyprland" ? hyprDefault : other;
    }
    function screenshotCmd(mode) {
        const auto = "sh '" + scripts + "/screenshot.sh' " + (mode || "region");
        return pick(Config.s.screenshotCmd, "hyprshot -m region", auto) || auto;
    }
    function logoutCmd() {
        const u = (Config.s.logoutCmd ?? "").trim();
        if (u) return u;
        if (kind === "hyprland") return "hyprctl dispatch exit";
        if (kind === "mango") return "mmsg -d quit";
        return "loginctl terminate-session \"${XDG_SESSION_ID:-self}\"";
    }
    function nightCmd(on) {
        return on ? pick(Config.s.nightOnCmd, "hyprsunset -t 4500", "wlsunset -T 4501 -t 4500")
                  : pick(Config.s.nightOffCmd, "pkill -x hyprsunset", "pkill -x wlsunset");
    }
}
