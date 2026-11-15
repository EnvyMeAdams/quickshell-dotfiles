pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Reads /sys/class/power_supply directly (no UPower needed).
// `present` is false on a desktop, so the battery icon only shows on laptops
// unless Settings → Home → Battery forces it.
Singleton {
    id: root

    property bool present: false
    property int percent: 0
    property string status: ""              // Charging | Discharging | Full | Not charging
    readonly property bool charging: status === "Charging" || status === "Full"
    property string lastStatus: ""          // previous reading, to notice the charger going in
    property bool lowWarned: false          // low-battery sound plays once per discharge
    property int ac: -1                     // charger: 1 in, 0 out, -1 = no charger reported
    readonly property bool pluggedIn: ac === 1 || (ac === -1 && charging)
    property bool firstRead: true

    // charger went in / came out (not on the first reading); the charging popup listens
    signal plugged()
    signal unplugged()
    readonly property bool shown: Config.s.showBattery === "on" || (Config.s.showBattery === "auto" && present)

    readonly property string icon: {
        if (charging) return "battery_charging_full";
        if (percent >= 95) return "battery_full";
        const steps = ["battery_0_bar", "battery_1_bar", "battery_2_bar", "battery_3_bar",
                       "battery_4_bar", "battery_5_bar", "battery_6_bar"];
        return steps[Math.min(6, Math.floor(percent / 15))];
    }

    Process {
        id: read
        // every BAT*: capacity and status, averaged for laptops with two batteries
        command: ["sh", "-c", "n=0; t=0; s=''; for b in /sys/class/power_supply/BAT*; do [ -r \"$b/capacity\" ] || continue; " +
                              "t=$((t + $(cat \"$b/capacity\"))); n=$((n + 1)); s=$(cat \"$b/status\" 2>/dev/null); done; " +
                              "a=-1; for m in /sys/class/power_supply/*; do case \"$(cat \"$m/type\" 2>/dev/null)\" in Mains|USB) ;; *) continue;; esac; " +
                              "[ \"$(cat \"$m/online\" 2>/dev/null)\" = 1 ] && a=1 || { [ $a = 1 ] || a=0; }; done; " +
                              "[ $n -gt 0 ] && echo \"$((t / n)) $a $s\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                root.present = t !== "";
                if (!t) return;
                // "<percent> <charger 1|0|-1> <status, may have spaces>"
                const parts = t.split(" ");
                root.percent = parseInt(parts[0]) || 0;
                const wasIn = root.pluggedIn;
                root.ac = parseInt(parts[1] ?? "-1");
                if (isNaN(root.ac)) root.ac = -1;
                root.status = parts.slice(2).join(" ");
                root.lastStatus = root.status;

                // charger in/out: reads the charger itself, so it also fires when a
                // charge limit (ThinkPads) leaves the battery at "Not charging"
                if (!root.firstRead && root.pluggedIn !== wasIn) {
                    if (root.pluggedIn) { Sounds.play("charger"); root.plugged(); }
                    else root.unplugged();
                    catchUp.restart();          // the battery's status lags the charger a little
                }
                root.firstRead = false;
                if (root.status === "Discharging" && root.percent <= 15) {
                    if (!root.lowWarned) { root.lowWarned = true; Sounds.play("lowBattery"); }
                } else if (root.charging || root.percent > 20) {
                    root.lowWarned = false;
                }
            }
        }
    }
    Timer {
        interval: root.present ? 20000 : 120000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: read.running = true
    }

    // the kernel announces charger and battery changes; re-read right away
    Process {
        running: root.present
        command: ["sh", "-c", "command -v udevadm >/dev/null && exec udevadm monitor --kernel --subsystem-match=power_supply"]
        stdout: SplitParser { onRead: line => { if (line.indexOf("change") >= 0) settle.restart(); } }
    }
    Timer { id: settle; interval: 600; onTriggered: read.running = true }
    Timer { id: catchUp; interval: 1500; onTriggered: read.running = true }
}
