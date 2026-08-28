import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import Quickshell 1.0
import Quickshell.Io 1.0
import "../theme"

PanelWindow {
    id: root
    anchors.centerIn: parent
    width: 400
    height: 500
    color: "transparent"
    
    property bool isActive: false
    visible: isActive

    onIsActiveChanged: {
        if (isActive) {
            searchInput.forceActiveFocus()
            searchInput.text = ""
        }
    }

    // A sample subset of common emojis
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
        // Add more as needed...
    ]

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        radius: 16
        border.color: Theme.bgLight
        border.width: 1

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
