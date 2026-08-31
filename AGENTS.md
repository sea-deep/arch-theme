# AGENTS.md — Quickshell & Arch Theme Architecture & Guide

> **CRITICAL OPERATIONAL RULES FOR ALL AGENTS:**
> 1. **DO NOT HOT-RELOAD OR KILL QUICKSHELL (`killall qs`, `hot_reload.sh`, `systemctl restart quickshell`, etc.)**
>    The user will **ALWAYS** manually reload Quickshell themselves. Any unauthorized restarts disrupt their active desktop environment.
> 2. **DO NOT DISMISS USER NOTIFICATIONS (`hyprctl dismissnotify`, `swaync-client -C`, etc.)**
>    All notifications and toasts belong strictly to the user. Never clear or dismiss notifications automatically.
> 3. **DO NOT SWITCH BRANCHES LOCALLY ON THE LIVE WORKING TREE (`git checkout main`, etc.)**
>    Live file watchers in Hyprland detect split-second unlinking during local branch switching and latch error banners. Push directly to remote branches (`git push origin HEAD:main`).

---

## 1. System Architecture Overview

This repository provides an integrated desktop shell configuration for **Hyprland** (Wayland) built on **Quickshell (Qt 6 / QML)**, with companion services for audio, power (TLP), clipboard (`clipse`), notifications, polkit authentication, and shader controls.

```
arch-theme/
├── quickshell/
│   ├── shell.qml              # Root ShellRoot and IPC handlers
│   ├── Bar.qml                # Top LayerShell status bar with native dropdowns
│   ├── bar/                   # Bar modules (Audio, Battery, Workspaces, Clock, etc.)
│   ├── controls/              # Native dropdown expanders (QuickControls, Clipboard, etc.)
│   ├── emoji/                 # Native emoji picker (EmojiPicker.qml)
│   ├── launcher/              # Native application launcher (Launcher.qml)
│   ├── theme/                 # Theme tokens (Theme.qml) & state singleton (UiState.qml)
│   └── scripts/               # Helper utilities (update_shader.sh, battery.sh, etc.)
├── hypr/                      # Hyprland configuration (hyprland.lua)
├── kdeglobals                 # Unified KDE/Qt6 color palette
├── qt5ct/ & qt6ct/            # Qt 5 and Qt 6 configuration files
├── Kvantum/                   # Kvantum SVG widget themes (Kvantum-Tokyo-Night)
└── environment.d/             # Session environment definitions
```

---

## 2. Proven Core Subsystems & Rules

### A. Drag-and-Drop (DND) across Wayland Windows

1. **Standalone Cursor Popups (`ClipboardPicker.qml`):**
   - Clipboard is an independent cursor-following overlay window (`quickshell/clipboard/ClipboardPicker.qml`).
   - When NOT dragging, `ClipboardPicker.qml` expands its `mask` to `root.height` with a backdrop `MouseArea` to dismiss upon clicking outside.
   - When dragging (`root.isDragging == true`), `ClipboardPicker.qml` dynamically shrinks the mask to `Region { item: popup }` so Hyprland routes drop events directly into client windows (Kitty, VSCode, Chrome, Discord).
   - **Correct Pattern:**
     ```qml
     mask: Region {
         Region {
             x: 0; y: 0; width: root.width
             height: root.isDragging ? 0 : root.height
         }
         Region { item: popup }
     }
     ```
2. **Layer Level (`WlrLayershell.layer`):**
   - Use `WlrLayer.Top` for `Bar.qml` and `ClipboardPicker.qml` to allow Wayland DnD drops onto client windows.
3. **QtQuick Wayland Drag Mechanics (`ClipboardPicker.qml`):**
   - `DragHandler` does not initiate `wl_data_device.start_drag` in Qt 6 Wayland QPA.
   - Use `MouseArea` with `drag.target` set to a proxy `Item` (`expDragProxy`).
   - Provide `Drag.dragType: Drag.Automatic` and `Drag.supportedActions: Qt.CopyAction | Qt.MoveAction | Qt.LinkAction`.
   - **MIME Payload format:**
     - Text: `text/plain`, `text/plain;charset=utf-8`, `UTF8_STRING`, `STRING`, and `TEXT`.
     - Files / Images: RFC-2483 CRLF-delimited `text/uri-list` (`file:///path\r\n`) and `x-special/gnome-copied-files` (`copy\nfile:///path\r\n`).
