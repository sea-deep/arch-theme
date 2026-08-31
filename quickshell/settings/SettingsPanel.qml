import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../theme"

PanelWindow {
    WlrLayershell.namespace: "quickshell"
    id: root
    implicitWidth: 400
    anchors.right: true
    anchors.top: true
    anchors.bottom: true
    
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"
    
    visible: UiState.settingsVisible

    Shortcut {
        sequence: "Escape"
        onActivated: UiState.settingsVisible = false
    }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioAvailable: sink !== null && sink.audio !== null && sink.ready
    readonly property int maxBrightness: parseInt(maxBrightnessFile.text()) || 100
    readonly property int currentBrightness: parseInt(brightnessFile.text()) || 0

    PwObjectTracker {
        objects: [root.sink]
    }

    FileView {
        id: maxBrightnessFile
        path: "/sys/class/backlight/intel_backlight/max_brightness"
        watchChanges: true
        onFileChanged: reload()
    }

    FileView {
        id: brightnessFile
        path: "/sys/class/backlight/intel_backlight/brightness"
        watchChanges: true
        onFileChanged: reload()
    }

    property int gapsIn: 0
    property int gapsOut: 0
    property int borderSize: 2
    property int rounding: 10
    property bool blurEnabled: false
    property int blurSize: 7
    property bool animationsEnabled: true

    Process {
        id: hyprQuery
        command: ["/bin/sh", "-c", "echo '{\"gaps_in\":'$(hyprctl getoption general:gaps_in -j | jq -r '.int // .css' | awk '{print $1}')',\"gaps_out\":'$(hyprctl getoption general:gaps_out -j | jq -r '.int // .css' | awk '{print $1}')',\"border_size\":'$(hyprctl getoption general:border_size -j | jq -r '.int // 2')',\"rounding\":'$(hyprctl getoption decoration:rounding -j | jq -r '.int // 10')',\"blur\":'$(hyprctl getoption decoration:blur:enabled -j | jq -r '.bool // false')',\"blur_size\":'$(hyprctl getoption decoration:blur:size -j | jq -r '.int // 7')',\"animations\":'$(hyprctl getoption animations:enabled -j | jq -r '.bool // true')'}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim())
                    if (data.gaps_in !== undefined) root.gapsIn = Number(data.gaps_in) || 0
                    if (data.gaps_out !== undefined) root.gapsOut = Number(data.gaps_out) || 0
                    if (data.border_size !== undefined) root.borderSize = Number(data.border_size) || 2
                    if (data.rounding !== undefined) root.rounding = Number(data.rounding) || 10
                    if (data.blur !== undefined) root.blurEnabled = Boolean(data.blur)
                    if (data.blur_size !== undefined) root.blurSize = Number(data.blur_size) || 7
                    if (data.animations !== undefined) root.animationsEnabled = Boolean(data.animations)
                } catch(e) {}
            }
        }
    }

    onVisibleChanged: {
        if (visible && !hyprQuery.running) {
            hyprQuery.running = true
        }
    }

    Process { id: hyprctl }

    function setHypr(keyword, value) {
        var parts = keyword.split(":")
        var lua = "hl.config({"
        for (var i = 0; i < parts.length - 1; i++) {
            lua += " " + parts[i] + " = {"
        }
        var valStr = value.toString()
        if (valStr === "true" || valStr === "false" || !isNaN(Number(valStr))) {
            lua += " " + parts[parts.length - 1] + " = " + valStr
        } else {
            lua += " " + parts[parts.length - 1] + " = '" + valStr + "'"
        }
        for (var j = 0; j < parts.length - 1; j++) {
            lua += " }"
        }
        lua += " })"
        hyprctl.command = ["hyprctl", "repl", lua]
        hyprctl.running = true
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(26/255, 27/255, 38/255, 0.95)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "⚙ SETTINGS"
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 20
                    font.weight: Theme.fontWeight
                    color: Theme.fg
                    Layout.fillWidth: true
                }
                Button {
                    text: "×"
                    font.pixelSize: 24
                    background: Rectangle { color: "transparent" }
                    contentItem: Text { text: parent.text; color: Theme.fg }
                    onClicked: UiState.settingsVisible = false
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 24

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text { text: "QUICK CONTROLS"; font.weight: Theme.fontWeight; color: Theme.fgDim; font.family: Theme.fontFamilySans }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: root.audioAvailable && root.sink.audio.muted ? "󰖁" : "󰕾"; color: Theme.blue; font.family: Theme.fontFamily; font.pixelSize: 18 }
                            Slider {
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: root.audioAvailable ? root.sink.audio.volume * 100 : 0
                                onMoved: {
                                    if (root.audioAvailable)
                                        root.sink.audio.volume = value / 100
                                }
                            }
                            Text { text: root.audioAvailable ? Math.round(root.sink.audio.volume * 100) + "%" : "--%"; color: Theme.fg; font.family: Theme.fontFamily }
                            Button {
                                text: root.audioAvailable && root.sink.audio.muted ? "Unmute" : "Mute"
                                onClicked: {
                                    if (root.audioAvailable)
                                        root.sink.audio.muted = !root.sink.audio.muted
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "󰃠"; color: Theme.yellow; font.family: Theme.fontFamily; font.pixelSize: 18 }
                            Slider {
                                Layout.fillWidth: true
                                from: 1
                                to: 100
                                value: Math.round((root.currentBrightness / root.maxBrightness) * 100)
                                onMoved: Quickshell.execDetached([
                                    Quickshell.shellPath("scripts/brightness.sh"), "set", Math.round(value) + "%"
                                ])
                            }
                            Text { text: Math.round((root.currentBrightness / root.maxBrightness) * 100) + "%"; color: Theme.fg; font.family: Theme.fontFamily }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Caffeine mode"; color: Theme.fg; Layout.fillWidth: true }
                            Switch { checked: UiState.caffeineEnabled; onToggled: UiState.caffeineEnabled = checked }
                        }
                    }

                    // Appearance
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "APPEARANCE"; font.weight: Theme.fontWeight; color: Theme.fgDim; font.family: Theme.fontFamilySans }
                        
                        RowLayout {
                            Text { text: "Gap size (inner)"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 0; to: 20; value: root.gapsIn; onMoved: { root.gapsIn = Math.round(value); setHypr("general:gaps_in", root.gapsIn) } }
                        }
                        RowLayout {
                            Text { text: "Gap size (outer)"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 0; to: 20; value: root.gapsOut; onMoved: { root.gapsOut = Math.round(value); setHypr("general:gaps_out", root.gapsOut) } }
                        }
                        RowLayout {
                            Text { text: "Border size"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 0; to: 5; value: root.borderSize; onMoved: { root.borderSize = Math.round(value); setHypr("general:border_size", root.borderSize) } }
                        }
                        RowLayout {
                            Text { text: "Corner rounding"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 0; to: 30; value: root.rounding; onMoved: { root.rounding = Math.round(value); setHypr("decoration:rounding", root.rounding) } }
                        }
                    }

                    // Effects
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "EFFECTS"; font.weight: Theme.fontWeight; color: Theme.fgDim; font.family: Theme.fontFamilySans }
                        
                        RowLayout {
                            Text { text: "Blur toggle"; color: Theme.fg; Layout.fillWidth: true }
                            Switch { checked: root.blurEnabled; onToggled: { root.blurEnabled = checked; setHypr("decoration:blur:enabled", checked ? "true" : "false") } }
                        }
                        RowLayout {
                            Text { text: "Blur strength"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 1; to: 10; value: root.blurSize; onMoved: { root.blurSize = Math.round(value); setHypr("decoration:blur:size", root.blurSize) } }
                        }
                        RowLayout {
                            Text { text: "Animations"; color: Theme.fg; Layout.fillWidth: true }
                            Switch { checked: root.animationsEnabled; onToggled: { root.animationsEnabled = checked; setHypr("animations:enabled", checked ? "true" : "false") } }
                        }
                    }

                    Text {
                        text: "Changes are live but not saved to config files."
                        color: Theme.fgMuted
                        font.pixelSize: 12
                        font.italic: true
                        font.family: Theme.fontFamilySans
                        Layout.topMargin: 20
                    }
                }
            }
        }
    }
}
