import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "theme"
import "notifications" as Notifications
import "launcher" as Launcher
import "emoji" as Emoji
import "power" as Power
import "settings" as Settings

ShellRoot {
    id: root

    // ── Per-screen bars ──────────────────────────────────────
    Variants {
        model: Quickshell.screens
        delegate: Component {
            Bar {
                required property var modelData
                screen: modelData
            }
        }
    }

    // ── Global overlay instances ──────────────────────────────
    Notifications.NotificationToast { id: notifToast }
    Notifications.NotificationCenter { id: notifCenter }
    Launcher.Launcher { id: appLauncher }
    Emoji.EmojiPicker { id: emojiPicker }
    Power.PowerMenu { id: powerMenu }
    Settings.SettingsPanel { id: settingsPanel }

    // ── IPC handlers (triggered by hyprland keybindings) ─────
    IpcHandler {
        target: "launcher"
        function toggle() {
            appLauncher.isActive = !appLauncher.isActive
        }
    }

    IpcHandler {
        target: "emoji"
        function toggle() {
            emojiPicker.isActive = !emojiPicker.isActive
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle() {
            notifCenter.isActive = !notifCenter.isActive
        }
    }

    IpcHandler {
        target: "power"
        function toggle() {
            powerMenu.isActive = !powerMenu.isActive
        }
    }

    IpcHandler {
        target: "settings"
        function toggle() {
            settingsPanel.isActive = !settingsPanel.isActive
        }
    }
}