4. **Delegate Drag State & Lifecycle Isolation:**
   - Never use global `Binding { target: UiState; property: "isDragging"; value: itemMouse.drag.active }` inside list delegates (competing rows will continuously overwrite it with `false`).
   - Use explicit `onPressed`, `onReleased`, `onCanceled`, `Drag.onDragStarted`, and `Drag.onDragFinished` handlers on the delegate's `MouseArea` and `expDragProxy`.
5. **Copy + Auto-Paste Execution:**
   - Activating an entry executes `scripts/paste-clipboard.sh` which sets the Wayland clipboard via `wl-copy` and sends a simulated <kbd>Ctrl+V</kbd> keypress via `wtype` after a 120ms window focus delay.

---

### B. Outer Click Dismissal & Escape Handling

1. **Bar Dropdowns:**
   - `Connections` targeting `Hyprland`:
     ```qml
     Connections {
         target: Hyprland
         function onActiveToplevelChanged() {
             if (root.overlayExpanded && !clipboardExpander.isDragging) {
                 UiState.closeOverlays()
             }
         }
         function onFocusedWorkspaceChanged() {
             if (root.overlayExpanded && !clipboardExpander.isDragging) {
                 UiState.closeOverlays()
             }
         }
     }
     ```
2. **Window-Wide `<Esc>` Shortcuts:**
   - Always include Qt Quick `Shortcut { sequence: "Escape"; enabled: ...; onActivated: ... }` on overlay windows so <kbd>Esc</kbd> works regardless of which inner child widget has active keyboard focus.
3. **Dynamic Keyboard Focus:**
   - In `Bar.qml`: `WlrLayershell.keyboardFocus: root.overlayExpanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None` routes keyboard input when open and yields focus immediately when closed.

---

### C. QuickControls Sliders & Mouse Wheel Interaction

1. **WheelHandler Integration:**
   - All sliders in `QuickControls.qml` derive from `CleanSlider: QQC2.Slider`.
   - `WheelHandler` is integrated into `CleanSlider` with `orientation: Qt.Vertical` to allow effortless hover-scrolling with mouse wheel or touchpad in ±5% increments:
     - Output / Master Audio & Application streams
     - Brightness backlight
     - Screen Shaders: Comfort (Night light), Grayscale, and Vivid

---

### D. Hyprland Screen Shaders & State Persistence

1. **Path Alternation Caching Fix (`update_shader.sh`):**
   - Hyprland caches shader paths. Writing to the same filename does not recompile the shader.
   - `update_shader.sh` alternates between `~/.config/quickshell/state/shader_a.frag` and `~/.config/quickshell/state/shader_b.frag`.
2. **Hyprland Config Syntax:**
   - `hyprctl eval "hl.config({ decoration = { screen_shader = '...' } })"` for Hyprland Lua configs.
3. **Dual Persistence (`UiState.qml`):**
   - State is held in `PersistentProperties` (`reloadableId: "ui-state"`) with aliased properties (`property alias comfortValue: persisted.comfortValue`).
   - `FileView` watches `~/.config/quickshell/state/shaders.json` with `onTextChanged` to ensure initial values load even with asynchronous disk reads.
   - Values `0..100` are sent to `update_shader.sh set_all <comfort> <grayscale> <vivid>`.

---

### E. Unified Typography & Theming Architecture

1. **Semibold (DemiBold) Standard:**
   - **Quickshell (`Theme.qml`):** `fontWeight: Font.DemiBold` (600) used across all bar modules, buttons, and popups.
   - **Qt5 & Qt6 (`qt5ct.conf` / `qt6ct.conf`):** Weight `63` (SemiBold) for `IBM Plex Sans` and `FiraCode Nerd Font`.
   - **KDE / Polkit (`kdeglobals`):** Weight `63` (SemiBold) across all font roles.
   - **GTK & Hyprland (`hyprland.lua` / `gsettings`):** `IBM Plex Sans SmBld 10` for interface/document, and `FiraCode Nerd Font SemBd 10` for monospace.
   - **Hyprlock (`hyprlock.conf`):** `IBM Plex Sans SmBld`.
