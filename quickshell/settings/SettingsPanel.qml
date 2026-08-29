import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Services.Pipewire
import "../theme"
import "../services"
import "../components" as Components

PanelWindow {
    WlrLayershell.namespace: "quickshell"
    id: root
    implicitWidth: 380
    anchors.right: true
    anchors.top: true
    anchors.bottom: true
    margins.top: Theme.outerGap
    margins.right: Theme.outerGap
    margins.bottom: Theme.outerGap
    
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
    property real innerGapValue: 0
    property real outerGapValue: 2
    property real borderSizeValue: 2
    property real roundingValue: 10
    property real blurStrengthValue: 7
    property string pendingHyprKeyword: ""
    property string pendingHyprValue: ""

    PwObjectTracker {
        objects: [root.sink]
    }

    function setHypr(keyword, value) {
        pendingHyprKeyword = keyword
        pendingHyprValue = value.toString()
        hyprUpdateTimer.restart()
    }

    Timer {
        id: hyprUpdateTimer
        interval: 40
        onTriggered: {
            if (root.pendingHyprKeyword === "")
                return
            Quickshell.execDetached([
                "hyprctl", "keyword", root.pendingHyprKeyword,
                root.pendingHyprValue
            ])
            root.pendingHyprKeyword = ""
            root.pendingHyprValue = ""
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.panel
        radius: Theme.radiusLarge
        border.width: Theme.borderWidth
        border.color: Theme.primary

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
                Rectangle {
                    implicitWidth: 30
                    implicitHeight: 30
                    radius: Theme.radiusMedium
                    color: settingsCloseHover.hovered
                        ? Theme.surfaceMedium : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: settingsCloseHover.hovered
                            ? Theme.danger : Theme.textSecondary
                        font.pixelSize: 20
                    }
                    HoverHandler { id: settingsCloseHover }
                    TapHandler { onTapped: UiState.settingsVisible = false }
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
                            Components.ValueSlider {
                                Layout.fillWidth: true
                                from: 0
                                to: 100
                                value: root.audioAvailable ? root.sink.audio.volume * 100 : 0
                                onMoved: value => {
                                    if (root.audioAvailable)
                                        root.sink.audio.volume = value / 100
                                }
                            }
                            Text { text: root.audioAvailable ? Math.round(root.sink.audio.volume * 100) + "%" : "--%"; color: Theme.fg; font.family: Theme.fontFamily }
                            Rectangle {
                                implicitWidth: 64
                                implicitHeight: 30
                                radius: Theme.radiusMedium
                                color: muteHover.hovered
                                    ? Theme.surfaceHigh : Theme.surfaceLow
                                Text {
                                    anchors.centerIn: parent
                                    text: root.audioAvailable && root.sink.audio.muted ? "Unmute" : "Mute"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: Theme.fontSizeSmall
                                }
                                HoverHandler { id: muteHover }
                                TapHandler { onTapped: {
                                    if (root.audioAvailable)
                                        root.sink.audio.muted = !root.sink.audio.muted
                                } }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "󰃠"; color: Theme.yellow; font.family: Theme.fontFamily; font.pixelSize: 18 }
                            Components.ValueSlider {
                                Layout.fillWidth: true
                                enabled: Brightness.available
                                value: Brightness.ratio
                                onMoved: value => Brightness.setRatio(value)
                            }
                            Text { text: Brightness.available ? Brightness.percentage + "%" : "--%"; color: Theme.fg; font.family: Theme.fontFamily }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Text { text: "Caffeine mode"; color: Theme.fg; Layout.fillWidth: true }
                            Components.ToggleSwitch {
                                checked: UiState.caffeineEnabled
                                onToggled: checked => UiState.caffeineEnabled = checked
                            }
                        }
                    }

                    // Appearance
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "APPEARANCE"; font.weight: Theme.fontWeight; color: Theme.fgDim; font.family: Theme.fontFamilySans }
                        
                        RowLayout {
                            Text { text: "Gap size (inner)"; color: Theme.fg; Layout.fillWidth: true }
                            Components.ValueSlider {
                                Layout.preferredWidth: 160
                                from: 0; to: 20; stepSize: 1
                                value: root.innerGapValue
                                onMoved: value => {
                                    root.innerGapValue = value
                                    root.setHypr("general:gaps_in", Math.round(value))
                                }
                            }
                        }
                        RowLayout {
                            Text { text: "Gap size (outer)"; color: Theme.fg; Layout.fillWidth: true }
                            Components.ValueSlider {
                                Layout.preferredWidth: 160
                                from: 0; to: 20; stepSize: 1
                                value: root.outerGapValue
                                onMoved: value => {
                                    root.outerGapValue = value
                                    root.setHypr("general:gaps_out", Math.round(value))
                                }
                            }
                        }
                        RowLayout {
                            Text { text: "Border size"; color: Theme.fg; Layout.fillWidth: true }
                            Components.ValueSlider {
                                Layout.preferredWidth: 160
                                from: 0; to: 5; stepSize: 1
                                value: root.borderSizeValue
                                onMoved: value => {
                                    root.borderSizeValue = value
                                    root.setHypr("general:border_size", Math.round(value))
                                }
                            }
                        }
                        RowLayout {
                            Text { text: "Corner rounding"; color: Theme.fg; Layout.fillWidth: true }
                            Components.ValueSlider {
                                Layout.preferredWidth: 160
                                from: 0; to: 30; stepSize: 1
                                value: root.roundingValue
                                onMoved: value => {
                                    root.roundingValue = value
                                    root.setHypr("decoration:rounding", Math.round(value))
                                }
                            }
                        }
                    }

                    // Effects
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "EFFECTS"; font.weight: Theme.fontWeight; color: Theme.fgDim; font.family: Theme.fontFamilySans }
                        
                        RowLayout {
                            Text { text: "Blur toggle"; color: Theme.fg; Layout.fillWidth: true }
                            Components.ToggleSwitch {
                                id: blurSwitch
                                checked: false
                                onToggled: checked => {
                                    blurSwitch.checked = checked
                                    root.setHypr("decoration:blur:enabled", checked ? "true" : "false")
                                }
                            }
                        }
                        RowLayout {
                            Text { text: "Blur strength"; color: Theme.fg; Layout.fillWidth: true }
                            Components.ValueSlider {
                                Layout.preferredWidth: 160
                                from: 1; to: 10; stepSize: 1
                                value: root.blurStrengthValue
                                onMoved: value => {
                                    root.blurStrengthValue = value
                                    root.setHypr("decoration:blur:size", Math.round(value))
                                }
                            }
                        }
                        RowLayout {
                            Text { text: "Animations"; color: Theme.fg; Layout.fillWidth: true }
                            Components.ToggleSwitch {
                                id: animationSwitch
                                checked: true
                                onToggled: checked => {
                                    animationSwitch.checked = checked
                                    root.setHypr("animations:enabled", checked ? "true" : "false")
                                }
                            }
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
