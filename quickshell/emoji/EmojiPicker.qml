import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"
import "../components" as Components
import "EmojiData.js" as EmojiData

PanelWindow {
    WlrLayershell.namespace: "quickshell"
    id: root
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.showing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    color: "transparent"
    property bool showing: UiState.emojiVisible
    property real reveal: showing ? 1 : 0

    Behavior on reveal {
        NumberAnimation {
            duration: Theme.durationMedium
            easing.type: Theme.easingDecelerate
        }
    }

    visible: reveal > 0

    Shortcut {
        sequence: "Escape"
        enabled: root.showing
        onActivated: UiState.emojiVisible = false
    }

    property int cursorX: -1
    property int cursorY: -1
    property string searchQuery: ""
    property string activeCategory: "Recent"

    property var categoryList: [
        { name: "Recent", icon: "🕒" },
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

    FileView {
        id: recentEmojisFile
        path: Quickshell.env("HOME") + "/.config/quickshell/state/recent_emojis.json"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            if (activeCategory === "Recent" && searchQuery === "") {
                loadCategory("Recent")
            }
        }
    }

    property var displayEmojis: []
    property int emojiCount: 0

    function getRecentEmojis() {
        try {
            var raw = recentEmojisFile.text().trim()
            if (!raw) return []
            var parsed = JSON.parse(raw)
            if (Array.isArray(parsed)) return parsed.slice(0, 56)
        } catch(e) {}
        return []
    }

    function recordRecentEmoji(emojiChar) {
        if (!emojiChar) return
        var recents = getRecentEmojis()
        recents = recents.filter(function(c) { return c !== emojiChar })
        recents.unshift(emojiChar)
        if (recents.length > 56) recents = recents.slice(0, 56)
        var jsonStr = JSON.stringify(recents)
        Quickshell.execDetached(["bash", "-c", "mkdir -p ~/.config/quickshell/state && printf '%s\\n' '" + jsonStr.replace(/'/g, "'\\''") + "' > ~/.config/quickshell/state/recent_emojis.json"])
    }

    function loadCategory(catName) {
        activeCategory = catName
        if (catName === "Recent") {
            var recents = getRecentEmojis()
            if (recents.length > 0) {
                var list = []
                for (var r = 0; r < recents.length; r++) {
                    list.push({
                        char: recents[r],
                        name: "recent",
                        category: "Recent"
                    })
                }
                displayEmojis = list
                emojiCount = list.length
                return
            }
            // If Recent is empty, fallback to Smileys & Emotion
            activeCategory = "Smileys & Emotion"
            catName = "Smileys & Emotion"
        }

        var ems = EmojiData.categories[catName] || []
        var list = []
        for (var i = 0; i < ems.length; i++) {
            list.push({
                char: ems[i].char,
                name: ems[i].name,
                category: catName
            })
        }
        displayEmojis = list
        emojiCount = list.length
    }

    function filterEmojis(query) {
        if (query === "") {
            loadCategory(activeCategory)
            return
        }
        var result = []
        var seen = {}
        for (var cat in EmojiData.categories) {
            var ems = EmojiData.categories[cat] || []
            for (var i = 0; i < ems.length; i++) {
                var e = ems[i]
                if (!seen[e.char]) {
                    var match = e.name.toLowerCase().indexOf(query) !== -1
                    if (!match && e.tags) {
                        for (var t = 0; t < e.tags.length; t++) {
                            if (e.tags[t].toLowerCase().indexOf(query) !== -1) {
                                match = true
                                break
                            }
                        }
                    }
                    if (match) {
                        seen[e.char] = true
                        result.push({
                            char: e.char,
                            name: e.name,
                            category: cat
                        })
                    }
                }
            }
        }
        displayEmojis = result
        emojiCount = result.length
    }

    function selectEmoji(emoji) {
        recordRecentEmoji(emoji)
        UiState.emojiVisible = false
        Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/type-emoji.sh"), emoji])
    }

    Process {
        id: cursorQuery
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(text.trim())
                    if (data.x !== undefined && data.y !== undefined) {
                        root.updateCoordinates(Number(data.x), Number(data.y))
                    }
                } catch(e) {}
            }
        }
    }

    function updateCoordinates(cx, cy) {
        var screenW = (root.screen && root.screen.width > 0) ? root.screen.width : (root.width > 0 ? root.width : 1920)
        var screenH = (root.screen && root.screen.height > 0) ? root.screen.height : (root.height > 0 ? root.height : 1080)
        var popupW = 340
        var popupH = 440

        var targetX = cx - (popupW / 2)
        if (targetX + popupW > screenW - 16) targetX = screenW - popupW - 16
        if (targetX < 16) targetX = 16

        var targetY = cy + 16
        if (targetY + popupH > screenH - 16) {
            targetY = cy - popupH - 16
        }
        if (targetY < 16) targetY = 16

        root.cursorX = targetX
        root.cursorY = targetY
    }

    Component.onCompleted: {
        var recents = getRecentEmojis()
        if (recents.length > 0) {
            loadCategory("Recent")
        } else {
            loadCategory("Smileys & Emotion")
        }
    }

    onShowingChanged: {
        if (showing) {
            cursorQuery.running = true
            searchQuery = ""
            searchInput.text = ""
            var recents = getRecentEmojis()
            if (recents.length > 0) {
                loadCategory("Recent")
            } else {
                loadCategory("Smileys & Emotion")
            }
            grid.currentIndex = 0
            grid.positionViewAtBeginning()
            searchInput.forceActiveFocus()
        }
    }

    // Click outside to close (backdrop) - transparent, NO dimming
    MouseArea {
        anchors.fill: parent
        enabled: root.showing
        onClicked: UiState.emojiVisible = false
    }

    // Popup
    Rectangle {
        id: popup
        readonly property int fullHeight: 440
        width: 340
        height: fullHeight * root.reveal
        clip: true
        x: root.cursorX >= 0 ? root.cursorX : (root.width - width) / 2
        y: root.cursorY >= 0 ? root.cursorY : (root.height - fullHeight) / 2
        visible: height > 0

        color: Theme.bg
        radius: 12
        border.color: Theme.surface
        border.width: 1

        // Consume clicks so they don't hit the backdrop MouseArea
        TapHandler {}

        Item {
            anchors.top: parent.top
            anchors.topMargin: (1.0 - root.reveal) * -16
            width: parent.width
            height: popup.fullHeight

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
                            grid.currentIndex = 0
                            grid.positionViewAtBeginning()
                        }
                        onAccepted: {
                            if (root.displayEmojis.length > 0) {
                                var targetIdx = (grid.currentIndex >= 0 && grid.currentIndex < root.displayEmojis.length) ? grid.currentIndex : 0
                                root.selectEmoji(root.displayEmojis[targetIdx].char)
                            }
                        }
                        Keys.onEscapePressed: UiState.emojiVisible = false
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Down) {
                                if (grid.count > 0) {
                                    grid.currentIndex = Math.min(grid.count - 1, grid.currentIndex + 8)
                                    grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                if (grid.count > 0) {
                                    grid.currentIndex = Math.max(0, grid.currentIndex - 8)
                                    grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Right) {
                                if (grid.count > 0) {
                                    grid.currentIndex = Math.min(grid.count - 1, grid.currentIndex + 1)
                                    grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Left) {
                                if (grid.count > 0) {
                                    grid.currentIndex = Math.max(0, grid.currentIndex - 1)
                                    grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (root.displayEmojis.length > 0) {
                                    var targetIdx = (grid.currentIndex >= 0 && grid.currentIndex < root.displayEmojis.length) ? grid.currentIndex : 0
                                    root.selectEmoji(root.displayEmojis[targetIdx].char)
                                }
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
                model: root.displayEmojis
                activeFocusOnTab: true
                highlightFollowsCurrentItem: true
                keyNavigationEnabled: true

                Keys.onEscapePressed: UiState.emojiVisible = false
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (currentIndex >= 0 && currentIndex < root.displayEmojis.length) {
                            root.selectEmoji(root.displayEmojis[currentIndex].char)
                        } else if (root.displayEmojis.length > 0) {
                            root.selectEmoji(root.displayEmojis[0].char)
                        }
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up && currentIndex < 8) {
                        searchInput.forceActiveFocus()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Backspace) {
                        searchInput.forceActiveFocus()
                        if (searchInput.text.length > 0) {
                            searchInput.text = searchInput.text.slice(0, -1)
                        }
                        event.accepted = true
                    } else if (event.text && event.text.length > 0 && event.text.charCodeAt(0) >= 32 && event.key !== Qt.Key_Space) {
                        searchInput.forceActiveFocus()
                        searchInput.text += event.text
                        event.accepted = true
                    }
                }

                delegate: Rectangle {
                    id: delegateRoot
                    required property var modelData
                    required property int index

                    property bool isCurrent: (grid.currentIndex === index)

                    width: grid.cellWidth
                    height: grid.cellHeight
                    color: isCurrent ? Theme.accent : (emojiMouseArea.containsMouse ? Theme.bgLight : "transparent")
                    radius: 8

                    MouseArea {
                        id: emojiMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            grid.currentIndex = index
                            if (delegateRoot.modelData)
                                root.selectEmoji(delegateRoot.modelData.char)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: delegateRoot.modelData ? delegateRoot.modelData.char : ""
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

            // Category tabs (compact & shortened)
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                spacing: 2
                visible: root.searchQuery === ""

                Repeater {
                    model: root.categoryList
                    Rectangle {
                        required property var modelData
                        readonly property bool isActive: (root.activeCategory === modelData.name) && (root.searchQuery === "")
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: isActive ? Theme.accent : (catMouseArea.containsMouse ? Theme.bgLight : "transparent")
                        radius: 4

                        MouseArea {
                            id: catMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.loadCategory(modelData.name)
                                grid.currentIndex = 0
                                grid.positionViewAtBeginning()
                                grid.forceActiveFocus()
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}
}
