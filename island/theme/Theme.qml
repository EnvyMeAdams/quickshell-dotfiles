pragma Singleton
import QtQuick
import Quickshell
import qs.services

Singleton {
    id: t

    // Surfaces: Cream (light), Fog (light grey), Slate (mid grey), Cocoa (dark).
    // Every set keeps ink outlines and lets the pastels stay the brightest thing.
    readonly property var modes: ({
        cream: { base: "#f1e3d6", card: "#f7ede4", sunk: "#e8d6c6", hover: "#efe0d3",
                 ink: "#1e1916", sub: "#7c6a5d", line: "#1e1916", shade: "#1e1916" },
        fog:   { base: "#e2e0de", card: "#eeedeb", sunk: "#d4d1ce", hover: "#e6e4e1",
                 ink: "#1d1b1a", sub: "#6c6763", line: "#1d1b1a", shade: "#1d1b1a" },
        slate: { base: "#58565a", card: "#67646a", sunk: "#4a484d", hover: "#716e74",
                 ink: "#f7f3ef", sub: "#ddd6d3", line: "#1b1a1d", shade: "#1b1a1d" },
        blush: { base: "#f3dcdd", card: "#f9e9e8", sunk: "#ebcccd", hover: "#f3dedd",
                 ink: "#22181a", sub: "#7d6064", line: "#22181a", shade: "#22181a" },
        matcha: { base: "#dde5d1", card: "#ebf0e2", sunk: "#ccd7bd", hover: "#e1e8d6",
                  ink: "#1a1f17", sub: "#5f6c55", line: "#1a1f17", shade: "#1a1f17" },
        lilac: { base: "#e3dcef", card: "#efeaf7", sunk: "#d3c9e6", hover: "#e6e0f1",
                 ink: "#1d1a24", sub: "#685f7a", line: "#1d1a24", shade: "#1d1a24" },
        midnight: { base: "#232838", card: "#2d3346", sunk: "#1b1f2c", hover: "#363d53",
                    ink: "#eef0f8", sub: "#aab1c8", line: "#0b0d14", shade: "#0b0d14" },
        cocoa: { base: "#2a2421", card: "#342c28", sunk: "#221d1a", hover: "#3d3430",
                 ink: "#f1e3d6", sub: "#b3a194", line: "#0e0b0a", shade: "#0e0b0a" }
    })
    // Look: "smoke" (dark tinted glass, the default), "clear" (nearly clear
    // glass with a bright rim) or "classic" (the cream-and-ink cards above).
    // Glass surfaces are all see-through; anything painted with a solid colour
    // (the pastels, the accent) goes through tint() so it sits in the glass.
    readonly property string look: ["smoke", "clear", "classic"].includes(Config.s.look) ? Config.s.look : "smoke"
    readonly property bool glass: look !== "classic"
    readonly property var glassModes: ({
        smoke: { base: Qt.rgba(0.065, 0.072, 0.098, 0.62), card: Qt.rgba(1, 1, 1, 0.06), sunk: Qt.rgba(1, 1, 1, 0.11),
                 hover: Qt.rgba(1, 1, 1, 0.11), ink: "#f4f5f8", sub: Qt.rgba(0.957, 0.961, 0.973, 0.66),
                 line: Qt.rgba(1, 1, 1, 0.12), rim: Qt.rgba(1, 1, 1, 0.24), shade: "transparent",
                 knob: "#eceef2", onPastel: "#fbf7f3" },
        clear: { base: Qt.rgba(0.08, 0.09, 0.11, 0.26), card: Qt.rgba(1, 1, 1, 0.10), sunk: Qt.rgba(1, 1, 1, 0.20),
                 hover: Qt.rgba(1, 1, 1, 0.16), ink: "#ffffff", sub: Qt.rgba(1, 1, 1, 0.80),
                 line: Qt.rgba(1, 1, 1, 0.30), rim: Qt.rgba(1, 1, 1, 0.62), shade: "transparent",
                 knob: "#ffffff", onPastel: "#15171c" }
    })
    readonly property var m: glass ? glassModes[look] : (modes[Config.s.surface] ?? modes.cream)
    readonly property bool dark: glass || ["slate", "cocoa", "midnight"].includes(Config.s.surface)

    readonly property color base:  m.base
    readonly property color card:  m.card
    readonly property color sunk:  m.sunk
    readonly property color hover: m.hover
    readonly property color ink:   m.ink
    readonly property color sub:   m.sub
    readonly property color line:  m.line
    readonly property color shade: m.shade
    readonly property color onPastel: glass ? m.onPastel : "#1e1916"
    // the island's outer glass (pill, power menu, popups); inner cards use `card`
    readonly property color panel: glass ? m.base : m.card
    readonly property color rim:   glass ? m.rim : "transparent"
    readonly property color knob:  glass ? m.knob : m.card
    // text / icons on a strong() colour (a full pastel on Smoked, white on Clear)
    readonly property color onStrong: glass ? (look === "clear" ? "#15171c" : "#1e1916") : onPastel
    // outlines that must stay visible on glass (battery bodies, nubs)
    readonly property color stroke: glass ? m.sub : m.line

    // A solid colour (pastel / accent) as it sits in the glass: on Smoked it
    // keeps its hue at 30% so the dark glass shows through, on Clear it turns
    // milky-light (dark text goes on it). See-through colours pass straight
    // through, so tint() is safe to apply twice. Classic is untouched.
    function tint(c) {
        if (!glass || c.a < 0.99) return c;
        if (look === "clear") return Qt.rgba(0.35 * c.r + 0.65, 0.35 * c.g + 0.65, 0.35 * c.b + 0.65, 0.92);
        return Qt.rgba(c.r, c.g, c.b, 0.30);
    }
    // the outline for something filled with tint(c): a glowing edge in its hue
    function edge(c) {
        if (!glass) return line;
        // a glass surface (card, hover…) keeps the plain hairline
        if (c.a < (look === "clear" ? 0.5 : 0.2)) return line;
        if (look === "clear") return Qt.rgba(1, 1, 1, 0.75);
        return Qt.rgba(c.r, c.g, c.b, 0.62);
    }
    // small solid marks (slider fills, bars, dots, progress): full colour on
    // Smoked, white on Clear, unchanged on Classic. Takes tinted colours too.
    function strong(c) {
        if (!glass) return c;
        return look === "clear" ? Qt.rgba(1, 1, 1, 1) : Qt.rgba(c.r, c.g, c.b, 1);
    }
    // a card washed with a colour (selected rows, "connected" cards)
    function wash(c, amount) {
        if (!glass) return Qt.tint(card, Qt.rgba(c.r, c.g, c.b, amount));
        return look === "clear" ? Qt.rgba(1, 1, 1, 0.10 + amount * 0.35)
                                : Qt.rgba(c.r, c.g, c.b, 0.06 + amount * 0.40);
    }

    // the real pastels; `pastels` below is them as they sit on the current look
    readonly property var rawPastels: ({
        pink: "#f6a9a9", rose: "#f7c3d6", blush: "#f4c7c3", coral: "#f7a48b",
        peach: "#f8b984", apricot: "#f9cfa0", butter: "#f6e7a1", yellow: "#f1d27c",
        sage: "#cfd8b4", green: "#c2d69b", mint: "#b8e6cf", aqua: "#a8dadc",
        sky: "#bfe1f6", blue: "#a7c6ea", periwinkle: "#b9c2f2", lavender: "#c9c2f0",
        lilac: "#d6b8ea", mauve: "#e3b5d2", sand: "#e2c2a5", mocha: "#d4b8a8"
    })
    readonly property var pastels: {
        const out = {};
        for (const k in rawPastels) {
            const h = rawPastels[k];
            out[k] = tint(Qt.rgba(parseInt(h.slice(1, 3), 16) / 255, parseInt(h.slice(3, 5), 16) / 255,
                                  parseInt(h.slice(5, 7), 16) / 255, 1));
        }
        return out;
    }
    readonly property var accentNames: ["pink", "rose", "blush", "coral", "peach", "apricot", "butter", "yellow",
                                        "sage", "green", "mint", "aqua", "sky", "blue", "periwinkle", "lavender",
                                        "lilac", "mauve", "sand", "mocha"]
    readonly property var cycle: [pastels.pink, pastels.rose, pastels.peach, pastels.yellow, pastels.green, pastels.blue, pastels.lilac]
    // "wallpaper" = picked from the current photo or video wallpaper
    readonly property bool autoAccent: Config.s.accent === "wallpaper"
    readonly property color accentRaw: autoAccent ? (AutoColor.ready ? AutoColor.color : rawPastels.peach)
                                                  : (rawPastels[Config.s.accent] ?? rawPastels.peach)
    readonly property color accent: tint(accentRaw)
    readonly property color mic: "#f39a4a"
    readonly property color camera: "#7fc46a"
    readonly property color danger: pastels.pink

    readonly property int outline: glass ? 1 : Config.s.outline
    readonly property int shadow: glass ? 0 : Config.s.shadow
    readonly property int radius: Config.s.radius
    readonly property string font: Config.s.fontFamily
    // icons ship with the config, so nothing has to be installed
    FontLoader { id: iconLoader; source: Qt.resolvedUrl("../assets/fonts/MaterialSymbolsRounded.ttf") }
    readonly property string iconFont: iconLoader.status === FontLoader.Ready ? iconLoader.name : "Material Symbols Rounded"

    function dur(ms) { return Math.round(ms / Math.max(0.25, Config.s.animSpeed)); }

    // every pill shape in one table — content is laid out at these sizes,
    // so nothing reflows or jumps while the pill morphs
    readonly property bool battery: { try { return Battery.shown === true; } catch (e) { return false; } }
    readonly property int batteryW: battery ? 58 : 0
    // room for the exit-node flag, only while it shows
    readonly property int extraW: {
        try {
            return Config.s.tsPillFlag && Tailscale.up && Tailscale.exitNode ? 22 : 0;
        } catch (e) { return 0; }
    }
    readonly property var sizes: ({
        idle:       Qt.size(250 + batteryW + extraW, 38),
        nowplaying: Qt.size(400 + batteryW, 38),
        workspace:  Qt.size(300, 38),
        volume:     Qt.size(380, 60),
        brightness: Qt.size(420, 60),
        notif:      Qt.size(460, 104),
        activity:   Qt.size(380, 60),
        launcher:   Qt.size(600, 440),
        windows:    Qt.size(760, 176),
        hub:        Qt.size(880, 520)
    })
}
