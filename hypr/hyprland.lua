local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "thunar"
local browser = "zen-browser"

hl.monitor({ output = "eDP-1", mode = "1920x1080@60.050", position = "0x0", scale = 1.0 })
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })

hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
    windowrulev2 = {
        "float,class:(polkit-kde-authentication-agent-1)",
        "stayfocused,class:(polkit-kde-authentication-agent-1)",
        "pin,class:(polkit-kde-authentication-agent-1)",
        "dimaround,class:(polkit-kde-authentication-agent-1)",
    },
    input = {
        kb_layout = "us",
        repeat_rate = 50,
        repeat_delay = 300,
        follow_mouse = 1,
        natural_scroll = true,
        scroll_method = "on_button_down",
        scroll_button = 274,
        touchpad = {
            natural_scroll = false,
            tap_to_click = true,
            disable_while_typing = true,
            middle_button_emulation = true,
        }
    },
    cursor = {
        default_monitor = "eDP-1"
    },
})

hl.device({
    name = "synaptics-tm3276-022",
    natural_scroll = false,
})

hl.config({
    general = {
        -- Adjacent windows already contribute two 2px borders. A further
        -- inner gap made the centre seam wider than the screen-edge inset.
        gaps_in = 0,
        gaps_out = 0,
        border_size = 2,
        ["col.active_border"] = "rgb(7aa2f7)",
        ["col.inactive_border"] = "rgb(24283b)",
        layout = "dwindle",
    },
    dwindle = {
        preserve_split = true
    },
    decoration = {
        rounding = 10,
        dim_inactive = true,
        dim_strength = 0.15,
        blur = { enabled = false },
        shadow = { enabled = false },
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
    }
})