2. **The `QT_STYLE_OVERRIDE` Trap:**
   - **NEVER** export `QT_STYLE_OVERRIDE=kvantum` globally.
   - Kvantum is a QWidget style only and lacks a Qt Quick Controls 2 QML module. Setting it causes Qt Quick QML apps (e.g. `polkit-kde-authentication-agent-1` / `QuickAuthDialog.qml`) to crash with `module "kvantum" is not installed` (`SEGV`).
3. **Unified Theming Stack:**
   - **Kvantum Config:** `Kvantum/kvantum.kvconfig` -> `theme=Kvantum-Tokyo-Night`.
   - **KDE / Polkit Config:** `~/.config/kdeglobals` -> Tokyo Night palette (`#1a1b26` bg, `#24283b` surface, `#39c5bb` accent).
   - **Polkit Agent Unit:** `plasma-polkit-agent.service` with drop-in override unsetting `QT_STYLE_OVERRIDE`.

---

### F. Full-Width Fluid Bar & Module Hover Architecture

1. **Edge-to-Edge Fluid Surface:**
   - `Bar.qml` uses `margins.top: 0`, `margins.left: 0`, `margins.right: 0` and `Theme.outerGap: 0` to eliminate corner gaps and prevent wallpaper bleed.
   - An underlying full-width `Rectangle` (`color: Theme.bg`) spans the status bar height with a crisp 1px `Theme.bgDark` bottom boundary.
2. **Pill Elevation & Hover Feedback:**
   - All modules deriving from `Components.Pill` render idle backgrounds as `Theme.bgDark`, transitioning to `Theme.bgLight` / `Theme.surface` and `Theme.accentGlow` borders on hover with `ColorAnimation { duration: 120 }`.
3. **Unified Clock Hit-Testing:**
   - `ClockExpander.qml` contains a root header `MouseArea` covering the entire time, date, and middle spacer region so clicking anywhere on the clock pill reliably toggles the menu or switches tabs.

---

### G. Window Headerbar Controls & Tiling Freezing Invariant

1. **The Minimization Suspension Bug:**
   - Tiling compositors like Hyprland do not maintain a traditional dock minimization queue.
   - When Electron, Chromium, or GTK windows receive `xdg_toplevel.set_minimized`, their rendering pipelines pause `BeginFrame` and freeze the entire window.
2. **Enforced `:close` Decoration Standard:**
   - **GSettings & Hyprland:** `gsettings set org.gnome.desktop.wm.preferences button-layout ':close'` in `hyprland.lua`.
   - **GTK Configs:** `gtk-decoration-layout=:close` in `gtk-3.0/settings.ini` and `gtk-4.0/settings.ini`.
   - **XSettings Daemon:** `Gtk/DecorationLayout ":close"` in `xsettingsd.conf`.
   - **Electron / VS Code:** `"window.customTitleBarVisibility": "never"` and `"window.titleBarStyle": "custom"` in `settings.json`.

---

### H. Display Fractional Scaling & 1080p Divisor Constraints

1. **DRM Fractional Divisors on 1080p:**
   - Scales like `1.10` or `1.15` produce non-integer pixel framebuffers on 1920x1080, triggering Hyprland `Invalid scale passed to monitor` warnings and blurry subpixel tearing.
   - Valid integer-divisible scale steps:
     `1.00` -> `1.20` (Recommended) -> `1.25` -> `1.50`
2. **Dynamic Scale Cycling:**
   - Bound exclusively to <kbd>Super + =</kbd> in `hyprland.lua` using `hl.monitor` and `hl.notification.create`.

---

### I. Pure Bash Scripting & Brightness Persistence Architecture

1. **100% Pure Bash Standard:**
   - All shell scripts in `quickshell/scripts/` and `hypr/scripts/` must be written in pure POSIX/Bash with zero Python runtime dependencies for sub-millisecond invocation.
