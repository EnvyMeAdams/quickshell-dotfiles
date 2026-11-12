import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.island
import qs.desktop
import qs.lock
import qs.island.hub

ShellRoot {
    id: root

    // make sure background services start even before anything is shown
    readonly property var keepAlive: [Compositor, Notifs, Media, Audio, Privacy, Network, Wallpaper, Recorder, AutoColor, Awake, Battery, Brightness, ControlActions, NightLight]

    Variants {
        model: Quickshell.screens
        DesktopWindow {}
    }
    Variants {
        model: Quickshell.screens
        ReserveWindow {}
    }
    Variants {
        model: Quickshell.screens
        IslandWindow {}
    }
    Saver {}

    // The lock (needs PAM) and idle timers (need a newer Quickshell) are
    // created at runtime: if your build lacks a module they need, only that
    // part turns off, the island still starts, and Settings → About says why.
    property var optional: []
    function loadOptional(path) {
        const c = Qt.createComponent(Qt.resolvedUrl(path));
        if (c.status !== Component.Ready) {
            console.warn("island: could not load", path, "\n", c.errorString());
            return c.errorString().split("\n")[0];
        }
        optional.push(c.createObject(root));
        return "";
    }
    Component.onCompleted: {
        LockState.lockError = loadOptional("lock/LockSession.qml");
        LockState.sessionReady = LockState.lockError === "";
        LockState.idleError = loadOptional("lock/Idle.qml");
        LockState.idleReady = LockState.idleError === "";
        missingCheck.start();
    }

    // After an update that adds a new service file, Quickshell's live reload
    // doesn't always pick it up, and the features using it silently do nothing.
    // Spot that and say so instead of failing quietly.
    Timer {
        id: missingCheck
        interval: 3000
        onTriggered: {
            const missing = [];
            try { NightLight.on; } catch (e) { missing.push("Night Light"); }
            try { Brightness.available; } catch (e) { missing.push("Brightness"); }
            try { Battery.present; } catch (e) { missing.push("Battery"); }
            try { Awake.saverBlocked; } catch (e) { missing.push("Keep Awake"); }
            try { Recorder.recording; } catch (e) { missing.push("Recording"); }
            if (missing.length > 0) {
                console.warn("island: not loaded:", missing.join(", "));
                Quickshell.execDetached(["notify-send", "-a", "Island", "Restart Quickshell to finish updating",
                    missing.join(", ") + " didn't load. Run: pkill -x quickshell; quickshell -d"]);
            }
        }
    }

    // Bind keys with:  quickshell ipc call island <name>
    IpcHandler {
        target: "island"
        function launcher(): void { Island.toggle("launcher"); }
        function hub(): void { Island.toggleHub("home"); }
        function now(): void { Island.toggleHub("home"); }
        function sound(): void { Island.toggleHub("sound"); }
        function volume(): void { Island.toggleHub("sound"); }
        function control(): void { Island.toggleHub("control"); }
        function notifications(): void { Island.toggleHub("notifications"); }
        function wallpaper(): void { Island.toggleHub("wallpaper"); }
        function settings(): void { Island.toggleHub("settings"); }
        function close(): void { Island.close(); }
        function dnd(): void { Config.s.dnd = !Config.s.dnd; }
        function lock(): void { LockState.lock(); }
        function saver(): void { LockState.startSaver(); }
        function screensaver(): void { LockState.startSaver(); }
        function brightnessUp(): void { Brightness.nudge(0.05); }
        function brightnessDown(): void { Brightness.nudge(-0.05); }
        function micmute(): void { Audio.toggleMic(); }
        function nightlight(): void { NightLight.toggle(); }
        function screenshot(mode: string): void {
            Quickshell.execDetached(["sh", "-c", Compositor.screenshotCmd(mode || "region")]);
        }

        function logout(): void { ControlActions.power("logout"); }
        function awake(): void { Awake.keepAwake = !Awake.keepAwake; }
        function record(): void { Recorder.toggle(); }
        function recordRegion(): void { Recorder.toggle("region"); }
        function recordScreen(): void { Recorder.toggle("screen"); }

        function windows(): void { Windows.step(1); }
        function windowsPrev(): void { Windows.step(-1); }

        // names used by the old island, so existing binds keep working
        function toggleLauncher(): void { Island.toggle("launcher"); }
        function toggleHub(): void { Island.toggleHub("home"); }
        function toggleControl(): void { Island.toggleHub("control"); }
        function openTab(tab: string): void {
            const map = { search: "sound", launcher: "launcher", sound: "sound", volume: "sound",
                          control: "control", wallpaper: "wallpaper", settings: "settings",
                          notifs: "notifications", notifications: "notifications",
                          home: "home", now: "home", media: "home" };
            const t = map[tab] ?? "home";
            if (t === "launcher") Island.toggle("launcher"); else Island.toggleHub(t);
        }
    }

    // Hyprland global shortcuts (island:launcher, ...) live in compositor/Hypr.qml
}
