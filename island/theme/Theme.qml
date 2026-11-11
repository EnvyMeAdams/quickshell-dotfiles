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
    readonly property var m: modes[Config.s.surface] ?? modes.cream
    readonly property bool dark: ["slate", "cocoa", "midnight"].includes(Config.s.surface)

    readonly property color base:  m.base
    readonly property color card:  m.card
    readonly property color sunk:  m.sunk
    readonly property color hover: m.hover
    readonly property color ink:   m.ink
    readonly property color sub:   m.sub
    readonly property color line:  m.line
    readonly property color shade: m.shade
    readonly property color onPastel: "#1e1916"

    readonly property var pastels: ({
        pink: "#f6a9a9", rose: "#f7c3d6", blush: "#f4c7c3", coral: "#f7a48b",
        peach: "#f8b984", apricot: "#f9cfa0", butter: "#f6e7a1", yellow: "#f1d27c",
        sage: "#cfd8b4", green: "#c2d69b", mint: "#b8e6cf", aqua: "#a8dadc",
        sky: "#bfe1f6", blue: "#a7c6ea", periwinkle: "#b9c2f2", lavender: "#c9c2f0",
        lilac: "#d6b8ea", mauve: "#e3b5d2", sand: "#e2c2a5", mocha: "#d4b8a8"
    })
    readonly property var accentNames: ["pink", "rose", "blush", "coral", "peach", "apricot", "butter", "yellow",
                                        "sage", "green", "mint", "aqua", "sky", "blue", "periwinkle", "lavender",
                                        "lilac", "mauve", "sand", "mocha"]
    readonly property var cycle: [pastels.pink, pastels.rose, pastels.peach, pastels.yellow, pastels.green, pastels.blue, pastels.lilac]
    // "wallpaper" = picked from the current photo or video wallpaper
    readonly property bool autoAccent: Config.s.accent === "wallpaper"
    readonly property color accent: autoAccent ? (AutoColor.ready ? AutoColor.color : pastels.peach)
                                               : (pastels[Config.s.accent] ?? pastels.peach)
    readonly property color mic: "#f39a4a"
    readonly property color camera: "#7fc46a"
    readonly property color danger: pastels.pink

    readonly property int outline: Config.s.outline
    readonly property int shadow: Config.s.shadow
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
    readonly property var sizes: ({
        idle:       Qt.size(250 + batteryW, 38),
        nowplaying: Qt.size(400 + batteryW, 38),
        workspace:  Qt.size(300, 38),
        volume:     Qt.size(380, 60),
        brightness: Qt.size(420, 60),
        notif:      Qt.size(460, 104),
        launcher:   Qt.size(600, 440),
        windows:    Qt.size(760, 176),
        hub:        Qt.size(880, 520)
    })
}
