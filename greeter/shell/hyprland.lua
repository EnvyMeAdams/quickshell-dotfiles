-- Hyprland for the login screen only (runs as the greetd account).
-- Your own ~/.config/hypr is not read here; island-greeter-sync copies
-- this machine's monitor layout and cursor into /etc/greetd/island/user/.

-- Monitors: this machine's layout (rotation, positions, refresh rates)
local synced = pcall(dofile, "/etc/greetd/island/user/monitors.lua")
if not synced then
  hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
end

-- Cursor: HYPRCURSOR_* / XCURSOR_* from your desktop
pcall(dofile, "/etc/greetd/island/user/cursor.lua")

hl.config({
  input = { follow_mouse = 1 },
  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    force_default_wallpaper = 0,
  },
  animations = { enabled = false },   -- the greeter animates itself
})

hl.on("hyprland.start", function ()
  hl.exec_cmd("/etc/greetd/island/run.sh")
end)
