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
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"
    property bool showing: UiState.emojiVisible
    property real reveal: showing ? 1 : 0

    Behavior on reveal {
        NumberAnimation {
            duration: root.showing ? 160 : 120
            easing.type: root.showing ? Easing.OutCubic : Easing.InQuad
        }
    }

    visible: reveal > 0

    Shortcut {
        sequence: "Escape"
        enabled: UiState.emojiVisible
        onActivated: UiState.emojiVisible = false
    }

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
        if (query === "") {
            root.displayEmojis = root.allEmojis
            root.emojiCount = root.allEmojis.length
            return
        }
        var src = root.allEmojis
        var result = []
        for (var i = 0; i < src.length; i++) {
            var e = src[i]
            if (e.name.toLowerCase().indexOf(query) !== -1) {
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

    function updateCoordinates(cx, cy) {
        var screenW = (root.screen && root.screen.width > 0) ? root.screen.width : (root.width > 0 ? root.width : 1920)
        var screenH = (root.screen && root.screen.height > 0) ? root.screen.height : (root.height > 0 ? root.height : 1080)
        var popupW = 480
        var popupH = 380
        if (cx + popupW > screenW) cx = screenW - popupW - 10
        if (cy + popupH > screenH) cy = screenH - popupH - 10
        if (cx < 10) cx = 10
        if (cy < 10) cy = 10
        root.cursorX = cx
        root.cursorY = cy
    }

    Component.onCompleted: {
        buildEmojiList()
        root.displayEmojis = root.allEmojis
        root.emojiCount = root.allEmojis.length
    }

    onShowingChanged: {
        if (showing) {
            searchQuery = ""
            searchInput.text = ""
            root.displayEmojis = root.allEmojis
            root.emojiCount = root.allEmojis.length
            searchInput.forceActiveFocus()
        }
    }

    // Click outside to close (backdrop) - transparent, NO dimming
    MouseArea {
        anchors.fill: parent
        onClicked: UiState.emojiVisible = false
    }

    // Bottom drawer container
    Components.BottomDrawerSurface {
        id: popup
        width: 480
        height: 380
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        transform: Translate {
            y: (1 - root.reveal) * (popup.height + 32)
        }

        // Consume clicks so they don't hit the backdrop MouseArea
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
                                    grid.currentIndex = Math.min(grid.count - 1, grid.currentIndex + 10)
                                    grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
                                }
                                event.accepted = true
                            } else if (event.key === Qt.Key_Up) {
                                if (grid.count > 0) {
                                    grid.currentIndex = Math.max(0, grid.currentIndex - 10)
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
                cellWidth: 45.6
                cellHeight: 44
                clip: true
                model: root.emojiCount
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
                    required property int index

                    property var emoji: index < root.displayEmojis.length ? root.displayEmojis[index] : null
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
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: catMouseArea.containsMouse ? Theme.bgLight : "transparent"
                        radius: 4

                        MouseArea {
                            id: catMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var idx = root.categoryIndices[modelData.name]
                                if (idx !== undefined) {
                                    grid.positionViewAtIndex(idx, GridView.Beginning)
                                    grid.currentIndex = idx
                                    grid.forceActiveFocus()
                                }
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
