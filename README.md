<h1 align="center">
  <br>
  🌊 sea-deep — Arch Linux Hyprland & Quickshell Desktop Environment
  <br>
</h1>

<p align="center">
  <b>A meticulously crafted, monolithic Wayland desktop environment built on Hyprland, Quickshell, and the sea-deep theme (Tokyo Night palette accented with vivid teal).</b>
</p>

<p align="center">
  <a href="#-quick-start"><img src="https://img.shields.io/badge/Arch-Linux-1793d1?style=for-the-badge&logo=archlinux&logoColor=white" alt="Arch Linux"></a>
  <a href="#-components"><img src="https://img.shields.io/badge/WM-Hyprland-39c5bb?style=for-the-badge" alt="Hyprland"></a>
  <a href="#-components"><img src="https://img.shields.io/badge/Shell-Quickshell-7aa2f7?style=for-the-badge" alt="Quickshell"></a>
  <a href="#-color-palette"><img src="https://img.shields.io/badge/Theme-sea--deep-39c5bb?style=for-the-badge" alt="sea-deep"></a>
</p>

---

## 🖼️ Wallpaper

![Wallpaper](wallpapers/satisfaction_hires.png)

The canonical wallpaper (`wallpapers/satisfaction_hires.png`) is powered natively by the `awww-daemon` Wayland user service, featuring smooth animated transitions and direct integration with Hyprland and Thunar file manager context actions. Zero legacy Sway or X11 dependencies.

---

## 📑 Table of Contents

