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
            id: revealAnim
            duration: root.showing ? 160 : 100
            easing.type: root.showing ? Easing.OutBack : Easing.InQuad
            easing.overshoot: 1.05
            onFinished: {
                if (root.showing && !root.fullyLoaded) {
                    lazyTimer.restart()
                }
            }
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
    property bool fullyLoaded: false
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

    property var categorySections: []
    property var searchSections: []
    property string activeCatId: "Recent"

    FileView {
        id: recentEmojisFile
        path: Quickshell.env("HOME") + "/.config/quickshell/state/recent_emojis.json"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            if (root.searchQuery === "") {
                if (root.fullyLoaded) {
                    root.loadFullSections()
                } else {
                    root.loadInitialPage()
                }
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

    // Load only 1 page (up to 56 emojis) initially for 0ms unroll reveal
    function loadInitialPage() {
        var sections = []
        var recents = getRecentEmojis()
        var needed = 56
        if (recents.length > 0) {
            sections.push({
                name: "Recently Used",
                icon: "🕒",
                catId: "Recent",
                emojis: recents.map(function(c) { return { char: c, name: "recent" } })
            })
            needed -= recents.length
        }
        var smileys = EmojiData.categories["Smileys & Emotion"] || []
        var initSmileys = smileys.slice(0, Math.max(24, needed))
        sections.push({
            name: "Smileys & Emotion",
            icon: "😀",
            catId: "Smileys & Emotion",
            emojis: initSmileys
        })
        categorySections = sections
        activeCatId = recents.length > 0 ? "Recent" : "Smileys & Emotion"
        fullyLoaded = false
    }

    // Lazy load all 9 categories after reveal animation finishes or upon scroll/click
    function loadFullSections() {
        var sections = []
        var recents = getRecentEmojis()
        if (recents.length > 0) {
            sections.push({
                name: "Recently Used",
                icon: "🕒",
                catId: "Recent",
                emojis: recents.map(function(c) { return { char: c, name: "recent" } })
            })
        }
        for (var i = 0; i < standardCategories.length; i++) {
            var cat = standardCategories[i]
            sections.push({
                name: cat.name,
                icon: cat.icon,
                catId: cat.name,
                emojis: EmojiData.categories[cat.name] || []
            })
        }
        categorySections = sections
        fullyLoaded = true
    }

    function filterEmojis(query) {
        if (query === "") {
            searchSections = []
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
                            name: e.name
                        })
                    }
                }
            }
        }
        searchSections = [{
            name: "Search Results (" + result.length + ")",
            icon: "󰍉",
            catId: "search",
            emojis: result
        }]
    }

    function selectEmoji(emoji) {
        recordRecentEmoji(emoji)
        UiState.emojiVisible = false
        Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/type-emoji.sh"), emoji])
    }

    Timer {
        id: lazyTimer
        interval: 30
        repeat: false
        onTriggered: {
            if (root.showing && !root.fullyLoaded) {
                root.loadFullSections()
            }
        }
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
        loadInitialPage()
    }

    onShowingChanged: {
        if (showing) {
            cursorQuery.running = true
            searchQuery = ""
            searchInput.text = ""
            loadInitialPage()
            emojiList.positionViewAtBeginning()
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
        height: fullHeight
        opacity: root.reveal
        scale: 0.95 + (0.05 * root.reveal)
        transformOrigin: Item.Center
        clip: true
        x: root.cursorX >= 0 ? root.cursorX : (root.width - width) / 2
        y: root.cursorY >= 0 ? root.cursorY : (root.height - fullHeight) / 2
        visible: root.reveal > 0

        color: Theme.bg
        radius: Theme.radiusLarge
        border.color: Theme.accentGlow
        border.width: Theme.borderWidth

        // Consume clicks so they don't hit the backdrop MouseArea
        TapHandler {}

        Item {
            anchors.top: parent.top
            anchors.left: parent.left
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
                                emojiList.positionViewAtBeginning()
                            }
                            onAccepted: {
                                if (root.searchSections.length > 0 && root.searchSections[0].emojis.length > 0) {
                                    root.selectEmoji(root.searchSections[0].emojis[0].char)
                                }
                            }
                            Keys.onEscapePressed: UiState.emojiVisible = false
                        }
                    }
                }

                // Continuous Scrollable Emoji List with Category Headers & Separators
                ListView {
                    id: emojiList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 100
                    clip: true
                    spacing: 12
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.searchQuery === "" ? root.categorySections : root.searchSections

                    onContentYChanged: {
                        if (!root.isClickScrolling && root.searchQuery === "") {
                            if (!root.fullyLoaded && contentY > 30) {
                                root.loadFullSections()
                            }
                            var idx = emojiList.indexAt(10, emojiList.contentY + 30)
                            if (idx >= 0 && idx < root.categorySections.length) {
                                root.activeCatId = root.categorySections[idx].catId
                            }
                        }
                    }

                    delegate: ColumnLayout {
                        id: secDelegate
                        required property var modelData
                        required property int index

                        width: emojiList.width
                        spacing: 6

                        // Category Section Header & Separator Line
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: index === 0 ? 0 : 6
                            Layout.bottomMargin: 2
                            spacing: 8

                            Text {
                                text: secDelegate.modelData.name
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

                        // Grid of Emojis for this Category
                        Flow {
                            Layout.fillWidth: true
                            spacing: 0

                            Repeater {
                                model: secDelegate.modelData.emojis
                                Rectangle {
                                    required property var modelData
                                    required property int index

                                    width: 39.5
                                    height: 39.5
                                    radius: 8
                                    color: emMouse.containsMouse ? Theme.bgLight : "transparent"

                                    MouseArea {
                                        id: emMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.selectEmoji(modelData.char)
                                        }
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

                    // Empty Search Placeholder
                    Text {
                        visible: root.searchQuery !== "" && (root.searchSections.length === 0 || root.searchSections[0].emojis.length === 0)
                        anchors.centerIn: parent
                        text: "No matching emojis"
                        color: Theme.fgDim
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 13
                    }
                }

                // Category separator line
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.surface
                    visible: root.searchQuery === ""
                }

                // Fixed 10 Category tabs with glowing indicator over active category
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
                                    if (!root.fullyLoaded) {
                                        root.loadFullSections()
                                    }
                                    root.isClickScrolling = true
                                    root.activeCatId = modelData.catId

                                    var targetIndex = 0
                                    for (var s = 0; s < root.categorySections.length; s++) {
                                        if (root.categorySections[s].catId === modelData.catId) {
                                            targetIndex = s
                                            break
                                        }
                                    }
                                    emojiList.positionViewAtIndex(targetIndex, ListView.Beginning)
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
