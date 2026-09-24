//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "theme"
import "settings" as Settings
import "notifications" as Notifications
import "emoji" as Emoji
import "clipboard" as Clipboard
import "launcher" as Launcher
import "screenshot" as Screenshot
import "recorder" as Recorder
import "zathura" as ZathuraDoc
import Quickshell.Services.UPower

ShellRoot {
    id: root

    Component.onCompleted: {
        recorderProbe.running = true
        polkitService.running = true
    }

    Process {
        id: polkitService
        command: ["/usr/bin/systemctl", "--user", "start", "plasma-polkit-agent"]
    }

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

    // ── In-process Battery & Power Profile Automator ──
    Item {
        id: powerAutomator
        readonly property var dev: UPower.displayDevice
        readonly property bool hasBattery: dev !== null && dev.ready && dev.isPresent
        readonly property real pct: hasBattery ? dev.percentage : 1.0
        readonly property bool onBattery: UPower.onBattery
        property bool lowBatteryTriggered: false
        property bool initialized: false

        function evaluate() {
            if (!hasBattery) return

            if (onBattery) {
                if (pct <= 0.30) {
                    if (!lowBatteryTriggered) {
                        lowBatteryTriggered = true
                        Quickshell.execDetached([
                            Quickshell.shellPath("scripts/power_profile.sh"), "set", "powersave", "false", "low_battery"
                        ])
                    }
                } else {
                    lowBatteryTriggered = false
                    Quickshell.execDetached([
                        Quickshell.shellPath("scripts/power_profile.sh"), "set", "balanced", "false", "battery"
                    ])
                }
            } else {
                lowBatteryTriggered = false
                Quickshell.execDetached([
                    Quickshell.shellPath("scripts/power_profile.sh"), "set", "performance", "false", "ac"
                ])
            }
        }

        Connections {
            target: UPower
            function onOnBatteryChanged() {
                if (!powerAutomator.initialized) return
                powerAutomator.evaluate()
            }
        }

        Connections {
            target: powerAutomator.dev
            function onPercentageChanged() {
                if (!powerAutomator.initialized) return
                if (powerAutomator.onBattery) {
                    if (powerAutomator.pct <= 0.30 && !powerAutomator.lowBatteryTriggered) {
                        powerAutomator.lowBatteryTriggered = true
                        Quickshell.execDetached([
                            Quickshell.shellPath("scripts/power_profile.sh"), "set", "powersave", "false", "low_battery"
                        ])
                    } else if (powerAutomator.pct > 0.35) {
                        powerAutomator.lowBatteryTriggered = false
                    }
                }
            }
        }

        Component.onCompleted: {
            Qt.callLater(() => {
                initialized = true
            })
        }
    }

    // ── Per-screen bar, bottom corners, and native expanders ──
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    Variants {
        model: Quickshell.screens
        BottomCorners {}
    }

    Emoji.EmojiPicker {}
    Clipboard.ClipboardPicker {}
    Launcher.Launcher {}
    Screenshot.ScreenshotMenu {}
    Recorder.RecorderMenu {}
    ZathuraDoc.ZathuraMenu {}

    LazyLoader {
        active: UiState.settingsVisible
        component: Component { Settings.SettingsPanel {} }
    }

    // ── Native Wayland Global Shortcuts (0ms latency, zero process fork) ──
    GlobalShortcut {
        name: "apps"
        onPressed: UiState.toggleLauncher()
    }

    GlobalShortcut {
        name: "emoji"
        onPressed: UiState.toggleEmoji()
    }

    GlobalShortcut {
        name: "clipboard"
        onPressed: UiState.toggleClipboard("")
    }

    GlobalShortcut {
        name: "notifications"
        onPressed: UiState.toggleNotifications()
    }

    GlobalShortcut {
        name: "dismissAll"
        onPressed: {
            Notifications.NotificationServer.clearAll()
            UiState.notificationCenterVisible = false
            UiState.notificationPreviewVisible = false
        }
    }

    GlobalShortcut {
        name: "power"
        onPressed: UiState.togglePower()
    }

    GlobalShortcut {
        name: "screenshot"
        onPressed: UiState.toggleScreenshot()
    }

    GlobalShortcut {
        name: "recorder"
        onPressed: {
            if (UiState.recorderActive) {
                Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"])
            } else {
                UiState.recorderMenuVisible = !UiState.recorderMenuVisible
            }
        }
    }

    // ── IPC handlers (fallback / CLI) ─────
    IpcHandler {
        target: "launcher"
        function toggle() {
            UiState.toggleLauncher()
        }
    }

    IpcHandler {
        target: "emoji"
        function toggle() {
            UiState.toggleEmoji()
        }
    }

    IpcHandler {
        target: "clipboard"
        function toggle() {
            UiState.toggleClipboard("")
        }
    }

    IpcHandler {
        target: "notifications"
        function toggle() {
            UiState.toggleNotifications()
        }

        function dismissAll() {
            Notifications.NotificationServer.clearAll()
            UiState.notificationCenterVisible = false
            UiState.notificationPreviewVisible = false
        }

        function clear() {
            Notifications.NotificationServer.clearAll()
            UiState.notificationCenterVisible = false
            UiState.notificationPreviewVisible = false
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
        function toggle() {
            if (UiState.recorderActive) {
                Quickshell.execDetached(["pkill", "-INT", "-x", "wf-recorder"])
            } else {
                UiState.recorderMenuVisible = !UiState.recorderMenuVisible
            }
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

    IpcHandler {
        target: "screenshot"
        function toggle() {
            UiState.toggleScreenshot()
        }
    }

    IpcHandler {
        target: "zathuraMenu"
        function toggle() {
            UiState.toggleZathuraMenu()
        }
        function open() {
            UiState.closeOverlays()
            UiState.zathuraMenuVisible = true
        }
        function close() {
            UiState.zathuraMenuVisible = false
        }
    }

}
// force reload