2. **Non-Poisoning Brightness Persistence:**
   - User brightness is persisted to `~/.config/quickshell/state/brightness.txt` via `quickshell/scripts/brightness.sh`.
   - `hypridle.conf` (`after_sleep_cmd` and `on-resume`) calls `brightness.sh restore` to prevent temporary 10% idle dims from poisoning the persistent brightness state on resume or reboot.

---

### J. Smooth Gliding Reveal Unroll Animation Standard

1. **The Gliding Unroll Invariant for All Custom Popups & Modals:**
   - **NEVER** use scale pop-ins or simple opacity-only fades for standalone desktop popups (`ClipboardPicker.qml`, `EmojiPicker.qml`, `RecorderMenu.qml`, `Launcher.qml`).
   - Use the **solid fluid clipping reveal unroll** architecture:
     - Outer container: `height: fullHeight * root.reveal`, `clip: true`, and `visible: height > 0`.
     - Inner content container: `Item` frozen in absolute coordinate space with static `height: popup.fullHeight` anchored to `top: parent.top` (or `bottom: parent.bottom` for drawer).
     - Standardized reveal transition:
       ```qml
       Behavior on reveal {
           NumberAnimation {
               duration: Theme.durationMedium  // 160ms
               easing.type: Theme.easingDecelerate  // Easing.OutCubic
           }
       }
       ```
   - This prevents layout recalculation jitter, guarantees sub-pixel sharpness without scale distortion, and provides the signature Tokyo Night fluid gliding motion.

2. **Rounded Border Containment & Zero Pixel Overflow Guarantee:**
   - In QtQuick, `clip: true` on `Rectangle` only clips to the rectangular bounding box, NOT the curved corner radii.
   - To prevent square child pixels from bleeding through outer rounded borders when the container height is small during unroll:
     - Wrap inner content in an `Item` with `anchors.fill: parent`, `anchors.margins: Theme.borderWidth`, `clip: true`, and an opacity gate:
       ```qml
       opacity: Math.min(1.0, Math.max(0.0, (root.reveal - 0.08) / 0.92))
       ```
     - This guarantees child elements are 100% invisible during the initial corner unroll ($0 \rightarrow 8\%$) and transition smoothly with zero border overflow or visual artifacting.

3. **Synchronous In-Memory Reactivity & Recently Opened Invariants:**
   - **Zero-Latency In-Memory State:** All interactive toggles (such as pinning/unpinning apps in the launcher or setting quick controls) must update local reactive properties (`root.activePinnedAppNames = pinned; filterApps()`) **synchronously** before invoking asynchronous disk persistence scripts, ensuring 0ms perceptible delay.
   - **Recently Opened Real-Time Tracking:**
     - Must normalize and clean strings with `name.toLowerCase().trim()` for case-insensitive matching.
     - Must re-sync on `onShowingChanged` via `syncPinnedFromDisk()` and `syncRecentsFromDisk()`.
     - Every application execution path (direct click, Enter key, right-click context menu "Launch" / "Launch with GPU") must route through `launch(item)` and invoke `recordRecentApp(name)`.

---

## 3. Verification & Testing Checklist for Agents

Before concluding any change:
- [ ] Run `git diff` to verify syntax and ensure no stray brackets or duplicate property declarations exist.
- [ ] Ensure `Bar.qml` dynamic input mask logic is preserved.
- [ ] Ensure all DND `MouseArea` delegates use `preventStealing: true` and `drag.target: proxy`.
- [ ] Confirm no global `QT_STYLE_OVERRIDE=kvantum` is added back to environment files.
- [ ] Verify `UiState.qml` aliases all persisted properties (`caffeineEnabled`, `comfortValue`, `grayscaleValue`, `vividValue`).
- [ ] Ensure all helper scripts pass `bash -n` syntax verification.
- [ ] **NEVER** run `hyprctl dismissnotify` or dismiss user notifications.
- [ ] Push directly to remote branches (`git push origin HEAD:main`) without local branch hopping.
- [ ] Commit with concise, descriptive commit messages and push to `origin/feat/hyprland-quickshell`.
- [ ] **DO NOT reload quickshell.** Notify the user that changes are pushed and ready for manual testing.

