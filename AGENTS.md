# AGENTS.md — Quickshell & Arch Theme Architecture & Guide

> **CRITICAL OPERATIONAL RULE FOR ALL AGENTS:**
> **DO NOT HOT-RELOAD OR KILL QUICKSHELL (`killall qs`, `hot_reload.sh`, `systemctl restart quickshell`, etc.)**
> The user will **ALWAYS** manually reload Quickshell themselves. Any unauthorized restarts disrupt their active desktop environment.

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
│   ├── selector/              # Universal fuzzy selector / modal (Selector.qml)
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

1. **Layer-Shell Surface Masking (`Bar.qml`):**
   - **Rule:** `Bar.qml`'s `mask: Region` must **NEVER** cover the full screen (`root.height`).
   - If `mask` covers the full screen, Hyprland gives all drop and pointer events to the invisible bar surface, blocking drops into desktop apps (Kitty, VSCode, Chrome, Discord).
   - **Correct Pattern:** Use discrete child item regions:
     ```qml
     mask: Region {
         Region { x: 0; y: 0; width: root.width; height: Theme.barHeight }
         Region { item: hardwarePill }
         Region { item: clipboardExpander }
         Region { item: networkExpander }
         Region { item: notificationExpander }
         Region { item: powerExpander }
         Region { item: clockExpander }
         Region { item: workspacesModule }
     }
     ```
2. **Layer Level (`WlrLayershell.layer`):**
   - Use `WlrLayer.Top` for `Bar.qml` and `Selector.qml` to allow Wayland DnD drops onto client windows.
3. **QtQuick Wayland Drag Mechanics (`ClipboardExpander.qml`):**
   - `DragHandler` does not initiate `wl_data_device.start_drag` in Qt 6 Wayland QPA.
   - Use `MouseArea` with `drag.target` set to a proxy `Item` (`expDragProxy`).
   - Provide `Drag.dragType: Drag.Automatic` and `Drag.supportedActions: Qt.CopyAction | Qt.MoveAction | Qt.LinkAction`.
   - **MIME Payload format:**
     - Text: `text/plain`, `text/plain;charset=utf-8`, and `UTF8_STRING`.
     - Files / Images: RFC-2483 CRLF-delimited `text/uri-list` (`file:///path\r\n`) and `x-special/gnome-copied-files` (`copy\nfile:///path\r\n`).
4. **Delegate Drag State Isolation:**
   - Never use global `Binding { target: UiState; property: "isDragging"; value: itemMouse.drag.active }` inside list delegates (competing rows will continuously overwrite it with `false`).
   - Use explicit `onPressed` / `onReleased` / `onCanceled` handlers on the delegate's `MouseArea`.

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

### C. Hyprland Screen Shaders & State Persistence

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

### D. PolicyKit Authentication & Qt Theming

1. **The `QT_STYLE_OVERRIDE` Trap:**
   - **NEVER** export `QT_STYLE_OVERRIDE=kvantum` globally.
   - Kvantum is a QWidget style only and lacks a Qt Quick Controls 2 QML module. Setting it causes Qt Quick QML apps (e.g. `polkit-kde-authentication-agent-1` / `QuickAuthDialog.qml`) to crash with `module "kvantum" is not installed` (`SEGV`).
2. **Unified Theming Stack:**
   - **Qt5 & Qt6 Platform Themes:** `qt5ct` / `qt6ct` with `style=kvantum`, `TokyoNight-SE` icons, and `IBM Plex Sans` font.
   - **Kvantum Config:** `Kvantum/kvantum.kvconfig` -> `theme=Kvantum-Tokyo-Night`.
   - **KDE / Polkit Config:** `~/.config/kdeglobals` -> Tokyo Night palette (`#1a1b26` bg, `#24283b` surface, `#39c5bb` accent).
   - **Polkit Agent Unit:** `plasma-polkit-agent.service` with drop-in override unsetting `QT_STYLE_OVERRIDE`.

---

## 3. Verification & Testing Checklist for Agents

Before concluding any change:
- [ ] Run `git diff` to verify syntax and ensure no stray brackets or duplicate property declarations exist.
- [ ] Ensure `Bar.qml` input mask remains discrete (never fullscreen).
- [ ] Ensure all DND `MouseArea` delegates use `preventStealing: true` and `drag.target: proxy`.
- [ ] Confirm no global `QT_STYLE_OVERRIDE=kvantum` is added back to environment files.
- [ ] Verify `UiState.qml` aliases all persisted properties (`caffeineEnabled`, `comfortValue`, `grayscaleValue`, `vividValue`).
- [ ] Commit with concise, descriptive commit messages and push to `origin/feat/hyprland-quickshell`.
- [ ] **DO NOT reload quickshell.** Notify the user that changes are pushed and ready for manual testing.
