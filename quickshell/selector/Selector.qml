import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"

PanelWindow {
    id: root

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    // Leave the native bar outside this overlay so its launcher/clipboard/tray
    // buttons remain true toggles while the selector is open.
    margins.top: 34 + 2 * 2
    color: Qt.rgba(21 / 255, 22 / 255, 30 / 255, 0.62)
    visible: UiState.selectorVisible

    WlrLayershell.namespace: "quickshell-selector"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    mask: Region {
        item: panel
    }

    property var emojis: []

    readonly property string mode: UiState.selectorMode
    readonly property string query: searchInput.text.trim().toLowerCase()
    readonly property var clipboardEntries: parseClipboard(clipboardFile.text())
    readonly property var entries: filteredEntries()

    function parseEmojiData(data) {
        const rows = data.split("\n")
        const result = []

        for (let i = 0; i < rows.length; ++i) {
            const row = rows[i].trim()
            const separator = row.indexOf(" ")
            if (separator <= 0)
                continue

            result.push({
                symbol: row.slice(0, separator),
                name: row.slice(separator + 1)
            })
        }

        return result
    }

    function parseClipboard(data) {
        if (!data)
            return []

        try {
            const parsed = JSON.parse(data)
            const history = parsed.clipboardHistory || []
            const result = []

            for (let i = 0; i < history.length; ++i) {
                const entry = history[i]
                const rawValue = String(entry.value || "")
                const isImage = entry.filePath && entry.filePath !== "null"
                const compact = rawValue.replace(/\s+/g, " ").trim()

                result.push({
                    value: rawValue,
                    label: isImage ? compact : compact.slice(0, 180),
                    recorded: entry.recorded || "",
                    filePath: isImage ? entry.filePath : "",
                    pinned: entry.pinned === true,
                    isImage: isImage
                })
            }

            return result
        } catch (error) {
            console.warn("Unable to parse Clipse history:", error)
            return []
        }
    }

    function filteredEntries() {
        const needle = root.query

        if (root.mode === "apps") {
            return DesktopEntries.applications.values.filter(function(entry) {
                if (entry.noDisplay)
                    return false

                if (needle === "")
                    return true

                return (entry.name || "").toLowerCase().includes(needle)
                    || (entry.comment || "").toLowerCase().includes(needle)
                    || (entry.genericName || "").toLowerCase().includes(needle)
                    || (entry.keywords || []).join(" ").toLowerCase().includes(needle)
            }).slice(0, 120)
        }

        if (root.mode === "emoji") {
            return root.emojis.filter(function(entry) {
                return needle === "" || entry.name.toLowerCase().includes(needle)
                    || entry.symbol.includes(needle)
            }).slice(0, 160)
        }

        return root.clipboardEntries.filter(function(entry) {
            return needle === "" || entry.label.toLowerCase().includes(needle)
        }).slice(0, 100)
    }

    function activate(entry) {
        if (!entry)
            return

        if (root.mode === "apps") {
            entry.execute()
        } else if (root.mode === "emoji") {
            Quickshell.clipboardText = entry.symbol
        } else if (entry.isImage) {
            Quickshell.execDetached([
                "bash",
                Quickshell.shellPath("scripts/copy-image.sh"),
                entry.filePath
            ])
        } else {
            Quickshell.clipboardText = entry.value
        }

        UiState.selectorVisible = false
    }

    function modeTitle() {
        if (root.mode === "emoji")
            return "Emoji"
        if (root.mode === "clipboard")
            return "Clipboard"
        return "Applications"
    }

    function modeIcon() {
        if (root.mode === "emoji")
            return "󰞅"
        if (root.mode === "clipboard")
            return "󰅌"
        return "󰀻"
    }

    function resetSelection() {
        const count = entries ? entries.length : 0
        resultList.currentIndex = root.mode === "emoji" ? -1 : (count > 0 ? 0 : -1)
        emojiGrid.currentIndex = root.mode === "emoji" && count > 0 ? 0 : -1
    }

    function activeEntry() {
        const view = root.mode === "emoji" ? emojiGrid : resultList
        return view.currentItem ? view.currentItem.modelData : null
    }

    onModeChanged: {
        searchInput.text = ""
        resetSelection()
        if (mode === "emoji" && emojis.length === 0)
            emojiLoader.running = true
    }

    onEntriesChanged: resetSelection()
    onVisibleChanged: if (visible) Qt.callLater(() => searchInput.forceActiveFocus())

    Component.onCompleted: {
        searchInput.forceActiveFocus()
        if (mode === "emoji")
            emojiLoader.running = true
    }

    Shortcut {
        sequence: "Escape"
        onActivated: UiState.selectorVisible = false
    }

    Process {
        id: emojiLoader
        command: ["bash", Quickshell.shellPath("scripts/emoji-data.sh")]
        stdout: StdioCollector {
            onStreamFinished: root.emojis = root.parseEmojiData(text)
        }
    }

    FileView {
        id: clipboardFile
        path: Quickshell.env("HOME") + "/.config/clipse/clipboard_history.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    TapHandler {
        onTapped: UiState.selectorVisible = false
    }

    Rectangle {
        id: panel
        width: Math.min(680, root.width - 48)
        height: Math.min(620, root.height - 96)
        anchors.centerIn: parent
        color: Theme.bg
        radius: 16
        border.width: 2
        border.color: Theme.bgDark

        TapHandler {}

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.modeIcon() + "  " + root.modeTitle()
                    color: Theme.fg
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.weight: Theme.fontWeight
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.mode === "apps" ? "Super+D  ·  Esc"
                        : (root.mode === "emoji" ? "Super+.  ·  Esc" : "Super+V  ·  Esc")
                    color: Theme.fgMuted
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 46
                radius: 10
                color: Theme.bgLight
                border.width: searchInput.activeFocus ? 2 : 0
                border.color: Theme.accent

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    Text {
                        text: root.modeIcon()
                        color: Theme.purple
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        color: Theme.fg
                        selectionColor: Theme.accent
                        selectedTextColor: Theme.bgDark
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 16
                        verticalAlignment: TextInput.AlignVCenter

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Search " + root.modeTitle().toLowerCase() + "…"
                            color: Theme.fgMuted
                            font: parent.font
                            visible: parent.text.length === 0
                        }

                        Keys.onEscapePressed: UiState.selectorVisible = false
                        Keys.onDownPressed: {
                            if (root.mode === "emoji")
                                emojiGrid.currentIndex = Math.min(emojiGrid.count - 1, emojiGrid.currentIndex + emojiGrid.columns)
                            else
                                resultList.currentIndex = Math.min(resultList.count - 1, resultList.currentIndex + 1)
                        }
                        Keys.onUpPressed: {
                            if (root.mode === "emoji")
                                emojiGrid.currentIndex = Math.max(0, emojiGrid.currentIndex - emojiGrid.columns)
                            else
                                resultList.currentIndex = Math.max(0, resultList.currentIndex - 1)
                        }
                        Keys.onLeftPressed: if (root.mode === "emoji") emojiGrid.currentIndex = Math.max(0, emojiGrid.currentIndex - 1)
                        Keys.onRightPressed: if (root.mode === "emoji") emojiGrid.currentIndex = Math.min(emojiGrid.count - 1, emojiGrid.currentIndex + 1)
                        Keys.onReturnPressed: root.activate(root.activeEntry())
                        Keys.onEnterPressed: root.activate(root.activeEntry())
                    }
                }
            }

            ListView {
                id: resultList
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.mode === "emoji" ? [] : root.entries
                visible: root.mode !== "emoji"
                clip: true
                spacing: 4
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: resultRow
                    required property var modelData
                    readonly property bool selected: ListView.isCurrentItem
                    width: ListView.view.width
                    height: 58
                    radius: 10
                    color: selected ? Theme.accent : (rowMouse.containsMouse ? Theme.bgLight : "transparent")

                    Item {
                        id: dragProxy
                        width: resultRow.width
                        height: resultRow.height
                        Drag.active: rowMouse.drag.active
                        Drag.dragType: Drag.Automatic
                        Drag.supportedActions: Qt.CopyAction | Qt.MoveAction | Qt.LinkAction
                        Drag.hotSpot.x: 24
                        Drag.hotSpot.y: 24
                        Drag.imageSource: (root.mode === "clipboard" && resultRow.modelData.isImage)
                            ? ("file://" + resultRow.modelData.filePath)
                            : ""
                        Drag.mimeData: {
                            var data = {};
                            if (root.mode === "clipboard") {
                                if (resultRow.modelData.isImage) {
                                    var uri = "file://" + resultRow.modelData.filePath;
                                    data["text/uri-list"] = uri + "\r\n";
                                    data["x-special/gnome-copied-files"] = "copy\n" + uri + "\r\n";
                                    data["text/plain"] = uri;
                                    data["text/plain;charset=utf-8"] = uri;
                                } else {
                                    var txt = resultRow.modelData.value || resultRow.modelData.label || "";
                                    data["text/plain"] = txt;
                                    data["text/plain;charset=utf-8"] = txt;
                                    data["UTF8_STRING"] = txt;
                                }
                            } else if (root.mode === "emoji") {
                                var sym = resultRow.modelData.symbol || "";
                                data["text/plain"] = sym;
                                data["text/plain;charset=utf-8"] = sym;
                                data["UTF8_STRING"] = sym;
                            }
                            return data;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 12

                        Item {
                            implicitWidth: 38
                            implicitHeight: 38

                            IconImage {
                                anchors.fill: parent
                                source: root.mode === "apps"
                                    ? Quickshell.iconPath(resultRow.modelData.icon || "", "application-x-executable")
                                    : ""
                                visible: root.mode === "apps"
                            }

                            Image {
                                anchors.fill: parent
                                source: root.mode === "clipboard" && resultRow.modelData.isImage
                                    ? "file://" + resultRow.modelData.filePath
                                    : ""
                                fillMode: Image.PreserveAspectCrop
                                visible: source !== ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.mode === "emoji"
                                    ? resultRow.modelData.symbol
                                    : (root.mode === "clipboard" && !resultRow.modelData.isImage ? "󰅍" : "")
                                color: resultRow.selected ? Theme.bgDark : Theme.purple
                                font.family: root.mode === "emoji" ? Theme.fontFamilySans : Theme.fontFamily
                                font.pixelSize: root.mode === "emoji" ? 26 : 20
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: root.mode === "apps"
                                    ? (resultRow.modelData.name || "")
                                    : (root.mode === "emoji" ? resultRow.modelData.name : resultRow.modelData.label)
                                color: resultRow.selected ? Theme.bgDark : Theme.fg
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 15
                                font.weight: Theme.fontWeight
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.mode === "apps"
                                    ? (resultRow.modelData.comment || resultRow.modelData.genericName || "")
                                    : (root.mode === "clipboard" ? resultRow.modelData.recorded : resultRow.modelData.symbol)
                                color: resultRow.selected ? Theme.bgDark : Theme.fgDim
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                visible: text !== ""
                            }
                        }

                        Text {
                            text: root.mode === "clipboard" && resultRow.modelData.pinned ? "󰐃" : ""
                            color: resultRow.selected ? Theme.bgDark : Theme.yellow
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        preventStealing: true
                        drag.target: dragProxy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(resultRow.modelData)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "No matches"
                    color: Theme.fgMuted
                    font.family: Theme.fontFamilySans
                    visible: resultList.count === 0
                }
            }

            GridView {
                id: emojiGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.mode === "emoji"
                model: root.mode === "emoji" ? root.entries : []
                clip: true
                cellWidth: width / columns
                cellHeight: 86
                readonly property int columns: Math.max(1, Math.floor(width / 88))
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                    id: emojiCell
                    required property var modelData
                    readonly property bool selected: GridView.isCurrentItem
                    width: emojiGrid.cellWidth - 4
                    height: emojiGrid.cellHeight - 4
                    radius: 11
                    color: selected ? Theme.accent : (emojiMouse.containsMouse ? Theme.bgLight : "transparent")

                    Item {
                        id: emojiDragProxy
                        width: emojiCell.width
                        height: emojiCell.height
                        Drag.active: emojiMouse.drag.active
                        Drag.dragType: Drag.Automatic
                        Drag.supportedActions: Qt.CopyAction
                        Drag.mimeData: {
                            return { "text/plain": emojiCell.modelData.symbol || "" };
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 2

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: emojiCell.modelData.symbol
                            color: emojiCell.selected ? Theme.bgDark : Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 30
                        }

                        Text {
                            Layout.fillWidth: true
                            text: emojiCell.modelData.name
                            color: emojiCell.selected ? Theme.bgDark : Theme.fgDim
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        id: emojiMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        preventStealing: true
                        drag.target: emojiDragProxy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activate(emojiCell.modelData)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: emojiLoader.running ? "Loading emoji…" : "No matches"
                    color: Theme.fgMuted
                    font.family: Theme.fontFamilySans
                    visible: emojiGrid.count === 0
                }
            }

            Text {
                Layout.fillWidth: true
                text: (root.entries ? root.entries.length : 0) + " results  ·  arrows navigate  ·  Enter select"
                horizontalAlignment: Text.AlignHCenter
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
    }
}
