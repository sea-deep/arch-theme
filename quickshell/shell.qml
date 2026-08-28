import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "theme" as Theme
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
    Notifications.NotificationServer { id: notifServer }
    Notifications.NotificationToast { id: notifToast }
    Notifications.NotificationCenter { id: notifCenter }
    Launcher.Launcher { id: appLauncher }
    Emoji.EmojiPicker { id: emojiPicker }
    Power.PowerMenu { id: powerMenu }
    Settings.SettingsPanel { id: settingsPanel }

    // ── IPC handlers (triggered by hyprland keybindings) ─────
    IpcHandler {
        name: "launcher"
        onMessage: {
            appLauncher.isActive = !appLauncher.isActive
        }
    }

    IpcHandler {
        name: "emoji"
        onMessage: {
            emojiPicker.isActive = !emojiPicker.isActive
        }
    }

    IpcHandler {
        name: "notifications"
        onMessage: {
            notifCenter.isActive = !notifCenter.isActive
        }
    }

    IpcHandler {
        name: "power"
        onMessage: {
            powerMenu.isActive = !powerMenu.isActive
        }
    }

    IpcHandler {
        name: "settings"
        onMessage: {
            settingsPanel.isActive = !settingsPanel.isActive
        }
    }
}
