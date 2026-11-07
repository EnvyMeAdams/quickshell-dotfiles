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
                              "[ $n -gt 0 ] && echo \"$((t / n)) $s\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                root.present = t !== "";
                if (!t) return;
                const sp = t.indexOf(" ");
                root.percent = parseInt(sp > 0 ? t.slice(0, sp) : t) || 0;
                root.status = sp > 0 ? t.slice(sp + 1) : "";
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
}
