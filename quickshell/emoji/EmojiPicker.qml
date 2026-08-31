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
    property bool isClickScrolling: false

    readonly property var categoryTabList: [
        { name: "Recently Used", catId: "Recent", icon: "🕒" },
        { name: "Smileys & Emotion", catId: "Smileys & Emotion", icon: "😀" },
        { name: "People & Body", catId: "People & Body", icon: "👋" },
        { name: "Animals & Nature", catId: "Animals & Nature", icon: "🐻" },
        { name: "Food & Drink", catId: "Food & Drink", icon: "🍔" },
        { name: "Travel & Places", catId: "Travel & Places", icon: "🚗" },
        { name: "Activities", catId: "Activities", icon: "⚽" },
        { name: "Objects", catId: "Objects", icon: "💡" },
        { name: "Symbols", catId: "Symbols", icon: "💖" },
        { name: "Flags", catId: "Flags", icon: "🚩" }
    ]

    readonly property var standardCategories: [
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

    property var emojiFlatModel: []
    property var categoryIndexMap: ({})
    property string activeCatId: "Recent"

    FileView {
        id: recentEmojisFile
        path: Quickshell.env("HOME") + "/.config/quickshell/state/recent_emojis.json"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            if (root.searchQuery === "") {
                root.refreshModel()
            }
        }
    }

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

    function refreshModel() {
        var recents = getRecentEmojis()
        var flatItems = []
        var indexMap = {}

        if (searchQuery && searchQuery.trim() !== "") {
            var q = searchQuery.trim().toLowerCase()
            var matched = []
            var seen = {}
            for (var cat in EmojiData.categories) {
                var list = EmojiData.categories[cat] || []
                for (var i = 0; i < list.length; i++) {
                    var e = list[i]
                    if (!seen[e.char]) {
                        var match = e.name.toLowerCase().indexOf(q) !== -1
                        if (!match && e.tags) {
                            for (var t = 0; t < e.tags.length; t++) {
                                if (e.tags[t].toLowerCase().indexOf(q) !== -1) {
                                    match = true
                                    break
                                }
                            }
                        }
                        if (match) {
                            seen[e.char] = true
                            matched.push(e)
                        }
                    }
                }
            }
            if (matched.length > 0) {
                flatItems.push({ isHeader: true, name: "Search Results (" + matched.length + ")", catId: "Search" })
                for (var i = 0; i < matched.length; i += 8) {
                    flatItems.push({ isHeader: false, rowEmojis: matched.slice(i, i + 8), catId: "Search" })
                }
            }
            root.emojiFlatModel = flatItems
            return
        }

        if (recents && recents.length > 0) {
            indexMap["Recent"] = flatItems.length
            flatItems.push({ isHeader: true, name: "Recently Used", catId: "Recent" })
            var recObjs = recents.map(function(c) { return { char: c, name: "recent" } })
            for (var i = 0; i < recObjs.length; i += 8) {
                flatItems.push({ isHeader: false, rowEmojis: recObjs.slice(i, i + 8), catId: "Recent" })
            }
        }

        for (var c = 0; c < standardCategories.length; c++) {
            var catName = standardCategories[c].name
            var emList = EmojiData.categories[catName] || []
            if (emList.length > 0) {
                indexMap[catName] = flatItems.length
                flatItems.push({ isHeader: true, name: catName, catId: catName })
                for (var i = 0; i < emList.length; i += 8) {
                    flatItems.push({ isHeader: false, rowEmojis: emList.slice(i, i + 8), catId: catName })
                }
            }
        }

        root.categoryIndexMap = indexMap
        root.emojiFlatModel = flatItems
        if (root.activeCatId === "Recent" && (!recents || recents.length === 0)) {
            root.activeCatId = "Smileys & Emotion"
        }
    }

    function selectEmoji(emoji) {
        recordRecentEmoji(emoji)
        UiState.emojiVisible = false
        Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/type-emoji.sh"), emoji])
    }

    Timer {
        id: scrollResetTimer
        interval: 220
        repeat: false
        onTriggered: root.isClickScrolling = false
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
        refreshModel()
    }

    onShowingChanged: {
        if (showing) {
            cursorQuery.running = true
            searchQuery = ""
            searchInput.text = ""
            refreshModel()
            emojiList.positionViewAtBeginning()
            searchInput.forceActiveFocus()
        }
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.showing
        onClicked: UiState.emojiVisible = false
    }

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
        radius: Theme.radiusLarge
        border.color: Theme.accentGlow
        border.width: Theme.borderWidth

        Item {
            anchors.fill: parent
            anchors.margins: Theme.borderWidth
            clip: true
            opacity: Math.min(1.0, Math.max(0.0, (root.reveal - 0.08) / 0.92))

            Item {
                anchors.top: parent.top
                anchors.left: parent.left
                width: parent.width
                height: popup.fullHeight - (Theme.borderWidth * 2)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        color: Theme.bgLight
                        radius: Theme.radiusSmall
                        border.color: searchInput.activeFocus ? Theme.accent : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Text {
                                text: ""
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                color: Theme.fg
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 13
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                selectByMouse: true
                                selectionColor: Theme.accent
                                selectedTextColor: Theme.bg

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: parent.text.length === 0
                                    text: "Search emojis…"
                                    color: Theme.fgMuted
                                    font: parent.font
                                }

                                onTextChanged: {
                                    root.searchQuery = text.toLowerCase()
                                    root.refreshModel()
                                    emojiList.positionViewAtBeginning()
                                }

                                onAccepted: {
                                    if (root.emojiFlatModel.length > 1 && !root.emojiFlatModel[1].isHeader) {
                                        var firstRow = root.emojiFlatModel[1].rowEmojis
                                        if (firstRow && firstRow.length > 0) {
                                            root.selectEmoji(firstRow[0].char)
                                        }
                                    }
                                }

                                Keys.onEscapePressed: UiState.emojiVisible = false
                            }

                            Text {
                                visible: searchInput.text !== ""
                                text: ""
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        searchInput.text = ""
                                        searchInput.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }

                    ListView {
                        id: emojiList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 2
                        boundsBehavior: Flickable.StopAtBounds
                        model: root.emojiFlatModel

                        onContentYChanged: {
                            if (!root.isClickScrolling && root.searchQuery === "" && emojiList.model && emojiList.model.length > 0) {
                                var idx = emojiList.indexAt(10, emojiList.contentY + 24)
                                if (idx >= 0 && idx < emojiList.model.length) {
                                    var item = emojiList.model[idx]
                                    if (item && item.catId && root.activeCatId !== item.catId) {
                                        root.activeCatId = item.catId
                                    }
                                }
                            }
                        }

                        delegate: Item {
                            id: rowItem
                            required property var modelData
                            required property int index

                            width: emojiList.width
                            height: modelData.isHeader ? 28 : 39.5

                            RowLayout {
                                visible: rowItem.modelData.isHeader
                                anchors.fill: parent
                                anchors.topMargin: rowItem.index === 0 ? 0 : 6
                                anchors.bottomMargin: 2
                                spacing: 8

                                Text {
                                    text: rowItem.modelData.name || ""
                                    color: Theme.accent
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 11
                                    font.weight: Theme.fontWeight
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: Theme.surface
                                }
                            }

                            Row {
                                visible: !rowItem.modelData.isHeader
                                anchors.fill: parent
                                spacing: 0

                                Repeater {
                                    model: rowItem.modelData.rowEmojis || []

                                    Rectangle {
                                        required property var modelData
                                        required property int index

                                        width: 39.5
                                        height: 39.5
                                        radius: Theme.radiusSmall
                                        color: emMouse.containsMouse ? Theme.bgLight : "transparent"

                                        Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                                        MouseArea {
                                            id: emMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectEmoji(modelData.char)
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.char
                                            font.pixelSize: 22
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            visible: root.searchQuery !== "" && root.emojiFlatModel.length === 0
                            anchors.centerIn: parent
                            text: "No matching emojis"
                            color: Theme.fgDim
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 13
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.surface
                        visible: root.searchQuery === ""
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        spacing: 2
                        visible: root.searchQuery === ""

                        Repeater {
                            model: root.categoryTabList
                            Rectangle {
                                required property var modelData
                                required property int index

                                readonly property bool isActive: (root.activeCatId === modelData.catId)

                                Layout.fillWidth: true
                                Layout.preferredHeight: 26
                                radius: Theme.radiusSmall
                                color: isActive ? Theme.accent : (catMouseArea.containsMouse ? Theme.bgLight : "transparent")
                                border.color: isActive ? Theme.accent : "transparent"
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                                Behavior on border.color { ColorAnimation { duration: Theme.durationFast } }

                                MouseArea {
                                    id: catMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.isClickScrolling = true
                                        root.activeCatId = modelData.catId
                                        var targetIdx = root.categoryIndexMap[modelData.catId]
                                        if (targetIdx !== undefined) {
                                            emojiList.positionViewAtIndex(targetIdx, ListView.Beginning)
                                        }
                                        scrollResetTimer.restart()
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
}
