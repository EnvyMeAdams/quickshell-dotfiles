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
          opts: ["Visualizer", "Bars", "Camera Light", "Spotify", "Lyrics in Pill", "Canvas", "Heart", "Up Next", "Song Change", "Port"] },
        { label: "Messages", icon: "chat", tint: Theme.pastels.mint, comp: messagesC,
          opts: ["Signal", "Link This Computer", "Start signal-cli", "Popups", "Previews", "Lock Screen Previews", "Read Receipts", "Typing", "Focus Allows", "Reactions", "Hide Signal Desktop Alerts", "Forget Account", "Fluxer", "Fluxer Popups", "Muted Words"] },
        { label: "Tailscale", icon: "hub", tint: Theme.pastels.aqua, comp: tailscaleC,
          opts: ["Hub Tab", "Exit Node Activity", "Exit Node Offline", "Pill Flag", "Taildrop", "Taildrop Folder", "Set Up"] },
        { label: "Sounds", icon: "volume_up", tint: Theme.pastels.mint, comp: soundsC,
          opts: ["Sounds", "Volume", "Sound Folder", "How It Works"].concat(Sounds.events.map(e => e.l)) },
        { label: "Home", icon: "home", tint: Theme.pastels.peach, comp: homeSetC,
          opts: ["Battery", "Tray", "Confirm Power"] },
        { label: "Display", icon: "brightness_medium", tint: Theme.pastels.butter, comp: displayC,
          opts: ["Brightness", "Night Light", "Warmth", "Brightness Popup", "Desktop Monitors"] },
        { label: "Lock & Saver", icon: "lock", tint: Theme.pastels.lilac, comp: lockC,
          opts: ["Built-in Lock", "Saver After", "Lock After", "Wait for Media", "Wait for Calls", "Wait for Fullscreen", "Apps", "Grace", "Lock Waits for Music", "Keep Awake", "Lock Media", "Saver Clock", "Animation", "Lock Displays", "Saver Displays", "Glass", "Blur", "Tint", "Fallback Lock", "Stuck Lock", "Fingerprint", "Listen For", "Hint For", "Lock Checks", "Popup for Permissions", "Popup Position", "Swipes", "Wait For", "doas", "App Prompts"] },
        { label: "Recording", icon: "screen_record", tint: Theme.pastels.coral, comp: recordC,
          opts: ["Mic", "Desktop Sound", "Mode", "FPS", "Folder"] },
        { label: "Wallpaper", icon: "image", tint: Theme.pastels.sand, comp: wallpaperC,
          opts: ["Photo Folder", "Video Folder", "Transition"] },
        { label: "Profile", icon: "account_circle", tint: Theme.pastels.blue, comp: profileC,
          opts: ["Name", "Picture"] },
        { label: "Launcher", icon: "search", tint: Theme.pastels.peach, comp: launcherC,
          opts: ["File Search", "Engine", "Backup"] },
        { label: "Commands", icon: "terminal", tint: Theme.pastels.green, comp: commandsC,
          opts: ["Log Out", "Sleep", "Reboot", "Power", "Screenshot", "Night On", "Night Off"] },
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
            SLink {
                icon: "graphic_eq"
                label: "Spotify"
                hint: !Config.s.spotifyBridge ? "Off" : Spotify.loadError ? Spotify.loadError
                    : Spotify.connected ? "Connected to Spicetify" : "Waiting for Spicetify"
                tint: Theme.pastels.green
                onClicked: stack.push(spotifyC)
            }
        }
    }
    Component {
        id: spotifyC
        SPage {
            title: "Spotify"
            SToggle { label: "Spicetify Bridge"; hint: "Extras from extras/spicetify/island-bridge.js"; key: "spotifyBridge" }
            SToggle { label: "Lyrics in Pill"; hint: "Synced lines replace the song title"; key: "spotifyLyricsPill" }
            SToggle { label: "Canvas"; hint: "The song's looping video behind the media card"; key: "spotifyCanvas" }
            SToggle { label: "Heart"; hint: "Like button on the media card"; key: "spotifyHeart" }
            SToggle { label: "Up Next"; key: "spotifyUpNext" }
            SToggle { label: "Song Change"; hint: "Pill shows the new song briefly"; key: "spotifyToast" }
            SSlider { label: "Port"; hint: "Same as PORT in island-bridge.js"; key: "spotifyPort"; from: 47700; to: 47799; step: 1 }
            SRow {
                label: "Right Now"
                hint: Spotify.loadError || (Spotify.connected ? (Spotify.synced ? "Synced lyrics" : Spotify.lines.length ? "Lyrics (not synced)" : "No lyrics for this song")
                                                              + (Spotify.canvas ? " · Canvas" : "") : "Spotify not connected")
            }
            SLink { icon: "help"; label: "How to Set Up"; tint: Theme.pastels.yellow; onClicked: stack.push(spotifyHelpC) }
        }
    }
    Component {
        id: spotifyHelpC
        SPage {
            title: "Spotify Setup"
            HelpCard {
                text: "Play, pause, skip and album art already work with any Spotify (through MPRIS). " +
                      "Spicetify adds the heart, synced lyrics, Canvas and Up Next.\n\n" +
                      "1. Install Spotify and Spicetify. On Gentoo, Spotify lives in /opt/spotify and Spicetify needs to write there once:\n" +
                      "   doas chmod a+wr /opt/spotify /opt/spotify/Apps -R\n" +
                      "   spicetify config spotify_path /opt/spotify\n\n" +
                      "2. Copy the bridge from this repo and turn it on:\n" +
                      "   cp ~/quickshell-dotfiles/extras/spicetify/island-bridge.js ~/.config/spicetify/Extensions/\n" +
                      "   spicetify config extensions island-bridge.js\n" +
                      "   spicetify backup apply\n\n" +
                      "3. Quickshell needs QtWebSockets: doas emerge --ask dev-qt/qtwebsockets, then restart Quickshell.\n\n" +
                      "After every Spotify update (emerge), run: spicetify backup apply. Otherwise the update quietly removes it.\n\n" +
                      "The bridge only listens on 127.0.0.1 (this computer). Canvas uses Spotify's internal API, " +
                      "so an update can break it; the card then simply shows no video."
            }
        }
    }
    Component {
        id: messagesC
        SPage {
            title: "Messages"
            SLink {
                icon: "chat"
                label: "Signal"
                hint: Signal.connected ? "Connected" : Config.s.signalAccount ? (Config.s.signalOn ? "Connecting…" : "Off") : "Not linked"
                tint: Theme.pastels.mint
                onClicked: stack.push(signalC)
            }
            SToggle { label: "Popups"; hint: "Message card in the pill"; key: "msgPopups" }
            SToggle { label: "Previews"; hint: "Off: just \"New Message\""; key: "msgPreviews" }
            SToggle { label: "Lock Screen Previews"; key: "msgLockPreviews" }
            SToggle { label: "Typing"; hint: "Show when someone is typing"; key: "msgTyping" }
            SWords { label: "Focus Allows"; hint: "Names that still pop up during Focus"; key: "msgAllow"; placeholder: "Mom, Alex" }
            SText { label: "Reactions"; hint: "Up to five, separated by spaces"; key: "msgReactions"; fieldWidth: 200 }
            SLink {
                icon: "forum"
                label: "Fluxer"
                hint: !Config.s.fluxerStyle ? "Off" : Notifs.fluxerCount + " in Alerts"
                tint: Theme.pastels.lavender
                onClicked: stack.push(fluxerC)
            }
        }
    }
    Component {
        id: signalC
        SPage {
            title: "Signal"
            SToggle { label: "Signal"; hint: Config.s.signalAccount ? Config.s.signalAccount : "Link first (below)"; key: "signalOn" }
            SToggle { label: "Start signal-cli"; hint: "Off if you run your own daemon"; key: "signalDaemon" }
            SText { label: "Socket"; hint: "Empty = the island's own"; key: "signalSocket"; placeholder: "$XDG_RUNTIME_DIR/island-signal.sock" }
            SText { label: "signal-cli"; hint: "Command or full path"; key: "signalCli"; fieldWidth: 240 }
            SToggle { label: "Read Receipts"; hint: "Sent when you open a chat"; key: "msgReceipts" }
            SToggle { label: "Hide Signal Desktop Alerts"; hint: "While the island is connected"; key: "signalHideDesktop" }
            SLink { icon: "qr_code_2"; label: "Link & Set Up"; tint: Theme.pastels.yellow; onClicked: stack.push(signalSetupC) }
            SRow {
                visible: Config.s.signalAccount !== ""
                label: "Forget Account"
                hint: "Then remove \"Island\" under Linked Devices on your phone"
                PButton {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Forget"
                    tint: Theme.pastels.pink
                    checked: true
                    onClicked: Signal.unlink()
                }
            }
        }
    }
    Component {
        id: signalSetupC
        SPage {
            title: "Link Signal"
            SignalSetup { width: parent.width }
        }
    }
    Component {
        id: fluxerC
        SPage {
            title: "Fluxer"
            SToggle { label: "Fluxer"; hint: "Own look for Fluxer alerts + a Messages tab"; key: "fluxerStyle" }
            SToggle { label: "Fluxer Popups"; key: "fluxerPopups" }
            SWords { label: "Muted Words"; hint: "Alerts containing any stay silent (servers, channels)"; key: "fluxerMuted"; placeholder: "#memes, Big Server" }
            SLink { icon: "help"; label: "How It Works"; tint: Theme.pastels.yellow; onClicked: stack.push(fluxerHelpC) }
        }
    }
    Component {
        id: fluxerHelpC
        SPage {
            title: "Fluxer"
            HelpCard {
                text: "The island reads the alerts the Fluxer desktop app already sends, so there's no token or login to set up, " +
                      "and nothing extra talks to Fluxer's servers.\n\n" +
                      "Fluxer alerts get a lilac Fluxer badge, count in the pill's chat bubble, and appear under Messages › Fluxer. " +
                      "Clicking one in the pill jumps into the app.\n\n" +
                      "Muted Words: alerts containing any of them are kept in Alerts but don't pop up or make a sound, " +
                      "e.g. a busy server's name or #channel.\n\n" +
                      "Limits: the Fluxer app has to be running, and replies happen in the app. " +
                      "Note that Fluxer isn't end-to-end encrypted, so keep private chats on Signal."
            }
        }
    }
    Component {
        id: tailscaleC
        SPage {
            title: "Tailscale"
            SRow {
                label: "Status"
                hint: !Tailscale.installed ? "Not installed" : !Tailscale.daemon ? "tailscaled not running"
                    : (Tailscale.up ? "Connected" : Tailscale.state || "Off") + (Tailscale.isOperator ? "" : " · operator not set")
            }
            SToggle { label: "Hub Tab"; hint: "Off: open it from the Control tile"; key: "tsTab" }
            SToggle { label: "Exit Node Activity"; hint: "\"Connected via …\" in the pill"; key: "tsActivity" }
            SToggle { label: "Exit Node Offline"; hint: "Warns when traffic stops going through it"; key: "tsLostAlert" }
            SToggle { label: "Pill Flag"; hint: "Tiny flag while on an exit node"; key: "tsPillFlag" }
            SToggle { label: "Taildrop"; hint: "Save files sent to this device"; key: "tsTaildrop" }
            SText { label: "Taildrop Folder"; key: "tsTaildropDir"; fieldWidth: 240 }
            SLink { icon: "help"; label: "Set Up"; tint: Theme.pastels.yellow; onClicked: stack.push(tsHelpC) }
        }
    }
    Component {
        id: tsHelpC
        SPage {
            title: "Set Up Tailscale"
            TsHelp { width: parent.width }
        }
    }
    Component {
        id: awakeAppsC
        AwakeAppsPage {}
    }
    Component {
        id: homeSetC
        SPage {
            title: "Home"
            SChoice {
                label: "Battery"
                hint: Battery.present ? "Battery found: " + Battery.percent + "%" : "No battery found"
                key: "showBattery"
                options: [{ v: "auto", l: "Auto" }, { v: "on", l: "On" }, { v: "off", l: "Off" }]
            }
            SLink {
                visible: Battery.present
                icon: "battery_charging_full"
                label: "Charging Popup"
                hint: !Config.s.chargePopup ? "Off"
                    : Config.s.chargePopupUnplug ? "Plug In & Unplug" : "When Plugged In"
                tint: Theme.pastels.green
                onClicked: stack.push(chargeC)
            }
            SToggle { label: "Tray"; hint: "App icons, top right"; key: "showTray" }
            SToggle { label: "Confirm Power"; hint: "Click twice for Log Out, Reboot, Power"; key: "powerConfirm" }
        }
    }
    Component {
        id: chargeC
        SPage {
            title: "Charging Popup"
            SToggle { label: "Charging Popup"; hint: "Middle of the screen when you plug in"; key: "chargePopup" }
            SToggle { label: "Also When Unplugged"; hint: "Shows On Battery"; key: "chargePopupUnplug" }
            SSlider { label: "Show For"; key: "chargePopupTime"; from: 1; to: 8; step: 1; suffix: "s" }
            SChoice {
                label: "Position"
                key: "chargePopupPos"
                options: [{ v: "center", l: "Middle" }, { v: "upper", l: "Upper" }]
            }
            SToggle { label: "Fill Animation"; hint: "Battery fills up to your level"; key: "chargePopupFill" }
            SToggle { label: "Glow"; hint: "Ring and shine while charging"; key: "chargePopupGlow" }
            SRow {
                label: "Right Now"
                hint: Battery.percent + "% · " + (Battery.pluggedIn ? (Battery.status || "Plugged In") : "On Battery")
            }
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
            SLink {
                icon: "apps"
                label: "Apps"
                hint: (Config.s.awakeApps ?? []).map(r => r.app).join(", ") || "None"
                tint: Theme.pastels.butter
                onClicked: stack.push(awakeAppsC)
            }
            SSlider { label: "Grace"; hint: "Keep waiting after it ends"; key: "awakeGrace"; from: 0; to: 120; step: 5; suffix: "s" }
            SToggle { label: "Lock Waits for Music"; key: "lockWaitsForMusic" }
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
            SLink {
                visible: Fingerprint.reader
                icon: "fingerprint"
                label: "Fingerprint"
                hint: !Config.s.lockFingerprint ? "Off"
                    : Fingerprint.fingers > 0 ? "On" : "No finger set up"
                tint: Theme.pastels.mint
                onClicked: stack.push(fingerprintC)
            }
            SToggle { label: "Glass"; key: "lockGlass" }
            SSlider { label: "Blur"; key: "glassBlur"; from: 0; to: 1; step: 0.05 }
            SSlider { label: "Tint"; key: "glassTint"; from: 0; to: 1; step: 0.05 }
            SText { label: "Fallback Lock"; key: "lockCmd"; fieldWidth: 300; placeholder: "hyprlock or swaylock" }
            SLink { icon: "help"; label: "Stuck Lock"; tint: Theme.pastels.yellow; onClicked: stack.push(stuckC) }
        }
    }
    Component {
        id: soundsC
        SPage {
            title: "Sounds"
            SToggle { label: "Sounds"; hint: "Off mutes every island sound"; key: "soundsOn" }
            SSlider { label: "Volume"; key: "soundVolume"; from: 0; to: 1; step: 0.05 }
            // one row per event; fingerprint and battery ones only where they can happen
            Repeater {
                model: Sounds.events.filter(e => (!e.fp || Fingerprint.reader) && (!e.battery || Battery.present))
                delegate: SLink {
                    required property var modelData
                    icon: modelData.i
                    label: modelData.l
                    hint: Sounds.nameFor(modelData.k) || ("None" + (modelData.h ? " · " + modelData.h : ""))
                    tint: Sounds.fileFor(modelData.k) ? Theme.pastels.mint : Theme.card
                    onClicked: stack.push(soundPickC, { event: modelData.k, title: modelData.l })
                }
            }
            SText { label: "Sound Folder"; hint: "Where the browser starts"; key: "soundDir" }
            SLink { icon: "help"; label: "How It Works"; tint: Theme.pastels.yellow; onClicked: stack.push(soundsHelpC) }
        }
    }
    Component {
        id: soundPickC
        SoundPicker {}
    }
    Component {
        id: soundsHelpC
        SPage {
            title: "How It Works"
            HelpCard {
                text: "Every event starts with no sound. Pick a file for the ones you want: " +
                      "click a file to use it (you'll hear it), ▶ plays it without choosing, None turns it off.\n\n" +
                      "Formats: mp3, ogg, wav, flac, m4a, opus. Short files (under 2 seconds) work best.\n\n" +
                      "Keep your sounds in one folder (Sound Folder) so the browser opens there. " +
                      "Files stay where they are; Settings only remembers their path, so moving or renaming " +
                      "a file silences that event until you pick it again.\n\n" +
                      "Notifications follow Do Not Disturb (critical ones still sound). A fingerprint unlock " +
                      "with its own sound skips the Unlock sound. With Recording › Desktop Sound on, the " +
                      "Recording Start sound can end up at the very start of the video.\n\n" +
                      (Sounds.qtOk ? "Plays through Qt Multimedia."
                                   : "Qt Multimedia isn't available, so sounds play with pw-play (PipeWire). " +
                                     "If mp3 files stay silent, use ogg or wav.")
            }
        }
    }
    Component {
        id: fingerprintC
        SPage {
            title: "Fingerprint"
            SToggle { label: "Use Fingerprint"; hint: "Unlock the lock screen with a finger"; key: "lockFingerprint" }
            SSlider { label: "Listen For"; hint: "Then move the mouse or tap the icon"; key: "fpListen"; from: 10; to: 180; step: 5; suffix: "s" }
            SSlider { label: "Hint For"; hint: "Help line under the password · 0 = always"; key: "fpHintFor"; from: 0; to: 30; step: 1; suffix: "s" }
            SRow {
                label: "Reader"
                hint: (Fingerprint.device || "Found") + " · " +
                      (Fingerprint.fingers === 1 ? "1 finger" : Fingerprint.fingers + " fingers")
            }
            SRow {
                visible: Fingerprint.fingers > 0
                label: "Lock Checks"
                hint: Fingerprint.lockUses + (Fingerprint.swipe && Fingerprint.fingers > 1 ? " (first in the list)" : "")
            }
            SLink { icon: "help"; label: "How to Set Up"; tint: Theme.pastels.yellow; onClicked: stack.push(fingerprintHelpC) }

            // doas + app permission prompts (polkit)
            SToggle { label: "Popup for Permissions"; hint: "doas and app prompts asking for your finger"; key: "fpPopup" }
            SChoice {
                label: "Popup Position"
                key: "fpPopupPos"
                options: [{ v: "upper", l: "Upper" }, { v: "center", l: "Middle" }]
            }
            SSlider { label: "Swipes"; hint: "doas and app prompts, then the password"; key: "fpPamTries"; from: 1; to: 5; step: 1 }
            SSlider { label: "Wait For"; hint: "Without a finger, then the password"; key: "fpPamWait"; from: 5; to: 30; step: 1; suffix: "s" }
            SRow { label: "doas"; hint: FingerprintWatch.pamDoas ? "Fingerprint on" : "Password only" }
            SRow { label: "App Prompts"; hint: FingerprintWatch.pamPolkit ? "Fingerprint on" : "Password only" }
            SLink { icon: "terminal"; label: "Set Up doas & App Prompts"; tint: Theme.pastels.yellow; onClicked: stack.push(fingerprintPamC) }
            Component.onCompleted: FingerprintWatch.checkPam()
        }
    }
    Component {
        id: fingerprintPamC
        SPage {
            title: "doas & App Prompts"
            HelpCard {
                readonly property string s: Compositor.scripts.replace(Config.home, "~") + "/fingerprint-pam.sh"
                text: "Lets doas and app permission prompts (polkit) take your fingerprint. " +
                      "You get " + Config.s.fpPamTries + (Config.s.fpPamTries === 1 ? " swipe" : " swipes") +
                      "; after " + Config.s.fpPamWait + " seconds without a finger, or that many misses, it asks for " +
                      "your password as usual (Swipes and Wait For change this). In a terminal, press any key to go straight to the " +
                      "password (what you typed is thrown away, so type it again at the prompt). " +
                      "Permission windows can't skip: the password comes after the wait.\n\n" +
                      "Turn it on (in a terminal):\n" +
                      "   doas sh " + s + " install\n\n" +
                      "Check:   sh " + s + " status\n" +
                      "Turn it off:   doas sh " + s + " remove\n\n" +
                      "Test:   doas -L; doas true\n\n" +
                      "What it changes: copies a small helper, root-owned, to " +
                      "/usr/local/libexec/island-fingerprint-auth, and adds one line to /etc/pam.d/doas " +
                      "and /etc/pam.d/polkit-1 (each backed up once to .island-bak; if polkit's file only " +
                      "exists in /usr/lib/pam.d, a marked copy is made in /etc/pam.d and removed again " +
                      "on remove). Your password " +
                      "always still works. It only checks your own account and never runs over SSH.\n\n" +
                      "Before changing PAM files, keep a root shell open in another terminal " +
                      "(doas -s) until you've tested it."
            }
        }
    }
    Component {
        id: fingerprintHelpC
        SPage {
            title: "How to Set Up"
            HelpCard {
                text: "The lock screen listens for a finger as soon as it appears. Start typing to use " +
                      "your password instead. The login screen always uses your password; doas and app " +
                      "prompts can use your finger too (Set Up doas & App Prompts).\n\n" +
                      "Set up a finger (in a terminal):\n" +
                      "   fprintd-enroll\n" +
                      "   fprintd-enroll -f left-index-finger   (another finger)\n\n" +
                      "Test it:   fprintd-verify\n" +
                      "Start over:   fprintd-delete $USER\n\n" +
                      (Fingerprint.swipe
                        ? "Swipe sensor tips: start at the first crease of your finger, pull down " +
                          "smoothly in about a second, flat and straight. Too fast reads as \"too short\".\n\n" +
                          "Some swipe sensors only check the first finger in the list (fprintd-list shows it). " +
                          "If another one works better, delete the ones above it.\n\n"
                        : "") +
                      "Needs fprintd (with PAM support). The island hides all of this on machines without a reader."
            }
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
        id: displayC
        SPage {
            title: "Display"
            SRow {
                label: "Brightness"
                hint: Brightness.mode === "ddc" ? "Monitors over DDC" : Brightness.available ? "" : "Nothing to control found"
                PSlider {
                    width: 220
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: Brightness.available
                    value: Brightness.value
                    tint: Theme.pastels.butter
                    onMoved: v => Brightness.set(v)
                }
                PText { width: 44; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter; text: Math.round(Brightness.value * 100) + "%"; font.bold: true; font.pixelSize: 12 }
            }
            SRow {
                label: "Night Light"
                PToggle {
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Config.s.nightLight
                    tint: Theme.pastels.coral
                    onToggled: NightLight.toggle()
                }
            }
            SRow {
                label: "Warmth"
                hint: Config.s.nightLight ? "Changes live" : "Turn Night Light on to preview"
                PText { anchors.verticalCenter: parent.verticalCenter; text: "Cool"; font.pixelSize: 11; color: Theme.sub }
                PSlider {
                    width: 200
                    anchors.verticalCenter: parent.verticalCenter
                    value: NightLight.warmth
                    tint: Theme.pastels.coral
                    onMoved: v => NightLight.setWarmth(v)
                }
                PText { anchors.verticalCenter: parent.verticalCenter; text: "Red"; font.pixelSize: 11; color: Theme.sub }
                PText { width: 52; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter; text: Config.s.nightTemp + "K"; font.bold: true; font.pixelSize: 12 }
            }
            SToggle { label: "Brightness Popup"; hint: "Show changes in the pill"; key: "osdBrightness" }
            SToggle { label: "Desktop Monitors"; hint: "Uses ddcutil (restart to apply)"; key: "ddcBrightness" }
        }
    }
    Component {
        id: commandsC
        SPage {
            title: "Commands"
            SText { label: "Log Out"; key: "logoutCmd"; fieldWidth: 380; placeholder: Compositor.logoutCmd() }
            SText { label: "Sleep"; key: "sleepCmd"; fieldWidth: 380 }
            SText { label: "Reboot"; key: "rebootCmd"; fieldWidth: 380 }
            SText { label: "Power"; key: "poweroffCmd"; fieldWidth: 380 }
            SText { label: "Screenshot"; key: "screenshotCmd"; fieldWidth: 380; placeholder: "Automatic: " + Compositor.screenshotCmd("region").replace(/^sh '.*\//, "").replace(/'/g, "") }
            SText { label: "Night On"; hint: "Leave empty to use Warmth; {temp} = Warmth in K"; key: "nightOnCmd"; fieldWidth: 380; placeholder: "Automatic" }
            SText { label: "Night Off"; key: "nightOffCmd"; fieldWidth: 380; placeholder: "Automatic" }
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
                    ["Sounds", "qt multimedia (else pw-play from pipewire)"],
                    ["Fingerprint", "fprintd (with pam), only on machines with a reader"],
                    ["Web Search", "curl, xdg-utils"],
                    ["Launcher", "wl-clipboard, fd"],
                    ["Camera Light", "psmisc"],
                    ["Screenshot", "Hyprland: hyprshot · others: grim, slurp, wl-clipboard"],
                    ["Night Light", "Hyprland: hyprsunset · others: wlsunset"],
                    ["Recording", "wf-recorder, slurp, pipewire-pulse"],
                    ["Accent", "ffmpegthumbnailer for videos"],
                    ["Laptop", "brightnessctl, bluez"],
                    ["Tailscale", "tailscale (net-vpn/tailscale), operator set once"],
                    ["Signal", "signal-cli + Java 25, qrencode"],
                    ["Spotify", "spicetify, qt websockets (dev-qt/qtwebsockets)"],
                    ["Fluxer", "the Fluxer desktop app"]
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
