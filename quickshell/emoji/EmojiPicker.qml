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
    property int emojiCount: 0

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

    // Internal storage — never bound as a model directly
    property var allEmojis: []
    // Filtered list — assigned as model
    property var displayEmojis: []
    property var categoryIndices: ({})

    function buildEmojiList() {
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
        allEmojis = list
        categoryIndices = indices
    }

    function filterEmojis(query) {
        var src = root.allEmojis
        var result = []
        for (var i = 0; i < src.length; i++) {
            var e = src[i]
            if (query === "" || e.name.toLowerCase().indexOf(query) !== -1) {
                result.push(e)
            }
        }
        root.displayEmojis = result
        root.emojiCount = result.length
    }

    function selectEmoji(emoji) {
        UiState.emojiVisible = false
        Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/type-emoji.sh"), emoji])
    }

    Component.onCompleted: {
        buildEmojiList()
        filterEmojis("")
    }

    onVisibleChanged: {
        if (visible) {
            cursorX = -1
            cursorY = -1
            searchQuery = ""
            searchInput.text = ""
            filterEmojis("")
            posProc.running = true
            Qt.callLater(function() { searchInput.forceActiveFocus() })
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

            // Emoji grid
            GridView {
                id: grid
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 100
                cellWidth: 39.5
                cellHeight: 39.5
                clip: true
                model: root.emojiCount
                activeFocusOnTab: true

                    Keys.onEscapePressed: UiState.emojiVisible = false
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (currentIndex >= 0 && currentIndex < root.displayEmojis.length) {
                                root.selectEmoji(root.displayEmojis[currentIndex].char)
                            }
                            event.accepted = true
                        }
                    }

                    delegate: Rectangle {
                        id: delegateRoot
                        required property int index

                        property var emoji: index < root.displayEmojis.length ? root.displayEmojis[index] : null

                        width: grid.cellWidth
                        height: grid.cellHeight
                        color: (grid.activeFocus && grid.currentIndex === index) || hover.hovered ? Theme.bgLight : "transparent"
                        radius: 8

                        HoverHandler { id: hover }
                        TapHandler {
                            onTapped: {
                                if (delegateRoot.emoji)
                                    root.selectEmoji(delegateRoot.emoji.char)
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: delegateRoot.emoji ? delegateRoot.emoji.char : ""
                            font.pixelSize: 22
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
