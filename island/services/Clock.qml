pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    SystemClock {
        id: clk
        precision: Config.s.showSeconds ? SystemClock.Seconds : SystemClock.Minutes
    }

    readonly property date now: clk.date
    readonly property bool h24: Config.s.use24h
    // Qt's "h" is only 12-hour when "AP" is in the same format, so build it by hand
    readonly property int hour12: (now.getHours() % 12) || 12
    function pad(n) { return n < 10 ? "0" + n : "" + n; }
    readonly property string hm: {
        const h = h24 ? pad(now.getHours()) : String(hour12);
        const base = h + ":" + pad(now.getMinutes());
        return Config.s.showSeconds ? base + ":" + pad(now.getSeconds()) : base;
    }
    readonly property string ampm: h24 ? "" : (now.getHours() < 12 ? "AM" : "PM")
    readonly property string weekday: Qt.formatDate(now, "dddd")
    readonly property string dateLong: Qt.formatDate(now, "MMMM d, yyyy")
    readonly property string greeting: {
        const h = now.getHours();
        if (h < 5) return "Good night";
        if (h < 12) return "Good morning";
        if (h < 18) return "Good afternoon";
        return "Good evening";
    }
}
