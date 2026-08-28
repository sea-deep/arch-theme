import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: root
    implicitWidth: 400
    anchors.right: true
    anchors.top: true
    anchors.bottom: true
    
    WlrLayershell.layer: WlrLayer.Overlay
    color: "transparent"
    
    property bool isActive: false
    visible: isActive

    Process { id: hyprctl }

    function setHypr(keyword, value) {
        hyprctl.command = ["hyprctl", "keyword", keyword, value.toString()]
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
                    font.bold: true
                    color: Theme.fg
                    Layout.fillWidth: true
                }
                Button {
                    text: "×"
                    font.pixelSize: 24
                    background: Rectangle { color: "transparent" }
                    contentItem: Text { text: parent.text; color: Theme.fg }
                    onClicked: root.isActive = false
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 24

                    // Appearance
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "APPEARANCE"; font.bold: true; color: Theme.fgDim; font.family: Theme.fontFamilySans }
                        
                        RowLayout {
                            Text { text: "Gap size (inner)"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 0; to: 20; onValueChanged: setHypr("general:gaps_in", Math.round(value)) }
                        }
                        RowLayout {
                            Text { text: "Gap size (outer)"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 0; to: 20; onValueChanged: setHypr("general:gaps_out", Math.round(value)) }
                        }
                        RowLayout {
                            Text { text: "Border size"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 0; to: 5; onValueChanged: setHypr("general:border_size", Math.round(value)) }
                        }
                        RowLayout {
                            Text { text: "Corner rounding"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 0; to: 30; onValueChanged: setHypr("decoration:rounding", Math.round(value)) }
                        }
                    }

                    // Effects
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Text { text: "EFFECTS"; font.bold: true; color: Theme.fgDim; font.family: Theme.fontFamilySans }
                        
                        RowLayout {
                            Text { text: "Blur toggle"; color: Theme.fg; Layout.fillWidth: true }
                            Switch { onCheckedChanged: setHypr("decoration:blur:enabled", checked ? "true" : "false") }
                        }
                        RowLayout {
                            Text { text: "Blur strength"; color: Theme.fg; Layout.fillWidth: true }
                            Slider { from: 1; to: 10; onValueChanged: setHypr("decoration:blur:size", Math.round(value)) }
                        }
                        RowLayout {
                            Text { text: "Animations"; color: Theme.fg; Layout.fillWidth: true }
                            Switch { onCheckedChanged: setHypr("animations:enabled", checked ? "true" : "false") }
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
