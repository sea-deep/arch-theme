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
                            Slider { from: 0; to: 20; value: 0; onMoved: setHypr("general:gaps_in", Math.round(value)) }
                        }
                        RowLayout {
                            Text { text: "Gap size (outer)"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 0; to: 20; value: 0; onMoved: setHypr("general:gaps_out", Math.round(value)) }
                        }
                        RowLayout {
                            Text { text: "Border size"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 0; to: 5; value: 2; onMoved: setHypr("general:border_size", Math.round(value)) }
                        }
                        RowLayout {
                            Text { text: "Corner rounding"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 0; to: 30; value: 10; onMoved: setHypr("decoration:rounding", Math.round(value)) }
                        }
                    }

                    // Effects
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "EFFECTS"; font.weight: Theme.fontWeight; color: Theme.fgDim; font.family: Theme.fontFamilySans }
                        
                        RowLayout {
                            Text { text: "Blur toggle"; color: Theme.fg; Layout.fillWidth: true }
                            Switch { checked: false; onCheckedChanged: setHypr("decoration:blur:enabled", checked ? "true" : "false") }
                        }
                        RowLayout {
                            Text { text: "Blur strength"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 1; to: 10; value: 7; onMoved: setHypr("decoration:blur:size", Math.round(value)) }
                        }
                        RowLayout {
                            Text { text: "Animations"; color: Theme.fg; Layout.fillWidth: true }
                            Switch { checked: true; onCheckedChanged: setHypr("animations:enabled", checked ? "true" : "false") }
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
