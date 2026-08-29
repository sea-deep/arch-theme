//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "theme"
import "selector" as Selector
import "settings" as Settings
import "notifications" as Notifications
import "notifications" as Notifications

ShellRoot {
    id: root

    Component.onCompleted: recorderProbe.running = true

    // One global producer for every monitor's recording indicator. Once a
    // recorder exists, pidwait gives us an event-driven exit notification.
    Process {
        id: recorderProbe
        command: ["/usr/bin/pgrep", "-x", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            UiState.recorderActive = exitCode === 0
            if (UiState.recorderActive && !recorderWait.running)
                recorderWait.running = true
        }
    }

    Process {
        id: recorderWait
        command: ["/usr/sbin/pidwait", "-x", "wf-recorder"]
        onExited: (exitCode, exitStatus) => {
            UiState.recorderActive = false
            if (!recorderProbe.running)
                recorderProbe.running = true
        }
    }

    // ── Per-screen bar and native expanders ──────────────────
    Variants {
        model: Quickshell.screens
        Bar {}
}

// Notifications.NotificationCenter {
// }

    LazyLoader {
        active: UiState.selectorVisible
        component: Component { Selector.Selector {} }
    }

    LazyLoader {
        active: UiState.settingsVisible
        component: Component { Settings.SettingsPanel {} }
    }

    // ── IPC handlers (triggered by hyprland keybindings) ─────
    IpcHandler {
        target: "launcher"
        function toggle() {
            UiState.toggleSelector("apps")
        }
    }

    IpcHandler {
        target: "emoji"
        function toggle() {
            UiState.toggleSelector("emoji")
        }
    }

    IpcHandler {
        target: "clipboard"
        function toggle() {
            UiState.toggleSelector("clipboard")
        }
    }

    IpcHandler {
        target: "selector"
        function apps() {
            UiState.toggleSelector("apps")
        }

        function emoji() {
            UiState.toggleSelector("emoji")
        }

        function clipboard() {
            UiState.toggleSelector("clipboard")
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle() {
            UiState.toggleNotifications()
        }
    }

    IpcHandler {
        target: "power"
        function toggle() {
            UiState.togglePower()
        }
    }

    IpcHandler {
        target: "clock"
        function toggle() {
            UiState.toggleClock()
        }

        function calendar() {
            UiState.showClockTab("calendar")
        }

        function time() {
            UiState.showClockTab("time")
        }
    }

    IpcHandler {
        target: "recorder"
        function refresh() {
            if (!recorderProbe.running)
                recorderProbe.running = true
        }
    }

    IpcHandler {
        target: "settings"
        function toggle() {
            UiState.toggleSettings()
        }
    }

    IpcHandler {
        target: "quickControls"
        function audio() {
            UiState.toggleQuickControl("audio")
        }

        function brightness() {
            UiState.toggleQuickControl("brightness")
        }

        function battery() {
            UiState.toggleQuickControl("battery")
        }
    }

}
// force reload
