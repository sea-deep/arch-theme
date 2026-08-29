import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"
import "EmojiData.js" as EmojiData

PanelWindow {
    WlrLayershell.namespace: "quickshell"
    id: root
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"
    visible: UiState.emojiVisible

    property int cursorX: -1
    property int cursorY: -1
    property string searchQuery: ""

    property var categoryList: [
        { name: "Smileys & Emotion", icon: "😀" },
        { name: "People & Body", icon: "👋" },
        { name: "Animals & Nature", icon: "🐻" },
        { name: "Food & Drink", icon: "🍔" },
        { name: "Travel & Places", icon: "🚗" },
        { name: "Activities", icon: "⚽" },
        { name: "Objects", icon: "💡" },
        { name: "Symbols", icon: "💖" },
        { name: "Flags", icon: "🚩" }
    ]

    property var flatEmojis: []
    property var displayEmojis: []
    property var categoryIndices: ({})

    function filterEmojis(query) {
        if (query === "") {
            root.displayEmojis = root.flatEmojis
        } else {
            var result = []
            for (var i = 0; i < root.flatEmojis.length; i++) {
                var e = root.flatEmojis[i]
                if (e.name.toLowerCase().indexOf(query) !== -1) {
                    result.push(e)
                }
            }
            root.displayEmojis = result
        }
    }

    function selectEmoji(char) {
        UiState.emojiVisible = false
        typeProc.command = [Quickshell.shellPath("scripts/type-emoji.sh"), char]
        typeProc.running = true
    }

    Component.onCompleted: {
        var list = []
        var indices = {}
        var idx = 0
        for (var i = 0; i < categoryList.length; i++) {
            var catName = categoryList[i].name
            indices[catName] = idx
            var ems = EmojiData.categories[catName] || []
            for (var j = 0; j < ems.length; j++) {
                list.push({
                    char: ems[j].char,
                    name: ems[j].name,
                    category: catName
                })
                idx++
            }
        }
        flatEmojis = list
        displayEmojis = list
        categoryIndices = indices
    }

    onVisibleChanged: {
        if (visible) {
            cursorX = -1
            cursorY = -1
            searchQuery = ""
            searchInput.text = ""
            filterEmojis("")
            posProc.running = true
            Qt.callLater(() => searchInput.forceActiveFocus())
        }
    }

    // Click outside to close
    TapHandler {
        onTapped: UiState.emojiVisible = false
    }

    // Get cursor position
    Process {
        id: posProc
        command: ["hyprctl", "cursorpos"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(",")
                if (parts.length === 2) {
                    var cx = parseInt(parts[0].trim())
                    var cy = parseInt(parts[1].trim())
                    var popupW = 340
                    var popupH = 440

                    if (cx + popupW > root.width) cx = root.width - popupW - 10
                    if (cy + popupH > root.height) cy = root.height - popupH - 10
                    if (cx < 10) cx = 10
                    if (cy < 10) cy = 10

                    root.cursorX = cx
                    root.cursorY = cy
                }
            }
        }
    }

    // Type emoji (wtype with wl-copy fallback)
    Process {
        id: typeProc
    }

    // Popup
    Rectangle {
        id: popup
        width: 340
        height: 440
        x: root.cursorX < 0 ? (root.width - width) / 2 : root.cursorX
        y: root.cursorY < 0 ? (root.height - height) / 2 : root.cursorY
        visible: root.cursorX >= 0 || !posProc.running

        color: Theme.bg
        radius: 12
        border.color: Theme.surface
        border.width: 1

        // Consume clicks so they don't close the popup
        TapHandler {}

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Search bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                color: Theme.bgLight
                radius: 8
                border.color: searchInput.activeFocus ? Theme.accent : "transparent"
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Text {
                        text: "󰍉"
                        color: Theme.fgDim
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Theme.fg
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 13
                        verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: {
                            root.searchQuery = text.toLowerCase()
                            root.filterEmojis(root.searchQuery)
                        }
                        Keys.onEscapePressed: UiState.emojiVisible = false
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down) {
                                grid.forceActiveFocus()
                                grid.currentIndex = 0
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            // Emoji grid (wrapped in Item for proper ColumnLayout sizing)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                GridView {
                    id: grid
                    anchors.fill: parent
                    cellWidth: 39.5
                    cellHeight: 39.5
                    clip: true
                    model: root.displayEmojis
                    activeFocusOnTab: true

                    Keys.onEscapePressed: UiState.emojiVisible = false
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (currentItem) {
                                root.selectEmoji(currentItem.modelData.char)
                            }
                            event.accepted = true
                        }
                    }

                    delegate: Rectangle {
                        id: delegateRoot
                        required property var modelData
                        required property int index

                        width: grid.cellWidth
                        height: grid.cellHeight
                        color: (grid.activeFocus && grid.currentIndex === index) || hover.hovered ? Theme.bgLight : "transparent"
                        radius: 8

                        HoverHandler { id: hover }
                        TapHandler {
                            onTapped: root.selectEmoji(delegateRoot.modelData.char)
                        }

                        Text {
                            anchors.centerIn: parent
                            text: delegateRoot.modelData.char
                            font.pixelSize: 22
                        }
                    }
                }
            }

            // Category separator
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.surface
                visible: root.searchQuery === ""
            }

            // Category tabs
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 32
                spacing: 4
                visible: root.searchQuery === ""

                Repeater {
                    model: root.categoryList
                    Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: catHover.hovered ? Theme.bgLight : "transparent"
                        radius: 6

                        HoverHandler { id: catHover }
                        TapHandler {
                            onTapped: {
                                var idx = root.categoryIndices[modelData.name]
                                if (idx !== undefined) {
                                    grid.positionViewAtIndex(idx, GridView.Beginning)
                                    grid.currentIndex = idx
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.pixelSize: 16
                        }
                    }
                }
            }
        }
    }
}
