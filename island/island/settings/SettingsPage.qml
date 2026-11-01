import QtQuick
import QtQuick.Controls
import qs.services
import qs.theme
import qs.components

// iOS-style: category list → one panel per category. Search covers every option.
Item {
    id: root

    readonly property var categories: [
        { label: "Appearance", icon: "palette", tint: Theme.pastels.pink, comp: appearanceC,
          opts: ["Surface", "Dark Mode", "Grey", "Accent", "Outline", "Shadow", "Corners", "Font", "Press Effect"] },
        { label: "Motion", icon: "animation", tint: Theme.pastels.peach, comp: motionC,
          opts: ["Speed", "Springy", "Jiggle"] },
        { label: "Pill", icon: "rounded_corner", tint: Theme.pastels.yellow, comp: pillC,
          opts: ["Hover Open", "Hover Delay", "Left Side", "Now Playing", "Gap Everywhere", "Workspace", "Volume", "Popup Time", "Scroll Volume", "Slider Scroll", "Switch Delay", "Top Gap", "Window Gap"] },
        { label: "Clock", icon: "schedule", tint: Theme.pastels.green, comp: clockC,
          opts: ["24-Hour", "Seconds"] },
        { label: "Alerts", icon: "notifications", tint: Theme.pastels.rose, comp: notifC,
          opts: ["Popups", "Popup Time", "Focus"] },
        { label: "Media", icon: "music_note", tint: Theme.pastels.blue, comp: mediaC,
          opts: ["Visualizer", "Bars", "Camera Light"] },
        { label: "Lock & Saver", icon: "lock", tint: Theme.pastels.lilac, comp: lockC,
          opts: ["Built-in Lock", "Saver After", "Lock After", "Wait for Media", "Wait for Calls", "Wait for Fullscreen", "Keep Awake", "Lock Media", "Saver Clock", "Animation", "Lock Displays", "Saver Displays", "Glass", "Blur", "Tint", "Fallback Lock", "Stuck Lock"] },
        { label: "Recording", icon: "screen_record", tint: Theme.pastels.coral, comp: recordC,
          opts: ["Mic", "Desktop Sound", "Mode", "FPS", "Folder"] },
        { label: "Wallpaper", icon: "image", tint: Theme.pastels.sand, comp: wallpaperC,
          opts: ["Photo Folder", "Video Folder", "Transition"] },
        { label: "Profile", icon: "account_circle", tint: Theme.pastels.blue, comp: profileC,
          opts: ["Name", "Picture"] },
        { label: "Launcher", icon: "search", tint: Theme.pastels.peach, comp: launcherC,
          opts: ["File Search", "Engine", "Backup"] },
        { label: "Commands", icon: "terminal", tint: Theme.pastels.green, comp: commandsC,
          opts: ["Sleep", "Reboot", "Power", "Screenshot", "Night On", "Night Off"] },
        { label: "Shortcuts", icon: "keyboard", tint: Theme.pastels.yellow, comp: shortcutsC,
          opts: ["How to Bind"] },
        { label: "About", icon: "info", tint: Theme.pastels.rose, comp: aboutC,
          opts: ["Needs", "Settings File"] }
    ]

    function open(cat) { stack.push(cat.comp); }

    StackView {
        id: stack
        anchors.fill: parent
        clip: true
        initialItem: homeC

        pushEnter: Transition {
            NumberAnimation { property: "x"; from: stack.width * 0.25; to: 0; duration: Theme.dur(220); easing.type: Easing.OutCubic }
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dur(180) }
        }
        pushExit: Transition { NumberAnimation { property: "opacity"; to: 0; duration: Theme.dur(120) } }
        popEnter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dur(180) } }
        popExit: Transition {
            NumberAnimation { property: "x"; to: stack.width * 0.25; duration: Theme.dur(200); easing.type: Easing.InCubic }
            NumberAnimation { property: "opacity"; to: 0; duration: Theme.dur(180) }
        }
    }

    // ── category list + search ──
    Component {
        id: homeC
        Item {
            id: home
            readonly property string q: search.text.trim().toLowerCase()
            readonly property var hits: {
                if (!q) return [];
                const out = [];
                root.categories.forEach(c => c.opts.forEach(o => {
                    if (o.toLowerCase().includes(q) || c.label.toLowerCase().includes(q)) out.push({ cat: c, opt: o });
                }));
                return out;
            }

            PField {
                id: search
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                icon: "search"
                placeholder: "Search"
            }

            PScroll {
                anchors.top: search.bottom
                anchors.topMargin: 14
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: 8

                Repeater {
                    model: home.q ? [] : root.categories
                    delegate: SLink {
                        required property var modelData
                        icon: modelData.icon
                        label: modelData.label
                        tint: modelData.tint
                        onClicked: root.open(modelData)
                    }
                }
                Repeater {
                    model: home.hits
                    delegate: SLink {
                        required property var modelData
                        icon: modelData.cat.icon
                        label: modelData.opt
                        hint: modelData.cat.label
                        tint: modelData.cat.tint
                        onClicked: root.open(modelData.cat)
                    }
                }
                PText {
                    visible: home.q !== "" && home.hits.length === 0
                    text: "No Matches"
                    color: Theme.sub
                }
            }
        }
    }

    // ── pages ──
    Component {
        id: appearanceC
        SPage {
            title: "Appearance"
            SurfacePicker {}
            SLink {
                icon: "palette"
                label: "Accent"
                hint: Config.s.accent === "wallpaper" ? "Wallpaper" : Config.s.accent.charAt(0).toUpperCase() + Config.s.accent.slice(1)
                tint: Theme.accent
                onClicked: stack.push(accentC)
            }
            SSlider { label: "Outline"; key: "outline"; from: 0; to: 4; step: 1; suffix: "px" }
            SSlider { label: "Shadow"; key: "shadow"; from: 0; to: 8; step: 1; suffix: "px" }
            SSlider { label: "Corners"; key: "radius"; from: 4; to: 24; step: 1; suffix: "px" }
            SText { label: "Font"; key: "fontFamily"; placeholder: "JetBrains Mono" }
            SToggle { label: "Press Effect"; key: "pressEffect" }
        }
    }
    Component {
        id: motionC
        SPage {
            title: "Motion"
            SSlider { label: "Speed"; key: "animSpeed"; from: 0.5; to: 2; step: 0.1; suffix: "×" }
            SToggle { label: "Springy"; key: "springy" }
            SToggle { label: "Jiggle"; key: "jiggle" }
        }
    }
    Component {
        id: pillC
        SPage {
            title: "Pill"
            SToggle { label: "Hover Open"; key: "openOnHover" }
            SSlider { label: "Hover Delay"; key: "hoverDelay"; from: 100; to: 1000; step: 50; suffix: "ms" }
            SChoice {
                label: "Left Side"
                key: "idleLeft"
                options: [{ v: "avatar", l: "Picture" }, { v: "workspace", l: "Workspace" }]
            }
            SToggle { label: "Now Playing"; key: "nowPlayingInPill" }
            SToggle { label: "Workspace"; key: "workspaceFlash" }
            SToggle { label: "Volume"; key: "osdVolume" }
            SSlider { label: "Popup Time"; key: "osdTimeout"; from: 800; to: 4000; step: 100; suffix: "ms" }
            SToggle { label: "Scroll Volume"; key: "pillScrollVolume" }
            SToggle { label: "Slider Scroll"; key: "sliderWheel" }
            SSlider { label: "Switch Delay"; hint: "ALT + Tab"; key: "switchDelay"; from: 300; to: 1500; step: 50; suffix: "ms" }
            SSlider { label: "Top Gap"; key: "topGap"; from: 0; to: 24; step: 1; suffix: "px" }
            SToggle { label: "Gap Everywhere"; hint: "Off: windows move with the island"; key: "reserveAll" }
            SSlider { label: "Window Gap"; key: "windowGap"; from: 0; to: 30; step: 1; suffix: "px" }
        }
    }
    Component {
        id: clockC
        SPage {
            title: "Clock"
            SToggle { label: "24-Hour"; key: "use24h" }
            SToggle { label: "Seconds"; key: "showSeconds" }
        }
    }
    Component {
        id: notifC
        SPage {
            title: "Alerts"
            SToggle { label: "Popups"; key: "notifPopups" }
            SSlider { label: "Popup Time"; key: "notifTimeout"; from: 2000; to: 15000; step: 500; suffix: "ms" }
            SToggle { label: "Focus"; hint: "Mutes popups"; key: "dnd" }
        }
    }
    Component {
        id: mediaC
        SPage {
            title: "Media"
            SToggle { label: "Visualizer"; key: "visualizer" }
            SSlider { label: "Bars"; key: "visualizerBars"; from: 8; to: 32; step: 1 }
            SToggle { label: "Camera Light"; key: "cameraIndicator" }
        }
    }
    Component {
        id: lockC
        SPage {
            title: "Lock & Saver"
            SToggle { label: "Built-in Lock"; key: "builtinLock" }
            SSlider { label: "Saver After"; hint: "0 = off"; key: "saverAfter"; from: 0; to: 60; step: 1; suffix: "min" }
            SSlider { label: "Lock After"; hint: "0 = off"; key: "lockAfter"; from: 0; to: 120; step: 1; suffix: "min" }
            SToggle { label: "Wait for Media"; hint: "Music or video playing"; key: "pauseForMedia" }
            SToggle { label: "Wait for Calls"; hint: "Mic or camera in use"; key: "pauseForCalls" }
            SToggle { label: "Wait for Fullscreen"; hint: "Games, fullscreen video"; key: "pauseForFullscreen" }
            SRow {
                label: "Right Now"
                hint: Awake.reason ? "Waiting: " + Awake.reason : "Counting down"
                PToggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Awake.keepAwake
                    tint: Theme.pastels.yellow
                    onToggled: Awake.keepAwake = !Awake.keepAwake
                }
            }
            SToggle { label: "Lock Media"; key: "lockMedia" }
            SToggle { label: "Saver Clock"; key: "saverClock" }
            SToggle { label: "Animation"; key: "lockAnim" }
            SDisplays { label: "Lock Displays"; key: "lockDisplays" }
            SDisplays { label: "Saver Displays"; key: "saverDisplays" }
            SToggle { label: "Glass"; key: "lockGlass" }
            SSlider { label: "Blur"; key: "glassBlur"; from: 0; to: 1; step: 0.05 }
            SSlider { label: "Tint"; key: "glassTint"; from: 0; to: 1; step: 0.05 }
            SText { label: "Fallback Lock"; key: "lockCmd"; fieldWidth: 300; placeholder: "hyprlock or swaylock" }
            SLink { icon: "help"; label: "Stuck Lock"; tint: Theme.pastels.yellow; onClicked: stack.push(stuckC) }
        }
    }
    Component {
        id: stuckC
        SPage {
            title: "Stuck Lock"
            HelpCard {
                text: "If the lock ever freezes or Quickshell crashes while locked:\n\n" +
                      "1. Press Ctrl + Alt + F2 and log in.\n" +
                      (Compositor.kind === "hyprland"
                        ? "2. Run:  hyprctl --instance 0 'keyword misc:allow_session_lock_restore 1'\n" +
                          "3. Run:  hyprctl --instance 0 'dispatch exec quickshell'\n"
                        : "2. Run:  pkill -x quickshell   (the screen stays locked)\n" +
                          "3. Start it again inside your session, e.g. with MangoWM:\n" +
                          "   WAYLAND_DISPLAY=wayland-0 quickshell -d\n" +
                          "   If that can't take the lock back, log out with:  pkill -x mango\n") +
                      "4. Press Ctrl + Alt + F1 (or F7) to go back and unlock.\n\n" +
                      "If the built-in lock can't load, Fallback Lock runs instead (empty = hyprlock or swaylock). " +
                      "Settings → About shows why it didn't load."
            }
        }
    }
    Component {
        id: wallpaperC
        SPage {
            title: "Wallpaper"
            SText { label: "Photo Folder"; key: "photoDir" }
            SText { label: "Video Folder"; key: "videoDir" }
            SChoice {
                label: "Transition"
                key: "transition"
                options: [{ v: "grow", l: "Grow" }, { v: "fade", l: "Fade" }, { v: "wipe", l: "Wipe" }, { v: "none", l: "None" }]
            }
        }
    }
    Component {
        id: recordC
        SPage {
            title: "Recording"
            SToggle { label: "Mic"; hint: "Your default microphone"; key: "recordMic" }
            SToggle { label: "Desktop Sound"; hint: "Everything you hear"; key: "recordDesktop" }
            SChoice {
                label: "Mode"
                key: "recordMode"
                options: [{ v: "screen", l: "Screen" }, { v: "region", l: "Region" }]
            }
            SChoice {
                label: "FPS"
                key: "recordFps"
                options: [{ v: 30, l: "30" }, { v: 60, l: "60" }]
            }
            SText { label: "Folder"; key: "recordDir" }
            SRow {
                label: "Last"
                hint: Recorder.lastFile.replace(Config.home, "~")
                visible: Recorder.lastFile !== ""
                PButton { icon: "folder_open"; text: "Open"; onClicked: Recorder.openFolder() }
            }
        }
    }
    Component {
        id: accentC
        AccentPage {}
    }
    Component {
        id: pictureC
        PicturePage {}
    }
    Component {
        id: profileC
        SPage {
            title: "Profile"
            SText { label: "Name"; key: "userName"; placeholder: "Login name" }
            SLink {
                icon: "account_circle"
                label: "Picture"
                hint: Config.s.avatar || "~/.face"
                tint: Theme.pastels.blue
                onClicked: stack.push(pictureC)
            }
        }
    }
    Component {
        id: launcherC
        SPage {
            title: "Launcher"
            SToggle { label: "File Search"; hint: "Start with /"; key: "launcherFiles" }
            SText { label: "Engine"; hint: "Your server, ends in ?q="; key: "searchEngine"; fieldWidth: 360; placeholder: "https://…/search?q=" }
            SText { label: "Backup"; hint: "If Engine is down, and ! bangs"; key: "backupEngine"; fieldWidth: 360 }
        }
    }
    Component {
        id: commandsC
        SPage {
            title: "Commands"
            SText { label: "Sleep"; key: "sleepCmd"; fieldWidth: 380 }
            SText { label: "Reboot"; key: "rebootCmd"; fieldWidth: 380 }
            SText { label: "Power"; key: "poweroffCmd"; fieldWidth: 380 }
            SText { label: "Screenshot"; key: "screenshotCmd"; fieldWidth: 380; placeholder: "Automatic: " + Compositor.screenshotCmd("region").replace(/^sh '.*\//, "").replace(/'/g, "") }
            SText { label: "Night On"; key: "nightOnCmd"; fieldWidth: 380; placeholder: "Automatic: " + Compositor.nightCmd(true) }
            SText { label: "Night Off"; key: "nightOffCmd"; fieldWidth: 380; placeholder: "Automatic: " + Compositor.nightCmd(false) }
        }
    }
    Component {
        id: shortcutsC
        SPage {
            title: "Shortcuts"
            Repeater {
                model: [
                    ["Launcher", "toggleLauncher"], ["Home", "toggleHub"], ["Control", "toggleControl"],
                    ["Sound", "sound"], ["Alerts", "notifications"], ["Wallpaper", "wallpaper"], ["Settings", "settings"],
                    ["Windows", "windows"], ["Windows Back", "windowsPrev"],
                    ["Focus", "dnd"], ["Mic", "micmute"], ["Night", "nightlight"], ["Screenshot", "screenshot region"],
                    ["Record", "record"], ["Record Region", "recordRegion"],
                    ["Keep Awake", "awake"], ["Lock", "lock"], ["Saver", "saver"], ["Close", "close"]
                ]
                delegate: SRow {
                    required property var modelData
                    label: modelData[0]
                    PText { text: modelData[1]; color: Theme.sub; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            SLink { icon: "help"; label: "How to Bind"; tint: Theme.pastels.yellow; onClicked: stack.push(howToC) }
        }
    }
    Component {
        id: howToC
        SPage {
            title: "How to Bind"
            HelpCard {
                text: "1. Test in a terminal first:\n" +
                      "   quickshell ipc call island launcher\n" +
                      "   If the search opens, the island works and only the binds need fixing.\n\n" +
                      "2. Add the binds to your compositor config, then reload.\n\n" +
                      "Hyprland (Lua config):\n" +
                      "local function island(cmd) return hl.dsp.exec_cmd(\"quickshell ipc call island \" .. cmd) end\n" +
                      "hl.bind(\"ALT + Space\", island(\"launcher\"))\n" +
                      "hl.bind(\"SUPER + S\", island(\"sound\"))\n" +
                      "hl.bind(\"SUPER + L\", island(\"lock\"))\n" +
                      "hl.bind(\"SUPER + C\", island(\"control\"))\n" +
                      "hl.bind(\"SUPER + W\", island(\"wallpaper\"))\n\n" +
                      "MangoWM (config.conf):\n" +
                      "bind=ALT,space,spawn,quickshell ipc call island launcher\n" +
                      "bind=SUPER,s,spawn,quickshell ipc call island sound\n" +
                      "bind=SUPER,l,spawn,quickshell ipc call island lock\n" +
                      "bind=SUPER,c,spawn,quickshell ipc call island control\n" +
                      "bind=SUPER,w,spawn,quickshell ipc call island wallpaper\n\n" +
                      "Any name from the Shortcuts list works. Press the same key again to close."
            }
        }
    }
    Component {
        id: aboutC
        SPage {
            title: "About"
            SRow { label: "Island"; PText { text: "2.0"; color: Theme.sub; anchors.verticalCenter: parent.verticalCenter } }
            SRow {
                label: "Compositor"
                hint: Compositor.backendError
                PText { text: Compositor.label; color: Theme.sub; anchors.verticalCenter: parent.verticalCenter }
            }
            SRow { label: "Settings File"; PText { text: "~/.config/island/settings.json"; color: Theme.sub; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter } }
            SRow {
                label: "Lock"
                hint: LockState.lockError
                PText { text: LockState.sessionReady ? "Built-in" : "Fallback"; color: Theme.sub; anchors.verticalCenter: parent.verticalCenter }
            }
            SRow {
                label: "Idle Timers"
                hint: LockState.idleError
                PText { text: LockState.idleReady ? "On" : "Off"; color: Theme.sub; anchors.verticalCenter: parent.verticalCenter }
            }
            SRow {
                label: "Video"
                hint: Wallpaper.videoError
                PText { text: Wallpaper.videoOk ? "On" : "Off"; color: Theme.sub; anchors.verticalCenter: parent.verticalCenter }
            }
            SLink { icon: "inventory_2"; label: "Needs"; tint: Theme.pastels.green; onClicked: stack.push(depsC) }
        }
    }
    Component {
        id: depsC
        SPage {
            title: "Needs"
            Repeater {
                model: [
                    ["Core", "quickshell, pipewire, Hyprland or MangoWM"],
                    ["MangoWM", "mmsg (comes with mango) for tags"],
                    ["Network", "networkmanager"],
                    ["Visualizer", "cava"],
                    ["Videos", "qt multimedia, ffmpegthumbnailer"],
                    ["Lock", "pam"],
                    ["Web Search", "curl, xdg-utils"],
                    ["Launcher", "wl-clipboard, fd"],
                    ["Camera Light", "psmisc"],
                    ["Screenshot", "Hyprland: hyprshot · others: grim, slurp, wl-clipboard"],
                    ["Night Light", "Hyprland: hyprsunset · others: wlsunset"],
                    ["Recording", "wf-recorder, slurp, pipewire-pulse"],
                    ["Accent", "ffmpegthumbnailer for videos"],
                    ["Laptop", "brightnessctl, bluez"]
                ]
                delegate: SRow {
                    required property var modelData
                    label: modelData[0]
                    hint: modelData[1]
                }
            }
        }
    }
}