- [Quick Start](#-quick-start)
- [Single Source of Truth & Theme Tokens](#-single-source-of-truth--theme-tokens)
- [Color Palette](#-color-palette)
- [Typography](#-typography)
- [Icon Hierarchy](#-icon-hierarchy)
- [Components](#-components)
  - [Hyprland (Compositor)](#hyprland-compositor)
  - [Quickshell (Status Bar, Launcher, Overlays)](#quickshell-status-bar-launcher-overlays)
  - [Native Custom Session Menu](#native-custom-session-menu)
  - [On-Screen Virtual Keyboard](#on-screen-virtual-keyboard)
  - [Hyprlock & Hypridle (Lock & Power Management)](#hyprlock--hypridle)
  - [Kitty (Terminal)](#kitty-terminal)
  - [Ly (Login Screen)](#ly-login-screen)
  - [Btop (System Monitor)](#btop-system-monitor)
  - [Starship (Shell Prompt)](#starship-shell-prompt)
  - [GTK 3 & GTK 4 Theming](#gtk-theming)
  - [Qt 5 & Qt 6 Theming](#qt-theming)
  - [Thunar File Manager & Custom Actions](#thunar-custom-actions)
- [Keybindings](#-keybindings)
- [Directory Structure](#-directory-structure)
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
1. Configure Pacman parallel downloads, enable the `multilib` repository, and set up `chaotic-aur`.
2. Install `yay` (AUR helper) if missing.
3. Install all required packages via `yay` (Hyprland, Quickshell, Ly, Kitty, Thunar, Qt/GTK engines).
4. Back up any existing configs to `*.bak`.
5. Symlink configurations from this repo into `~/.config/` and `~/.local/share/`.
6. Run `scripts/sync-theme.sh` to compile all Qt, GTK, and KDE palettes from `theme/tokens.json`.
7. Configure Ly display manager and TTY color service.
8. Enable native systemd user services (`awww-daemon.service`, `plasma-polkit-agent.service`).

---

## 💎 Single Source of Truth & Theme Tokens

All design tokens across colors, typography, geometry metrics, on-screen keyboard styling, icon inheritance, wallpaper, and platform environment defaults are centrally defined in:

- **Tokens Definition:** [`theme/tokens.json`](theme/tokens.json)
- **Synchronizer Script:** [`scripts/sync-theme.sh`](scripts/sync-theme.sh)

Whenever you adjust a color, font, or metric in `theme/tokens.json`, run:

```bash
./scripts/sync-theme.sh
```

This single command automatically regenerates and updates:
- **Qt5 & Qt6:** 21-role `TokyoNight.conf` color schemes in `qt5ct/colors/` and `qt6ct/colors/`.
- **GTK3 & GTK4:** `colors.css` and `settings.ini` variables.
- **KDE / Polkit:** Tokyo Night RGB definitions in `kdeglobals`.
- **Kvantum:** `Kvantum-Tokyo-Night.kvconfig` general colors.
- **XSettings:** `xsettingsd/xsettingsd.conf`.
- **User Symlinks & Caches:** Re-links palettes and updates icon caches for `sea-deep`.

---

## 🎨 Color Palette

The desktop color scheme is derived from **Tokyo Night** with **Teal (`#39c5bb`)** accents:

| Role | Hex | RGB | Purpose |
|------|-----|-----|---------|
| **Base Background (`bg`)** | `#1a1b26` | `26, 27, 38` | Main window, panel backgrounds, terminal bg |
| **Deep Background (`bgDark`)** | `#16161e` | `22, 22, 30` | Base text inputs, inactive surfaces, borders |
| **Light Surface (`bgLight`)** | `#24283b` | `36, 40, 59` | Buttons, cards, popover surfaces |
| **Muted Surface (`surface`)** | `#2f3549` | `47, 53, 73` | Dividers, mid-level surface containers |
| **Surface Variant (`surfaceVariant`)** | `#3b4261` | `59, 66, 97` | Subtle borders, elevated card highlights |
| **Foreground (`fg`)** | `#c0caf5` | `192, 202, 245` | Primary text and sharp iconography |
| **Dim Foreground (`fgDim`)** | `#9aa5ce` | `154, 165, 206` | Secondary labels and inactive text |
| **Muted Foreground (`fgMuted`)** | `#565f89` | `86, 95, 137` | Placeholders, disabled states, comments |
| **Accent Teal (`accent`)** | `#39c5bb` | `57, 197, 187` | Focused borders, active pills, primary accents |
| **Teal Glow (`accentGlow`)** | `#33e0e0` | `51, 224, 224` | Hover states, glowing boundary effects |
| **Pink (`mikuPink`)** | `#e35885` | `227, 88, 133` | Special badges, media playback accents |
| **Dark Teal (`mikuDark`)** | `#134c48` | `19, 76, 72` | Subtle inactive teal fills |
| **Blue (`blue`)** | `#7aa2f7` | `122, 162, 247` | Hyperlinks and informational widgets |
| **Purple (`purple`)** | `#bb9af7` | `187, 154, 247` | Media progress, secondary highlight |
| **Red (`red`)** | `#f7768e` | `247, 118, 142` | Errors, close buttons, battery critical |
| **Yellow (`yellow`)** | `#e0af68` | `224, 175, 104` | Warnings, notifications |
| **Green (`green`)** | `#73daca` | `115, 218, 202` | Success indicators, battery full |

---

## ✏️ Typography

The desktop standardizes strictly on two typefaces:

| Context | Font | Weight | Weight Token | Where Applied |
|---------|------|--------|--------------|---------------|
| **System UI & Documents** | IBM Plex Sans | SemiBold (600) | `63` | Hyprland, Quickshell, GTK 3/4, Qt 5/6, KDE |
| **Monospace & Code** | FiraCode Nerd Font | SemiBold (600) | `63` | Kitty, Starship, Quickshell status clock |

---

## 🎭 Icon Hierarchy

A unified master theme **`sea-deep`** (`icons/sea-deep/index.theme`) provides a 3-layer inheritance architecture ensuring complete coverage across all desktop software:

```ini
[Icon Theme]
Name=sea-deep
Comment=sea-deep unified icon theme
Inherits=YAMIS-enlarged,TokyoNight-Files,Adwaita,breeze-dark,hicolor
```

1. **Layer 1: Applications & App MIME Types (`YAMIS-enlarged`):**
   - Pure flat monochromatic SVG icons for desktop applications (`icons/YAMIS-enlarged/apps/`).
   - Monochromatic app and executable MIME types (`application-x-executable`, `application-x-desktop`, `apk`, `deb`, `rpm`, `shellscript`).
   - Custom additions for apps lacking standard vendor icons (`antigravity-ide`, `co.anysphere.cursor`, `org.vinegarhq.Sober`).
2. **Layer 2: Files, Folders & Storage Devices in Thunar (`TokyoNight-Files`):**
   - Rich Tokyo Night blue folders and user directories (`places/`).
   - Distinct file type icons for documents, media, archives, and code (`mimetypes/`).
   - Hardware storage, disks, and partitions (`devices/`).
3. **Layer 3: System-Wide UI Controls, Toolbar Actions & Window Buttons (`Adwaita`):**
   - Standard modern GNOME vector symbolic SVGs (`document-save-symbolic`, `edit-copy-symbolic`, `pan-down-symbolic`, window controls).

---

## 🧩 Components

### Hyprland (Compositor)

**Config:** [`hypr/hyprland.lua`](hypr/hyprland.lua)

- Native Lua-based configuration (`hyprland.lua`).
- Dynamic 1080p fractional scale cycling bound to <kbd>Super + =</kbd> (1.0 → 1.2 → 1.25 → 1.5).
- Hardware screen shaders with alternating cache fix (`comfort`, `grayscale`, `vivid`).
- Enforced `:close` window decoration button layout preventing Electron/Chromium minimization suspension bugs.
- Global IPC shortcuts for Quickshell overlays and app launchers.

---

### Quickshell (Status Bar, Launcher, Overlays)

**Root:** [`quickshell/shell.qml`](quickshell/shell.qml) · **Bar:** [`quickshell/Bar.qml`](quickshell/Bar.qml)

Quickshell implements the entire interactive shell:
- **Full-Width Fluid Bar:** Zero-gap edge-to-edge status bar with concave corner fillets.
- **Native App Launcher (`Launcher.qml`):** Instant search, pinned apps, recently opened tracking, smooth gliding unroll, and virtualized list item reuse (`reuseItems: true`).
- **Clipboard Manager (`ClipboardPicker.qml`):** Standalone cursor-following popup with Wayland Drag-and-Drop support, auto-paste simulation, and virtualized list item reuse.
- **Emoji Picker (`EmojiPicker.qml`):** Native categorised picker with search, category jump bar, and virtualized list item reuse.
- **Quick Controls (`QuickControls.qml`):** Master audio, application streams, brightness, and screen shaders with hover-wheel volume and slider controls.
- **System Tray (`TrayExpander.qml`):** StatusNotifier DBus tray with reactive hot-reload synchronization and grace timers.
- **Screenshot Menu (`ScreenshotMenu.qml`):** Region, window, and monitor capture overlay.
- **Recorder Menu (`RecorderMenu.qml`):** Screen and audio recording overlay with live recording indicators in the status bar.

---

### Native Custom Session Menu

**Component:** [`quickshell/controls/PowerExpander.qml`](quickshell/controls/PowerExpander.qml)

Triggered instantly via <kbd>Super + Shift + E</kbd> or the status bar power icon. Features zero-lag keyboard navigation:

- <kbd>L</kbd> — Lock session (`loginctl lock-session` via Hyprlock)
- <kbd>U</kbd> — Suspend system (`systemctl suspend`)
- <kbd>E</kbd> — Log out (`loginctl terminate-user $USER`)
- <kbd>R</kbd> — Reboot system (`systemctl reboot`)
- <kbd>S</kbd> — Shut down (`systemctl poweroff`)
- <kbd>H</kbd> — Hibernate system (`systemctl hibernate`)
- <kbd>Esc</kbd> — Dismiss menu

---

### On-Screen Virtual Keyboard

**Script:** [`hypr/scripts/toggle_osk.sh`](hypr/scripts/toggle_osk.sh)

Toggled via <kbd>Super + ,</kbd> (comma). Runs `wvkbd` with fully tokenized styling extracted dynamically from [`theme/tokens.json`](theme/tokens.json):
- Matches `sea-deep` background, key surface, pressed highlight, font family, and rounding metrics.
- Sub-3ms launch time with graceful fallback tokens and zero-latency instant `pkill` toggle-off.

---

### Hyprlock & Hypridle

**Lockscreen:** [`hypr/hyprlock.conf`](hypr/hyprlock.conf) · **Idle:** [`hypr/hypridle.conf`](hypr/hypridle.conf)

- Uses canonical 4K wallpaper (`satisfaction_hires.png`).
- Seamless fingerprint and password unlock via PAM.
- Non-poisoning brightness persistence: restores hardware backlight upon resume without retaining idle dimming.

---

### Kitty (Terminal)

**Config:** [`kitty/kitty.conf`](kitty/kitty.conf)

- Tokyo Night colors with vivid teal cursor.
- 95% opacity with crisp text rendering.
- `FiraCode Nerd Font` 13pt SemiBold.

---

### Ly (Login Screen)

**Config:** [`ly/config.ini`](ly/config.ini) · **TTY Theme:** [`ly/set-tty-theme.sh`](ly/set-tty-theme.sh)

- Lightweight TUI display manager.
- Automated systemd service sets the 16-color Linux VT console palette to Tokyo Night before login.

---

### Btop (System Monitor)

**Config:** [`btop/btop.conf`](btop/btop.conf) · **Theme:** [`btop/themes/miku-dark.theme`](btop/themes/miku-dark.theme)

- Launched in a dedicated terminal window via <kbd>Super + Escape</kbd>.

---

### Starship (Shell Prompt)

**Config:** [`starship.toml`](starship.toml)

- Powerline pill prompt in Zsh showing user, directory, git branch, and execution status.

---

### GTK Theming

**Config:** [`gtk-3.0/`](gtk-3.0/) · [`gtk-4.0/`](gtk-4.0/)

- Base theme: `adw-gtk3-dark`.
- Dynamic color variables generated from `theme/tokens.json`.
- Icon theme: `sea-deep`.
- Standardized hover and active button styling (`#39c5bb` background highlight with `#16161e` text/icon inversion).
- `GTK_USE_PORTAL=1` enforced to unify file chooser dialogs across all applications.

---

### Qt Theming

**Config:** [`qt5ct/`](qt5ct/) · [`qt6ct/`](qt6ct/) · [`Kvantum/`](Kvantum/) · [`kdeglobals`](kdeglobals)

- Complete 21-role Tokyo Night palette for Qt 5 and Qt 6.
- `Kvantum-Tokyo-Night` SVG widget theme with teal accents.
- `QT_WAYLAND_DISABLE_WINDOWDECORATION="1"` disables conflicting client-side borders.
- Unified `QT_QPA_PLATFORMTHEME="qt5ct"` seamlessly loads `libqt5ct.so` for Qt5 and `libqt6ct.so` for Qt6.
- `standard_dialogs=xdgdesktopportal` routes Qt file pickers to XDG Desktop Portal.

---

### Thunar File Manager & Custom Actions

**Config:** [`Thunar/uca.xml`](Thunar/uca.xml) · **MIME Defaults:** [`mimeapps.list`](mimeapps.list)

Thunar is configured as the canonical system file opener (`inode/directory` and `x-scheme-handler/file`), featuring custom context actions:
1. **Copy Path:** Copies exact file or folder path to Wayland clipboard (`wl-copy -n "%f"`).
2. **Set as Wallpaper:** Instantly applies image as wallpaper with animated transition via `hypr/scripts/set_wallpaper.sh`.
3. **Open Terminal Here:** Opens Kitty at current directory.
4. **Open as Root:** Opens elevated Thunar window with pkexec.
5. **Open with VSCode:** Opens selected file or folder in VS Code.

---

## ⌨️ Keybindings

All keybindings use `Super` (Windows key) as the main modifier:

### Applications & Overlays
| Keys | Action |
|------|--------|
| `Super + Return` | Terminal (Kitty) |
| `Super + D` | Native App Launcher (Quickshell) |
| `Super + V` | Native Clipboard Manager (Quickshell) |
| `Super + .` | Native Emoji Picker (Quickshell) |
| `Super + ,` | On-Screen Virtual Keyboard (`toggle_osk.sh`) |
| `Super + B` | Web Browser (Zen Browser) |
| `Super + E` | File Manager (Thunar) |
| `Super + Z` | Code Editor (Zed) |
| `Super + Shift + Z` | Code Editor New Window (Zed) |
| `Super + Escape` | System Monitor (Btop) |
| `Super + N` | Notification Center (Quickshell) |
| `Super + Shift + N` / `Super + BackSpace` | Dismiss All Notifications |
| `Super + Shift + P` | Cycle Power Profile (performance / balanced / power-saver) |

### Window Management & Workspaces
| Keys | Action |
|------|--------|
| `Super + Q` | Close window |
| `Super + F` | Toggle fullscreen |
| `Super + Shift + Space` | Toggle floating mode for active window |
| `Super + Space` | Cycle focus between tiled and floating window layers |
| `Super + A` | Cycle focus across tiled windows |
| `Super + S` | Toggle window grouping (tabbed windows) |
| `Super + Tab` / `Super + Shift + Tab` | Cycle active window in current group |
| `Super + W` | Toggle layout split direction |
| `Super + P` | Pseudo-tile active window |
| `Super + H/J/K/L` (or Arrows) | Move focus (Vim direction keys) |
| `Super + Shift + H/J/K/L` (or Arrows) | Move active window |
| `Super + 1–0` | Switch to workspace 1–10 |
| `Super + Shift + 1–0` | Move window to workspace 1–10 |
| `Super + minus` | Toggle special workspace (scratchpad) |
| `Super + Shift + minus` | Move window to scratchpad |
| `Super + =` | Cycle display fractional scale (1.0 → 1.2 → 1.25 → 1.5) |
| `Super + R` | Enter interactive window resize submap (<kbd>H/J/K/L</kbd> to resize, <kbd>Enter</kbd>/<kbd>Esc</kbd> to exit) |

### Media, Screenshot & Recording
| Keys | Action |
|------|--------|
| `XF86AudioMute` | Toggle speaker mute |
| `XF86AudioLowerVolume` / `RaiseVolume` | Volume ±5% |
| `XF86AudioMicMute` | Toggle microphone mute |
| `XF86AudioPlay` / `Pause` / `Stop` | Media playback toggle |
| `XF86AudioNext` / `Prev` | Next / previous media track |
| `XF86MonBrightnessDown` / `Up` | Screen backlight ±5% |
| `Super + Shift + S` / `Print` | Native Screenshot Menu (Quickshell) |
| `Super + Print` | Fullscreen screenshot copied directly to clipboard |
| `Super + Shift + R` | Screen Recorder Menu / toggle recording (Quickshell / wf-recorder) |

### System & Compositor
| Keys | Action |
|------|--------|
| `Super + Shift + C` | Hot reload desktop (Hyprland, Quickshell & screen shaders) |
| `Super + Shift + E` | Native Custom Session Menu (Lock, Suspend, Logout, Reboot, Shutdown, Hibernate) |

---

## 📁 Directory Structure

```
arch-theme/
├── ⚙️ theme/                     # Single source of truth
│   └── tokens.json              #   Unified design tokens (colors, typography, geometry, OSK)
│
├── 🪟 hypr/                      # Hyprland compositor configuration
│   ├── hyprland.lua             #   Main Hyprland Lua config
│   ├── hypridle.conf            #   Idle inhibitor & sleep daemon
│   ├── hyprlock.conf            #   Lockscreen configuration
│   ├── screenshot.sh            #   Quickshell IPC screenshot helper
│   └── scripts/                 #   Compositor helper utilities (wallpaper, OSK, hot-reload)
│
├── 🐚 quickshell/                # Quickshell desktop shell
│   ├── shell.qml                #   ShellRoot & IPC dispatcher
│   ├── Bar.qml                  #   Fluid top status bar
│   ├── launcher/                #   Native app launcher with virtualized list reuse
│   ├── clipboard/               #   Cursor-following clipboard overlay with Wayland DnD
│   ├── emoji/                   #   Native emoji picker with virtualized list reuse
│   ├── controls/                #   Drop-down expanders (PowerExpander, QuickControls, Tray, etc.)
│   ├── bar/                     #   Bar modules (Clock, Audio, Battery, Workspaces)
│   ├── theme/                   #   Theme.qml & UiState.qml
│   └── scripts/                 #   Brightness, power profile, shader scripts
│
├── 🐱 kitty/                     # Terminal emulator
│   └── kitty.conf               #   Colors, font, opacity
│
├── 🎨 gtk-3.0/ & gtk-4.0/        # GTK theming
│   ├── colors.css               #   Compiled Tokyo Night color variables
│   ├── gtk.css                  #   Custom widget styles & standardized button highlights
│   └── settings.ini             #   Theme, icon, font configuration
│
├── ⚙️ qt5ct/ & qt6ct/            # Qt 5 and Qt 6 configuration
│   ├── qt5ct.conf / qt6ct.conf  #   Active palette and proxy settings
│   └── colors/TokyoNight.conf   #   21-role Tokyo Night color scheme
│
├── 🎨 Kvantum/                   # Kvantum SVG widget themes
│   ├── kvantum.kvconfig         #   Theme selection
│   └── Kvantum-Tokyo-Night/     #   Tokyo Night Kvantum theme
│
├── 📁 Thunar/                    # File manager custom actions
│   └── uca.xml                  #   Copy Path, Set as Wallpaper, etc.
│
├── 🖼️ icons/                     # Icon themes
│   ├── sea-deep/                #   Master icon theme with layered inheritance
│   ├── TokyoNight-Files/        #   Places, mimetypes, and devices for Thunar
│   └── YAMIS-enlarged/          #   Flat monochrome app and executable MIME icons
│
├── 🔑 ly/                        # Display manager
│   ├── config.ini               #   Ly TUI theme configuration
│   └── set-tty-theme.sh         #   16-color TTY scheme injector
│
├── 📈 btop/                      # System monitor configuration
├── 🔤 fontconfig/                # Font fallback configuration
├── 🧰 environment.d/             # Wayland & Qt session environment variables
├── 📜 scripts/                   # Theme sync & system hooks
│   └── sync-theme.sh            #   Compiles all configs from tokens.json
├── 🌌 wallpapers/                # Canonical high-resolution wallpaper (satisfaction_hires.png)
└── 📦 install.sh                 # Unified installation & setup script
```

---

## 🙏 Credits

- **Design System:** [Tokyo Night](https://github.com/enkia/tokyo-night-vscode-theme) by enkia, accented with Hatsune Miku Teal (`#39c5bb`).
- **Icons:** [YAMIS](https://github.com/dirn/yamis) by dirn, [TokyoNight-SE](https://github.com/ljmill/tokyo-night-icons), and [Adwaita](https://gitlab.gnome.org/GNOME/adwaita-icon-theme).
- **GTK Theme:** [adw-gtk3](https://github.com/lassekongo83/adw-gtk3).
- **Cursor Theme:** [Breeze](https://github.com/KDE/breeze).
- **Wallpaper Art:** Hatsune Miku "Satisfaction" illustration.

---

<p align="center">
  <sub>Maintained with 💙 by <a href="https://github.com/sea-deep">@sea-deep</a></sub>
</p>
