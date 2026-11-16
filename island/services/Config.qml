pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// All user settings live OUTSIDE the code folder (~/.config/island/settings.json)
// so replacing ~/.config/quickshell never wipes your choices.
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string dir: home + "/.config/island"
    readonly property string file: dir + "/settings.json"
    property bool ready: false
    property alias s: adapter

    readonly property string profileName: s.userName || Quickshell.env("USER") || "you"
    readonly property string profilePic: "file://" + (s.avatar ? expand(s.avatar) : home + "/.face")

    function expand(p) {
        if (!p) return "";
        return p.startsWith("~") ? home + p.slice(1) : p;
    }

    Process {
        running: true
        command: ["sh", "-c", "mkdir -p \"$1\" && { [ -s \"$2\" ] || echo '{}' > \"$2\"; }", "sh", root.dir, root.file]
        onExited: root.ready = true
    }

    FileView {
        path: root.ready ? root.file : ""
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        // old default folder name
        onLoaded: {
            if (adapter.videoDir === "~/Video/Wallpapers") adapter.videoDir = "~/Videos/Wallpapers";
            // the old 5 / 10 minute defaults were too eager
            if (adapter.idleVersion < 1) {
                if (adapter.saverAfter === 5) adapter.saverAfter = 15;
                if (adapter.lockAfter === 10) adapter.lockAfter = 20;
                adapter.idleVersion = 1;
            }
            // gap follows the island (like the old island did)
            if (adapter.darkMode) { adapter.surface = "cocoa"; adapter.darkMode = false; }
            if (adapter.layoutVersion < 1) { adapter.reserveAll = false; adapter.layoutVersion = 1; }
            // old builds saved their default night light commands into settings,
            // which then overrode the Warmth slider; clear those (not your own)
            const oldNight = ["hyprsunset -t 4500", "pkill -x hyprsunset", "wlsunset -T 4501 -t 4500", "pkill -x wlsunset"];
            if (oldNight.includes((adapter.nightOnCmd ?? "").trim())) adapter.nightOnCmd = "";
            if (oldNight.includes((adapter.nightOffCmd ?? "").trim())) adapter.nightOffCmd = "";
        }

        JsonAdapter {
            id: adapter

            // Appearance
            property bool darkMode: false            // old setting, replaced by surface
            property string look: "smoke"            // smoke | clear | classic (the cream cards)
            property string surface: "cream"         // cream | fog | slate | cocoa (classic look)
            property bool frost: true                // glass looks: blur the wallpaper behind the pill
            property real frostBlur: 0.7
            property string accent: "peach"
            property int outline: 2
            property int shadow: 4
            property int radius: 14
            property string fontFamily: "JetBrains Mono"
            property bool pressEffect: true

            // Motion
            property real animSpeed: 1.0
            property bool springy: true
            property bool jiggle: true

            // Pill
            property bool openOnHover: false
            property int hoverDelay: 350
            property bool nowPlayingInPill: true
            property bool workspaceFlash: true
            property string idleLeft: "avatar"       // avatar | workspace
            property bool reserveAll: false
            property int layoutVersion: 0
            property bool osdVolume: true
            property int osdTimeout: 1600
            property bool pillScrollVolume: false
            property bool sliderWheel: false
            property int switchDelay: 650
            property int topGap: 8
            property int windowGap: 8

            // Clock
            property bool use24h: false
            property bool showSeconds: false

            // Notifications
            property bool notifPopups: true
            property int notifTimeout: 5000
            property bool dnd: false

            // Media
            property bool visualizer: true
            property int visualizerBars: 16

            // Privacy
            property bool cameraIndicator: true

            // Profile
            property string userName: ""
            property string avatar: ""

            // Wallpaper
            property string photoDir: "~/Pictures/Wallpapers"
            property string videoDir: "~/Videos/Wallpapers"
            property string transition: "grow"
            // per display: { "*": {path, kind}, "DP-1": {path, kind} }
            property var desktop: ({})
            property string lockBg: ""
            property string lockBgKind: "photo"
            property string saverVideo: ""
            property var lockDisplays: []           // empty = every display
            property var saverDisplays: []          // empty = every display

            // Lock & Saver
            property bool builtinLock: true
            property int saverAfter: 15             // minutes, 0 = off
            property int lockAfter: 20              // minutes, 0 = off
            property bool pauseForMedia: true
            property bool pauseForCalls: true
            property bool pauseForFullscreen: true
            property bool lockWaitsForMusic: false
            property int awakeGrace: 30              // seconds to keep waiting after a video/call ends
            property var awakeApps: [{ "app": "firefox", "when": "sound" }]
            property int idleVersion: 0
            property bool lockMedia: true
            property bool saverClock: true
            property bool lockAnim: true
            property bool lockGlass: true
            property bool lockFingerprint: true     // only matters with a reader + enrolled finger
            property int fpListen: 60                // seconds the lock listens before it rests
            property int fpHintFor: 6                // seconds the resting hint stays (0 = always)
            property bool fpPopup: true              // popup when doas / app prompts ask for a finger
            property string fpPopupPos: "upper"      // upper | center
            property int fpPamTries: 2               // doas / app prompts: swipes before the password (1-5)
            property int fpPamWait: 10               // doas / app prompts: seconds without a finger (5-30)

            // Sounds (your own files; every event starts silent)
            property bool soundsOn: true
            property real soundVolume: 0.7
            property var sounds: ({})                // event key -> file, e.g. { "lock": "~/Music/Sounds/lock.mp3" }
            property string soundDir: "~/Music"      // where the sound browser starts
            property real glassBlur: 0.8
            property real glassTint: 0.45

            // Recording
            property bool recordMic: true
            property bool recordDesktop: true
            property string recordMode: "screen"     // screen | region
            property string recordDir: "~/Videos/Recordings"
            property int recordFps: 60

            // Launcher
            property bool launcherFiles: true
            property string searchEngine: ""          // your own, e.g. a SearXNG ".../search?q="
            property string backupEngine: "https://duckduckgo.com/?q="

            // Home
            property string showBattery: "auto"      // auto | on | off
            property bool chargePopup: true          // middle card when the charger goes in (laptops)
            property bool chargePopupUnplug: false   // also when it comes out
            property int chargePopupTime: 3          // seconds on screen
            property string chargePopupPos: "center" // center | upper
            property bool chargePopupFill: true      // battery fills up to your level
            property bool chargePopupGlow: true      // breathing ring + light sweep while charging
            property bool showTray: true
            property bool powerConfirm: true
            property string powerMenuLayout: "horizontal"   // horizontal | vertical
            property int powerMenuDim: 45                   // % the screen darkens behind it
            property bool powerMenuHints: true              // keyboard hints + numbers
            property var powerMenuOrder: ["lock", "saver", "sleep", "logout", "reboot", "poweroff"]
            property var powerMenuHidden: []

            // Tailscale (only shows if tailscale is installed)
            property bool tsTab: true                // its own tab in the hub
            property bool tsActivity: true           // "Connected via …" when the exit node changes
            property bool tsLostAlert: true          // warning when the exit node goes offline
            property bool tsPillFlag: false          // tiny flag in the pill while on an exit node
            property bool tsTaildrop: false          // save files sent to this device
            property string tsTaildropDir: "~/Downloads"

            // Spotify (Spicetify bridge)
            property bool spotifyBridge: true
            property int spotifyPort: 47719
            property bool spotifyLyricsPill: true
            property bool spotifyCanvas: true
            property bool spotifyHeart: true
            property bool spotifyUpNext: true
            property bool spotifyToast: false        // pill shows the new song briefly

            // Commands
            property string logoutCmd: ""            // empty = automatic for your compositor
            property string lockCmd: ""              // fallback only; empty = hyprlock or swaylock
            property string sleepCmd: "loginctl suspend"
            property string rebootCmd: "loginctl reboot"
            property string poweroffCmd: "loginctl poweroff"
            // empty = automatic for your compositor (see services/Compositor.qml)
            property string screenshotCmd: ""
            property string nightOnCmd: ""
            property string nightOffCmd: ""
            property bool nightLight: false
            property int nightTemp: 3500             // Kelvin: 1500 very red … 6000 barely warm
            property bool osdBrightness: true
            property bool ddcBrightness: true        // desktop monitors via ddcutil
        }
    }
}
