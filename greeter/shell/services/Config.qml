pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Read-only copy of your island settings. island-greeter-sync writes
// user/settings.json (next to this folder) with every file path already
// pointing inside user/files/, because the greeter account can't see ~.
// The greeter never writes it back.
Singleton {
    id: root

    readonly property string base: Qt.resolvedUrl("..").toString().replace(/^file:\/\//, "").replace(/\/$/, "")
    readonly property string userDir: base + "/user"
    readonly property string file: userDir + "/settings.json"
    property bool loaded: false
    property alias s: adapter

    readonly property string home: userDir
    function expand(p) { return p || ""; }

    FileView {
        path: root.file
        watchChanges: true                     // a sync while the greeter is up shows right away
        onFileChanged: reload()
        onLoaded: root.loaded = true
        onLoadFailed: root.loaded = true       // defaults still give a working login

        JsonAdapter {
            id: adapter

            // written by island-greeter-sync
            property string greeterUser: ""
            property string greeterSession: ""     // Exec line to start by default ("" = guess)
            property string desktop: ""            // compositor you were using when synced (hyprland | mango)
            property string accentFile: ""         // image the Wallpaper accent is picked from
            property var desktopPhotos: ({})       // { "DP-1": "/etc/.../files/x.jpg" } for the photo fallback

            // copied from the island (same names, same meaning)
            property string surface: "cream"
            property string accent: "peach"
            property int outline: 2
            property int shadow: 4
            property int radius: 14
            property string fontFamily: "JetBrains Mono"
            property bool pressEffect: true
            property real animSpeed: 1.0
            property bool use24h: false
            property bool showSeconds: false
            property string userName: ""
            property string avatar: ""
            property string lockBg: ""
            property string lockBgKind: "photo"
            property var lockDisplays: []
            property bool lockAnim: true
            property bool lockGlass: true
            property real glassBlur: 0.8
            property real glassTint: 0.45
        }
    }
}
