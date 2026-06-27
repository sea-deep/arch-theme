<h1 align="center">
  <br>
  🌊 Miku × Tokyo Night — Arch Linux Sway Dotfiles
  <br>
</h1>

<p align="center">
  <b>A meticulously crafted, Hatsune Miku–inspired Sway desktop environment built on the Tokyo Night color palette.</b>
</p>

<p align="center">
  <a href="#-quick-start"><img src="https://img.shields.io/badge/Arch-Linux-1793d1?style=for-the-badge&logo=archlinux&logoColor=white" alt="Arch Linux"></a>
  <a href="#-components"><img src="https://img.shields.io/badge/WM-SwayFX-39c5bb?style=for-the-badge" alt="SwayFX"></a>
  <a href="#-color-palette"><img src="https://img.shields.io/badge/Theme-Tokyo%20Night-1a1b26?style=for-the-badge" alt="Tokyo Night"></a>
</p>

---

## 🖼️ Wallpaper

![Miku Wallpaper](wallpapers/satisfaction_hires_final.png)

---

## 📑 Table of Contents

- [Quick Start](#-quick-start)
- [Color Palette](#-color-palette)
- [Typography](#-typography)
- [Components](#-components)
  - [Sway (Window Manager)](#sway-window-manager)
  - [Waybar (Status Bar)](#waybar-status-bar)
  - [Rofi (App Launcher)](#rofi-app-launcher)
  - [Kitty (Terminal)](#kitty-terminal)
  - [Swaync (Notifications)](#swaync-notifications)
  - [Lemurs (Login Screen)](#lemurs-login-screen)
  - [Swaylock (Lock Screen)](#swaylock-lock-screen)
  - [Wlogout (Logout Menu)](#wlogout-logout-menu)
  - [Btop (System Monitor)](#btop-system-monitor)
  - [Starship (Shell Prompt)](#starship-shell-prompt)
  - [GTK Theming](#gtk-theming)
  - [Fontconfig (Browser Fonts)](#fontconfig-browser-fonts)
  - [Qt Theming](#qt-theming)
- [Custom Scripts](#-custom-scripts)
- [Keybindings](#-keybindings)
- [Directory Structure](#-directory-structure)
- [Customization Guide](#-customization-guide)
- [Credits](#-credits)

---

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/sea-deep/arch-theme.git ~/code/arch-theme
cd ~/code/arch-theme

# Run the installer (do NOT run as root)
chmod +x install.sh
./install.sh
```

The installer will:
1. Configure Pacman parallel downloads, enable the `multilib` repository, and set up the `chaotic-aur` pre-compiled repository.
2. Install `yay` (AUR helper) if missing.
3. Install all required packages via `yay`.
4. Back up any existing configs to `*.bak` (and prevent nested backups).
5. Symlink everything from this repo into `~/.config/`.
6. Set up Lemurs display manager, TLP, and systemd services.
7. Optionally configure fingerprint authentication.

> **Note:** After installation, reboot or log out to enter your new Sway session.

---

## 🎨 Color Palette

Every component in this dotfiles collection uses the same unified color palette, derived from **Tokyo Night** and accented with **Miku Teal**.

| Role | Hex | Preview | Used In |
|------|-----|---------|---------|
| **Base Background** | `#1a1b26` | 🟫 | Everywhere — Sway, Waybar, Kitty, Rofi, Lemurs |
| **Deep Background** | `#15161e` | ⬛ | Waybar borders, Rofi panel backgrounds |
| **Surface / Gutter** | `#414868` | 🔘 | Unfocused UI elements, dim text |
| **Miku Teal (Primary)** | `#39c5bb` | 🟩 | Focused borders, active workspace, accents |
| **Bright Teal** | `#33e0e0` | 🟦 | Hover states, Waybar border glow |
| **Sky Cyan** | `#7dcfff` | 🔵 | Links, secondary highlights, unfocused labels |
| **Blue** | `#7aa2f7` | 🔷 | Focused input labels, secondary accents |
| **Purple** | `#bb9af7` | 🟣 | Sway indicator color |
| **Red / Error** | `#f7768e` | 🔴 | Urgent windows, battery critical, muted audio |
| **Yellow / Warning** | `#e0af68` | 🟡 | Warning states |
| **Foreground** | `#c0caf5` | ⬜ | Primary text color |
| **Soft Foreground** | `#a9b1d6` | 🩶 | Secondary text, environment switcher |

> **To re-theme the entire desktop**, you only need to search-and-replace these hex codes across the config files. Every component references them directly — there are no magic variables or indirection layers.

---

## ✏️ Typography

This setup uses **two font families** with a strict separation of concerns:

| Context | Font | Weight | Where to Change |
|---------|------|--------|-----------------|
| **System UI** | IBM Plex Sans | SemiBold (600) | `sway/config` line 10, `gtk-3.0/settings.ini`, `gtk-4.0/settings.ini` |
| **Monospace / Code** | FiraCode Nerd Font | SemiBold (600) | `kitty/kitty.conf` line 6, `waybar/style.css` line 4 |

### Font Fallback Chain (Fontconfig)

The file `fontconfig/conf.d/99-user-fonts.conf` ensures that **all applications** (including web browsers) resolve generic font families to your chosen fonts:

| Generic Family | Resolves To |
|---------------|-------------|
| `sans-serif` | IBM Plex Sans |
| `serif` | IBM Plex Serif |
| `monospace` | FiraCode Nerd Font |

> **To change the system font**, update the font name in the files listed above AND update `fontconfig/conf.d/99-user-fonts.conf` to match.

---

## 🧩 Components

### Sway (Window Manager)

**Config:** [`sway/config`](sway/config)

The heart of the desktop. SwayFX is used (not vanilla Sway) for blur and rounded corners.

| Setting | Value | Line |
|---------|-------|------|
| Font | `IBM Plex Sans SemiBold 10` | 10 |
| Mod Key | `Super` (Mod4) | 45 |
| Terminal | `kitty` | 52 |
| Launcher | `rofi` (via `rofi-manager.sh`) | 54 |
| Browser | `zen-browser` | 58 |
| File Manager | `thunar` | 56 |
| Wallpaper | `wallpapers/satisfaction_hires_final.png` | 65 |
| Display | 1920×1080 @ 60Hz, scale 1.25 | 66 |
| Border Width | 2px (no titlebars) | 30 |
| Corner Radius | 10px | 32 |
| Gaps (inner) | 2px | 70 |
| Gaps (outer) | 1px | 71 |
| Blur | Enabled, radius 7, passes 4 (frosted glass) | 41–43 |
| Shadows | Enabled, radius 20, color `#15161ecc` | 44–46 |
| Inactive Dimming | Enabled, 15% dim | 48–49 |

**Window Border Colors** (lines 35–39):

| State | Border | Background | Text |
|-------|--------|------------|------|
| Focused | `#39c5bb` | `#39c5bb` | `#1a1b26` |
| Focused Inactive | `#414868` | `#414868` | `#c0caf5` |
| Unfocused | `#24283b` | `#24283b` | `#a9b1d6` |
| Urgent | `#f7768e` | `#f7768e` | `#c0caf5` |

**Cursor Theme** (lines 13–15):

| Setting | Value |
|---------|-------|
| Theme | `breeze_cursors` |
| Size | 24 |

> **To change wallpaper:** Replace the PNG at `wallpapers/satisfaction_hires_final.png` or edit line 65.
> **To change display scaling:** Edit the `scale` value on line 66.
> **To change gaps:** Edit lines 70–71.

---

### Waybar (Status Bar)

**Config:** [`waybar/config`](waybar/config) · **Style:** [`waybar/style.css`](waybar/style.css)

A top-mounted, rounded-pill-style bar with transparent spacing between modules.

**Layout:**
```
┌─────────────────────────────────────────────────────────┐
│ [Workspaces] [Window]    [Clock]    [Tray] [🔔] [HW] [⏻] │
└─────────────────────────────────────────────────────────┘
```

| Module | Content | Click Action |
|--------|---------|--------------|
| **Workspaces** | Workspace numbers | Switch workspace |
| **Window** | Focused window title | — |
| **Clock** | `HH:MM AM/PM · Mon DD` | Tooltip: Calendar |
| **Tray** | System tray icons | — |
| **Notifications (🔔)** | Swaync indicator | Toggle notification panel |
| **Hardware Group** | Audio / Brightness / Battery | See below |
| **Power (⏻)** | Power icon | Opens Rofi power menu |

**Hardware Group Actions:**

| Sub-module | Click | Middle-Click | Scroll |
|------------|-------|-------------|--------|
| Audio | Toggle Pavucontrol popup | Mute/Unmute | — |
| Brightness | — | Toggle idle inhibitor | Adjust brightness ±1% |
| Battery | Open TLP power profile menu | — | — |

**Styling Quick Reference** (`waybar/style.css`):

| Property | Value | Line |
|----------|-------|------|
| Font | `FiraCode Nerd Font` | 4 |
| Font Weight | 600 (SemiBold) | 5 |
| Font Size | 14px | 6 |
| Module Background | `#1a1b26` | 23 |
| Module Border | `2px solid #15161e` | 27 |
| Module Border Radius | 12px | 26 |
| Hover Border | `2px solid #33e0e0` | 63 |
| Active Workspace BG | `#39c5bb` | 82 |
| Active Workspace Text | `#1a1b26` | 83 |

> **To change the bar font:** Edit `waybar/style.css` line 4.
> **To change module layout:** Edit the `modules-left/center/right` arrays in `waybar/config`.
> **To change accent color:** Replace `#39c5bb` and `#33e0e0` in `waybar/style.css`.

---

### Rofi (App Launcher)

**Config:** [`rofi/config.rasi`](rofi/config.rasi) · **Power Menu:** [`rofi/powermenu.rasi`](rofi/powermenu.rasi)

Rofi is used for three functions, all managed through [`sway/rofi-manager.sh`](sway/rofi-manager.sh):

| Function | Keybinding | Mode |
|----------|-----------|------|
| App Launcher | `Super + D` | `drun` |
| Clipboard History | `Super + V` | `clipboard` |
| Emoji Picker | `Super + .` | `emoji` |

**Key Customization Points** (`rofi/config.rasi`):

| Setting | Value |
|---------|-------|
| Font | `IBM Plex Sans SmBld 13` |
| Icon Theme | `TokyoNight-SE` |
| Display Columns | 2 |
| Window Width | 600px |

> **To change the launcher font:** Edit the `font:` line in `rofi/config.rasi`.
> **To change launcher width/columns:** Edit the `configuration` block in `rofi/config.rasi`.

---

### Kitty (Terminal)

**Config:** [`kitty/kitty.conf`](kitty/kitty.conf)

| Setting | Value | Line |
|---------|-------|------|
| Font | `FiraCode Nerd Font` | 6 |
| Font Size | 13pt | 10 |
| Padding | 12px | 14 |
| Opacity | 0.95 (95%) | 20 |
| Background | `#1a1b26` | 23 |
| Foreground | `#c0caf5` | 24 |
| Cursor | `#39c5bb` | 25 |
| Selection | Teal on dark | 27–28 |
| Window Decorations | Hidden | 16 |

**Terminal Color Map:**

| Index | Normal | Bright | Color |
|-------|--------|--------|-------|
| 0/8 | `#1a1b26` | `#414868` | Black/Gray |
| 1/9 | `#f7768e` | `#f7768e` | Red |
| 2/10 | `#39c5bb` | `#39c5bb` | Green (Miku Teal) |
| 3/11 | `#e0af68` | `#e0af68` | Yellow |
| 4/12 | `#7aa2f7` | `#7aa2f7` | Blue |
| 5/13 | `#bb9af7` | `#bb9af7` | Purple |
| 6/14 | `#7dcfff` | `#7dcfff` | Cyan |
| 7/15 | `#a9b1d6` | `#c0caf5` | White |

> **To change terminal transparency:** Edit line 20 (`background_opacity`).
> **To change terminal font size:** Edit line 10 (`font_size`).

---

### Swaync (Notifications)

**Config:** [`swaync/config.json`](swaync/config.json) · **Style:** [`swaync/style.css`](swaync/style.css)

Desktop notification daemon with a slide-out side panel.

> **To change notification styling:** Edit colors in `swaync/style.css`.
> **To change notification behavior:** Edit `swaync/config.json`.

---

### Lemurs (Login Screen)

**Config:** [`lemurs/config.toml`](lemurs/config.toml) · **PAM:** [`lemurs/pam`](lemurs/pam)

A minimal TUI-based display manager. Styled to match the Kitty terminal palette with all borders disabled.

| Setting | Value |
|---------|-------|
| Background | `#1a1b26` |
| Borders | All disabled |
| Focused Title | `#7aa2f7` (Blue) |
| Focused Content | `#c0caf5` (Foreground) |
| Unfocused Title | `#7dcfff` (Cyan) |
| Unfocused Content | `#414868` (Gray) |
| Environment Switcher Active | `#39c5bb` (Miku Teal) |
| Movers (Active) | `#39c5bb` |
| Error State | `#f7768e` (Red) |
| Password Char | `*` |
| Max Field Width | 48 |

**PAM Configuration:**

The login PAM stack requires a password on every login and automatically unlocks GNOME Keyring.

```
auth       include      system-local-login
auth       optional     pam_gnome_keyring.so       ← Unlocks keyring with login password
session    optional     pam_gnome_keyring.so auto_start
```

> **To change login colors:** Edit the hex values in `lemurs/config.toml`.
> **To re-enable borders:** Set `show_border = true` in the `[username_field.style]` and `[password_field.style]` sections.

---

### Swaylock (Lock Screen)

Swaylock is configured **inline via CLI flags** — there is no standalone `swaylock/config` file. The lock command and wallpaper path are defined in:
- [`sway/idle.sh`](sway/idle.sh) — auto-lock after idle timeout
- [`rofi/powermenu.sh`](rofi/powermenu.sh) — manual lock from power menu
- [`wlogout/layout`](wlogout/layout) — lock button in logout overlay

**Lock Wallpaper:** `~/Pictures/wallpapers/satisfaction_hires_lock_final.png`

Optional fingerprint unlock support is available via [`fingerprint/`](fingerprint/).

> **To change the lock wallpaper:** Update the image path in all three files listed above.

---

### Wlogout (Logout Menu)

**Layout:** [`wlogout/layout`](wlogout/layout) · **Style:** [`wlogout/style.css`](wlogout/style.css)

Fullscreen logout/power overlay triggered by the Rofi power menu.

> **To customize:** Edit button labels and actions in `wlogout/layout`, and styling in `wlogout/style.css`.

---

### Btop (System Monitor)

**Config:** [`btop/btop.conf`](btop/btop.conf) · **Theme:** [`btop/themes/miku-dark.theme`](btop/themes/miku-dark.theme)

Launched with `Super + Escape`. Uses a custom Miku Dark theme file.

> **To change btop colors:** Edit `btop/themes/miku-dark.theme`.

---

### Starship (Shell Prompt)

**Config:** [`starship.toml`](starship.toml)

Cross-shell prompt using a **powerline pill** style with Nerd Font icons.

**Prompt Layout:**
```
󰣇 dipak@arch  ~/code/project  dart flutter git:main  ❯
└── teal bg ──┘└── gray bg ──┘└── purple bg ─────────┘
```

| Segment | Background | Foreground |
|---------|-----------|------------|
| OS + User + Host | `#39c5bb` | `#1a1b26` |
| Directory | `#414868` | `#c0caf5` |
| Languages + Git | `#bb9af7` | `#1a1b26` |
| Success prompt char | — | `#39c5bb` ❯ |
| Error prompt char | — | `#f7768e` ❯ |

> **To customize the prompt:** Edit `starship.toml`. See [starship.rs](https://starship.rs) for docs.

---

### GTK Theming

**GTK-3:** [`gtk-3.0/`](gtk-3.0/) · **GTK-4:** [`gtk-4.0/`](gtk-4.0/)

| Setting | Value |
|---------|-------|
| GTK Theme | `adw-gtk3-dark` |
| Icon Theme | `TokyoNight-SE` |
| Cursor Theme | `breeze_cursors` |
| Font | `IBM Plex Sans SemiBold 10` |
| Sound Theme | `Pop` |
| Dark Mode | Enforced |

Custom color overrides are in `gtk-3.0/colors.css` and `gtk-4.0/colors.css`, using a Breeze-derived teal accent.

> **To change GTK font:** Edit `gtk-font-name` in both `gtk-3.0/settings.ini` and `gtk-4.0/settings.ini`.
> **To change icon theme:** Edit `gtk-icon-theme-name` in both settings files.

---

### Fontconfig (Browser Fonts)

**Config:** [`fontconfig/conf.d/99-user-fonts.conf`](fontconfig/conf.d/99-user-fonts.conf)

Forces all applications (especially web browsers) to resolve generic font families to your chosen fonts. Without this, browsers may fall back to Times New Roman.

Additional configs handle emoji rendering:
- `75-joypixels.conf` — JoyPixels emoji support
- `98-remove-mono-emojis.conf` — Strips monochrome emoji fallbacks
- `99-reject-google-emoji.conf` — Blocks Google Noto Color Emoji

> **To change browser fallback fonts:** Edit `fontconfig/conf.d/99-user-fonts.conf`.

---

### Qt Theming

**Config:** [`environment.d/qt-theming.conf`](environment.d/qt-theming.conf) · [`qt5ct/qt5ct.conf`](qt5ct/qt5ct.conf) · [`qt6ct/qt6ct.conf`](qt6ct/qt6ct.conf)

Environment variables force Qt apps to use `qt5ct`/`qt6ct` for consistent theming.

---

## 🔧 Custom Scripts

| Script | Location | Purpose | Triggered By |
|--------|----------|---------|-------------|
| `rofi-manager.sh` | `sway/` | Unified launcher for Rofi (drun/clipboard/emoji) | `Super+D`, `Super+V`, `Super+.` |
| `idle.sh` | `sway/` | Swayidle configuration: dim→lock→dpms off→suspend | Auto on Sway start |
| `hw-notifier.py` | `sway/` | Desktop notifications for USB/power events | Systemd service |
| `battery.sh` | `waybar/` | Custom battery display with TLP profile indicator | Waybar module |
| `pavu_toggle.sh` | `waybar/` | Pavucontrol popup with global Escape-to-close | Waybar audio click |
| `tlp_menu.sh` | `waybar/` | Rofi dropdown for TLP power profile switching | Waybar battery click |
| `toggle_idle.sh` | `waybar/` | Toggle idle inhibitor on/off | Backlight middle-click |
| `powermenu.sh` | `rofi/` | Rofi power menu (lock/logout/reboot/shutdown) | `Super+Power` button |
| `install-miku-tray-patch.sh` | `scripts/` | Patches system tray icons to Miku theme | Manual |
| `apply_frosted_glass.sh` | `scripts/` | Wallpaper generator (frosted glass + lockscreen) | Manual |

### Wallpaper Generator (`scripts/apply_frosted_glass.sh`)

An ImageMagick pipeline that takes **any wallpaper** and converts it into two theme-ready images:

1. **Desktop wallpaper** — with a frosted glass blur strip along all four edges (designed so Waybar and screen borders blend seamlessly into the wallpaper)
2. **Lock screen wallpaper** — a heavily blurred, darkened variant tinted with the Tokyo Night base color (`#1a1b26` at 60% opacity), downscaled to 1080p

**Requirements:** `imagemagick` must be installed (`sudo pacman -S imagemagick`).

**Usage:**
```bash
# Interactive mode
./scripts/apply_frosted_glass.sh

# CLI mode
./scripts/apply_frosted_glass.sh input.png output.png
```

**How the pipeline works:**

```
┌─────────────────────────────────────────────────┐
│  1. INPUT IMAGE                                 │
│     ↓                                           │
│  2. Auto-detect display resolution via Sway IPC │
│     (falls back to manual input if no session)  │
│     ↓                                           │
│  3. Resize to display resolution if needed      │
│     • Option A: Crop to fill (preserves ratio)  │
│     • Option B: Stretch to fit                  │
│     ↓                                           │
│  4. Generate edge masks:                        │
│     • Top:    80px solid white + 30px fade       │
│     • Bottom: 30px fade                          │
│     • Left:   30px fade                          │
│     • Right:  30px fade                          │
│     ↓                                           │
│  5. Composite masks via Screen blending          │
│     ↓                                           │
│  6. Apply 25px Gaussian blur to masked regions   │
│     ↓                                           │
│  7. OUTPUT: Desktop wallpaper (native res)       │
│     ↓                                           │
│  8. BONUS: Generate lockscreen variant           │
│     • 40px blur + 60% Tokyo Night tint           │
│     • Same native resolution                     │
└─────────────────────────────────────────────────┘
```

**Output files:**
| File | Resolution | Description |
|------|-----------|-------------|
| `<output>.png` | Auto-detected | Desktop wallpaper with frosted glass edges |
| `<output>_lock.png` | Auto-detected | Lock screen — blurred & tinted Tokyo Night |

> **To use a new wallpaper:** Run this script on any image, then copy the outputs into `wallpapers/` and update the path in `sway/config` line 65.

### Idle Timeouts (`sway/idle.sh`)

| Timeout | Action |
|---------|--------|
| 3 minutes | Dim screen (brightness → 5%) |
| 5 minutes | Lock screen (swaylock) |
| 10 minutes | Turn off display (DPMS) |
| 15 minutes | Suspend to RAM |

> **To change idle timeouts:** Edit the timeout values in `sway/idle.sh`.

### Idle Inhibition

Screen sleep is automatically prevented when:
- Any audio is playing (`sway-audio-idle-inhibit`)
- Any window is fullscreen (YouTube, video players, etc.)

---

## ⌨️ Keybindings

All keybindings use `Super` (Windows key) as the modifier.

### Applications

| Keys | Action |
|------|--------|
| `Super + Return` | Open terminal (Kitty) |
| `Super + D` | App launcher (Rofi) |
| `Super + B` | Open browser (Zen Browser) |
| `Super + E` | File manager (Thunar) |
| `Super + Z` | Open Zed editor |
| `Super + Shift + Z` | Open new Zed window |
| `Super + V` | Clipboard history |
| `Super + .` | Emoji picker |
| `Super + Escape` | System monitor (Btop) |

### Window Management

| Keys | Action |
|------|--------|
| `Super + Q` | Kill focused window |
| `Super + F` | Toggle fullscreen |
| `Super + Shift + Space` | Toggle floating |
| `Super + Space` | Toggle focus (tiling ↔ floating) |
| `Super + H/J/K/L` | Move focus (Vim-style) |
| `Super + Shift + H/J/K/L` | Move window (Vim-style) |
| `Super + Arrow Keys` | Move focus (Arrow keys) |
| `Super + R` | Enter resize mode |
| `Super + S` | Stacking layout |
| `Super + W` | Toggle tabbed/split layout |
| `Super + A` | Focus parent container |

### Workspaces

| Keys | Action |
|------|--------|
| `Super + 1–0` | Switch to workspace 1–10 |
| `Super + Shift + 1–0` | Move window to workspace 1–10 |

### Scratchpad

| Keys | Action |
|------|--------|
| `Super + Shift + -` | Move window to scratchpad |
| `Super + -` | Show/cycle scratchpad |

### Media & Hardware

| Keys | Action |
|------|--------|
| `XF86AudioMute` | Toggle mute |
| `XF86AudioLowerVolume` | Volume -5% |
| `XF86AudioRaiseVolume` | Volume +5% |
| `XF86AudioMicMute` | Toggle mic mute |
| `XF86AudioPlay/Pause` | Play/Pause media |
| `XF86AudioPrev/Next` | Previous/Next track |
| `XF86MonBrightnessDown` | Brightness -5% |
| `XF86MonBrightnessUp` | Brightness +5% |

### Screenshots

| Keys | Action |
|------|--------|
| `Super + Shift + S` | Region select → Swappy editor |
| `Super + Print` | Full screen → clipboard |

### System

| Keys | Action |
|------|--------|
| `Super + N` | Toggle notification panel |
| `Super + Shift + C` | Reload Sway config |
| `Super + Shift + E` | Exit Sway (with confirmation) |

---

## 📁 Directory Structure

```
arch-theme/
├── 🪟 sway/                    # Window manager config
│   ├── config                   #   Main Sway configuration
│   ├── idle.sh                  #   Idle timeout handler
│   ├── rofi-manager.sh          #   Unified Rofi launcher
│   └── hw-notifier.py           #   USB/power notification daemon
│
├── 📊 waybar/                   # Status bar
│   ├── config                   #   Module layout & behavior
│   ├── style.css                #   Visual styling
│   ├── battery.sh               #   Battery + TLP status script
│   ├── pavu_toggle.sh           #   Audio mixer popup script
│   ├── tlp_menu.sh              #   Power profile switcher
│   └── toggle_idle.sh           #   Idle inhibitor toggle
│
├── 🔍 rofi/                     # Application launcher
│   ├── config.rasi              #   Main Rofi theme
│   ├── powermenu.rasi           #   Power menu theme
│   ├── powermenu.sh             #   Power menu script
│   └── rofimoji-theme.rasi      #   Emoji picker theme
│
├── 🐱 kitty/                    # Terminal emulator
│   └── kitty.conf               #   Colors, font, opacity
│
├── 🔔 swaync/                   # Notification daemon
│   ├── config.json              #   Behavior settings
│   └── style.css                #   Visual styling
│
├── 🔒 swaylock/                 # Lock screen
├── 🔑 lemurs/                   # Display manager (login screen)
│   ├── config.toml              #   UI styling & behavior
│   └── pam                      #   PAM authentication stack
│
├── 🚪 wlogout/                  # Logout overlay
│   ├── layout                   #   Button definitions
│   └── style.css                #   Visual styling
│
├── 📈 btop/                     # System monitor
│   ├── btop.conf                #   Settings
│   └── themes/miku-dark.theme   #   Custom Miku color theme
│
├── 🔤 fontconfig/               # System font overrides
│   └── conf.d/
│       ├── 99-user-fonts.conf   #   Font family aliases
│       ├── 75-joypixels.conf    #   Emoji font config
│       ├── 98-remove-mono-emojis.conf
│       └── 99-reject-google-emoji.conf
│
├── 🎨 gtk-3.0/                  # GTK-3 theming
│   ├── settings.ini             #   Theme, font, icons
│   ├── colors.css               #   Color overrides
│   └── gtk.css                  #   CSS overrides
│
├── 🎨 gtk-4.0/                  # GTK-4 theming
│   ├── settings.ini             #   Theme, font, icons
│   ├── colors.css               #   Color overrides
│   └── gtk.css                  #   CSS overrides
│
├── 🧰 environment.d/            # Environment variables
│   └── qt-theming.conf          #   Qt platform theme config
│
├── ⚙️ qt5ct/ & qt6ct/           # Qt theme configurations
├── 🖼️ icons/                    # Custom icon theme (YAMIS-enlarged)
├── 📁 Thunar/                   # Thunar file manager settings (custom actions/shortcuts)
├── 📁 xfce4/                    # Xfce4/Thunar system registry configuration XMLs
├── 🏠 applications/             # Custom .desktop launchers
├── 📜 scripts/                  # Utility scripts
├── 🖥️ systemd/                  # User systemd services
├── 🌌 wallpapers/               # Wallpaper images
├── 🐚 zshrc                     # Zsh shell configuration
├── 🚀 starship.toml             # Shell prompt configuration
├── 📋 mimeapps.list             # Default application associations
├── 👆 fingerprint/              # Fingerprint auth setup
├── ⚡ etc/tlp.conf              # TLP power management
└── 📦 install.sh                # One-shot installer
```

---

## 🎛️ Customization Guide

### I want to change the accent color

The primary accent is **Miku Teal `#39c5bb`**. To change it:

1. Search and replace `#39c5bb` across all files
2. Also replace the hover variant `#33e0e0`
3. Key files to update:
   - `sway/config` (border colors)
   - `waybar/style.css` (active workspace, hover)
   - `waybar/config` (icon span colors)
   - `rofi/config.rasi` (selection highlight)
   - `kitty/kitty.conf` (cursor, selection, color2/10)
   - `swaync/style.css` (notification accent)
   - `lemurs/config.toml` (focused colors)

### I want to change the wallpaper

1. Replace `wallpapers/satisfaction_hires_final.png` with your image
2. Or edit `sway/config` line 65 to point to a different path
3. For the lock screen wallpaper, check `swaylock/config`

### I want to change the font

1. **System UI font:** Change `IBM Plex Sans SemiBold` in:
   - `sway/config` line 10
   - `gtk-3.0/settings.ini` → `gtk-font-name`
   - `gtk-4.0/settings.ini` → `gtk-font-name`
   - `rofi/config.rasi` → `font:`
   - `fontconfig/conf.d/99-user-fonts.conf`
2. **Monospace font:** Change `FiraCode Nerd Font` in:
   - `kitty/kitty.conf` line 6
   - `waybar/style.css` line 4
   - `fontconfig/conf.d/99-user-fonts.conf`
3. Run `fc-cache -fv` after changing fontconfig

### I want to change the terminal transparency

Edit `kitty/kitty.conf` line 20:
```
background_opacity 0.95    # 0.0 = fully transparent, 1.0 = opaque
```

### I want to change idle timeouts

Edit the timeout values in `sway/idle.sh`. The current values are:
- Dim: 180s (3 min)
- Lock: 300s (5 min)
- DPMS off: 600s (10 min)
- Suspend: 900s (15 min)

### I want to add a new Waybar module

1. Add the module name to `modules-left/center/right` in `waybar/config`
2. Add module configuration in the same file
3. Add CSS styling in `waybar/style.css`

### I want to change the display manager theme

Edit `lemurs/config.toml`. The PAM file at `lemurs/pam` controls authentication.

> ⚠️ **Be careful editing PAM files.** A misconfigured PAM stack can lock you out of your system. Always keep a root shell open when testing PAM changes.

---

## 🙏 Credits

- **Color Scheme:** Based on [Tokyo Night](https://github.com/enkia/tokyo-night-vscode-theme) by enkia
- **Icon Theme:** [TokyoNight-SE](https://github.com/ljmill/tokyo-night-icons) (YAMIS enlarged variant)
- **GTK Theme:** [adw-gtk3-dark](https://github.com/lassekongo83/adw-gtk3)
- **Cursor Theme:** [Breeze](https://github.com/KDE/breeze)
- **Wallpaper Art:** Hatsune Miku "Satisfaction" illustration

---

<p align="center">
  <sub>Built with 💙 on Arch Linux · Maintained by <a href="https://github.com/sea-deep">@sea-deep</a></sub>
</p>
