import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    WlrLayershell.namespace: "quickshell"
    id: root
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Overlay
    color: Qt.rgba(26/255, 27/255, 38/255, 0.7)
    
    property bool isActive: false
    visible: isActive

    onIsActiveChanged: {
        if (isActive) {
            searchInput.forceActiveFocus()
            searchInput.text = ""
        }
    }

    TapHandler {
        onTapped: root.isActive = false
    }

    property var allEmojis: [
        {"char": "😀", "name": "grinning face"},
        {"char": "😂", "name": "face with tears of joy"},
        {"char": "🥰", "name": "smiling face with hearts"},
        {"char": "😎", "name": "smiling face with sunglasses"},
        {"char": "🤔", "name": "thinking face"},
        {"char": "👍", "name": "thumbs up"},
        {"char": "🙌", "name": "raising hands"},
        {"char": "❤️", "name": "red heart"},
        {"char": "✨", "name": "sparkles"},
        {"char": "🔥", "name": "fire"},
        {"char": "🎉", "name": "party popper"},
        {"char": "🚀", "name": "rocket"},
        {"char": "👀", "name": "eyes"},
        {"char": "💯", "name": "hundred points"},
        {"char": "💀", "name": "skull"}
    ]

    Rectangle {
        implicitWidth: 400
        implicitHeight: 500
        anchors.centerIn: parent
        color: Theme.bg
        radius: 16
        border.color: Theme.bgLight
        border.width: 1

        TapHandler {
            // consume clicks on the card
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: Theme.bgLight
                radius: 8

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.margins: 10
                    color: Theme.fg
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 16
                    verticalAlignment: TextInput.AlignVCenter
                    
                    Keys.onEscapePressed: root.isActive = false
                }
            }

            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: width / 6
                cellHeight: cellWidth
                clip: true
                
                model: root.allEmojis.filter(function(e) {
                    var query = searchInput.text.toLowerCase();
                    return e.name.includes(query);
                })

                delegate: Rectangle {
                    width: grid.cellWidth
                    height: grid.cellHeight
                    color: hover.hovered ? Theme.bgLight : "transparent"
                    radius: 8

                    HoverHandler { id: hover }
                    TapHandler {
                        onTapped: {
                            copyProcess.command = ["wl-copy", modelData.char]
                            copyProcess.running = true
                            root.isActive = false
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.char
                        font.pixelSize: 28
                    }
                }
            }
        }
    }

    Process {
        id: copyProcess
    }
}