-- Bezier Curves & Animations
-- All transitions standardise on the macOS curve. Layer windows (Waybar/SwayNC)
-- should appear without a floating pop-in; normal app windows pop in with the
-- fluid curve, and leave opacity transitions disabled.
hl.curve("macOS", { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.animation({ leaf = "global",      enabled = true,  speed = 10,  bezier = "default" })
hl.animation({ leaf = "windows",     enabled = true,  speed = 6.5, bezier = "macOS", style = "popin 98%" })
hl.animation({ leaf = "windowsIn",   enabled = true,  speed = 6.5, bezier = "macOS", style = "popin 98%" })
hl.animation({ leaf = "windowsOut",  enabled = true,  speed = 8,   bezier = "macOS", style = "popin 94%" })
hl.animation({ leaf = "workspaces",  enabled = true,  speed = 7,   bezier = "macOS", style = "slide" })
hl.animation({ leaf = "border",      enabled = true,  speed = 8,   bezier = "macOS" })
hl.animation({ leaf = "fade",        enabled = true,  speed = 6,   bezier = "macOS" })
hl.animation({ leaf = "fadeOut",     enabled = true,  speed = 7,   bezier = "macOS" })
hl.animation({ leaf = "fadePopups",  enabled = false, speed = 1,   bezier = "default" })
hl.animation({ leaf = "fadeLayers",  enabled = false, speed = 1,   bezier = "default" })
hl.animation({ leaf = "layers",      enabled = false, speed = 1,   bezier = "default" })

hl.env("XCURSOR_THEME", "breeze_cursors")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GTK_THEME", "adw-gtk3-dark")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("GDK_BACKEND", "wayland,x11,*")

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("systemctl --user start xdg-desktop-portal-hyprland.service")
    hl.exec_cmd("swww-daemon || swaybg -i /home/dipak/code/arch-theme/wallpapers/satisfaction_waybar_blur.png -m fill")
    hl.exec_cmd("sleep 0.5 && swww img /home/dipak/code/arch-theme/wallpapers/satisfaction_waybar_blur.png --transition-type grow --transition-duration 1")
    hl.exec_cmd("QT_LOGGING_RULES=\"quickshell.network.warning=false\" qs --no-duplicate")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("systemctl --user start plasma-polkit-agent || /usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("wl-paste --type text --watch clipse -wl-store")
    hl.exec_cmd("wl-paste --type image --watch clipse -wl-store")
    hl.exec_cmd("sway-audio-idle-inhibit")
    hl.exec_cmd("gsettings set org.gnome.desktop.wm.preferences button-layout ':close'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface text-scaling-factor 1.0")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-theme breeze_cursors")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface cursor-size 24")
    hl.exec_cmd("gsettings set org.gnome.desktop.sound theme-name Pop")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme TokyoNight-SE")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface font-name 'IBM Plex Sans SmBld 10'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface document-font-name 'IBM Plex Sans SmBld 10'")
    hl.exec_cmd("gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font SemBd 10'")
    hl.exec_cmd("sh -c '$HOME/code/arch-theme/quickshell/scripts/brightness.sh restore 2>/dev/null || true'")
end)

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + D", hl.dsp.global("quickshell:apps"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("zeditor"))
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd("zeditor -n"))
hl.bind(mainMod .. " + V", hl.dsp.global("quickshell:clipboard"))
hl.bind(mainMod .. " + period", hl.dsp.global("quickshell:emoji"))
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("sh -c '$HOME/code/arch-theme/hypr/scripts/toggle_osk.sh'"))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd(terminal .. " -e btop"))
hl.bind(mainMod .. " + N", hl.dsp.global("quickshell:notifications"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.global("quickshell:dismissAll"))
hl.bind(mainMod .. " + BackSpace", hl.dsp.global("quickshell:dismissAll"))

hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(0))
hl.bind(mainMod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + S", hl.dsp.group.toggle())
hl.bind(mainMod .. " + W", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())

-- Sway's focus mode toggle has no exact Hyprland equivalent. Cycle between
-- the tiled and floating layers while preserving the same Super+Space muscle memory.
hl.bind(mainMod .. " + Space", function()
    local active = hl.get_active_window()
    if active == nil then
        return
    end

    hl.dispatch(hl.dsp.window.cycle_next({ floating = not active.floating }))
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- Dwindle has no parent containers; cycling tiled windows is the closest useful action.
hl.bind(mainMod .. " + A", hl.dsp.window.cycle_next({ floating = false }))

hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + Left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + Down", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + Up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + Right", hl.dsp.focus({ direction = "r" }))

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + Left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + Down", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + SHIFT + Up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "r" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("mouse:275", hl.dsp.focus({ workspace = "m-1" }))
hl.bind("mouse:276", hl.dsp.focus({ workspace = "m+1" }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.window.move({ workspace = "special:scratchpad" }))
hl.bind(mainMod .. " + minus", hl.dsp.workspace.toggle_special("scratchpad"))

hl.bind(mainMod .. " + SHIFT + S", hl.dsp.global("quickshell:screenshot"))
hl.bind("Print", hl.dsp.global("quickshell:screenshot"))
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("sh -c '$HOME/.config/hypr/screenshot.sh full'"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.global("quickshell:recorder"))

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("sh -c '$HOME/code/arch-theme/quickshell/scripts/brightness.sh step_down 5%'"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("sh -c '$HOME/code/arch-theme/quickshell/scripts/brightness.sh step_up 5%'"), { locked = true, repeating = true })

hl.bind(mainMod .. " + R", hl.dsp.submap("resize"))
hl.on("keybinds.submap", function(map)
    if map == "resize" then
        hl.bind("Right", hl.dsp.window.resize({ x = 10, y = 0 }), { repeating = true })
        hl.bind("Left", hl.dsp.window.resize({ x = -10, y = 0 }), { repeating = true })
        hl.bind("Up", hl.dsp.window.resize({ x = 0, y = -10 }), { repeating = true })
        hl.bind("Down", hl.dsp.window.resize({ x = 0, y = 10 }), { repeating = true })
        hl.bind("L", hl.dsp.window.resize({ x = 10, y = 0 }), { repeating = true })
        hl.bind("H", hl.dsp.window.resize({ x = -10, y = 0 }), { repeating = true })
        hl.bind("K", hl.dsp.window.resize({ x = 0, y = -10 }), { repeating = true })
        hl.bind("J", hl.dsp.window.resize({ x = 0, y = 10 }), { repeating = true })
        hl.bind("Return", hl.dsp.submap("reset"))
        hl.bind("Escape", hl.dsp.submap("reset"))
    end
end)

hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("sh -c '$HOME/.config/hypr/scripts/hot_reload.sh'"))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.global("quickshell:power"))

-- Dynamic Display Scaling Shortcuts (as per Hyprland's preferred scale steps)
local scale_steps = { 1.0, 1.2, 1.25, 1.5 }

local function set_display_scale(target_scale)
    hl.monitor({ output = "eDP-1", mode = "1920x1080@60.050", position = "0x0", scale = target_scale })
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = target_scale })
    hl.notification.create({
        text = string.format("Display Scale: %.2fx", target_scale),
        time = 1800,
        color = "rgba(57, 197, 187, 1.0)"
    })
end

local function cycle_scale()
    local monitors = hl.get_monitors()
    local current = (monitors[1] and monitors[1].scale) or 1.0
    current = math.floor(current * 100 + 0.5) / 100

    local current_idx = 1
    local min_diff = 999
    for i, s in ipairs(scale_steps) do
        local diff = math.abs(s - current)
        if diff < min_diff then
            min_diff = diff
            current_idx = i
        end
    end

    local next_idx = current_idx + 1
    if next_idx > #scale_steps then
        next_idx = 1
    end

    set_display_scale(scale_steps[next_idx])
end

hl.bind(mainMod .. " + equal", cycle_scale)

hl.window_rule({ name = "swappy-float", match = { class = "^(swappy)$" }, float = true })
hl.window_rule({ name = "pavucontrol-float", match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true, size = "450 265", move = "875 0" })
hl.window_rule({ name = "clipse-float", match = { class = "^(clipse)$" }, float = true, size = "800 600", center = true })
hl.window_rule({ name = "idle_inhibit", match = { class = "^(.*)$" }, idle_inhibit = "fullscreen" })
