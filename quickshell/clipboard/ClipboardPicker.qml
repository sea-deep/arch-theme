import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    WlrLayershell.namespace: "quickshell-clipboard"
    id: root
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"
    visible: UiState.clipboardVisible

    Shortcut {
        sequence: "Escape"
        enabled: UiState.clipboardVisible
        onActivated: UiState.clipboardVisible = false
    }

    property int cursorX: -1
    property int cursorY: -1
    property string searchQuery: ""
    property bool isDragging: false

    mask: Region {
        Region {
            x: 0
            y: 0
            width: root.width
            height: root.isDragging ? 0 : root.height
        }
        Region { item: popup }
    }

    FileView {
        id: clipboardFile
        path: Quickshell.env("HOME") + "/.config/clipse/clipboard_history.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }

    readonly property var clipboardEntries: parseClipboard(clipboardFile.text())

    readonly property var filteredEntries: {
        const query = searchQuery.trim().toLowerCase()
        if (query === "") return clipboardEntries
        return clipboardEntries.filter(e =>
            (e.label && e.label.toLowerCase().includes(query)) ||
            (e.value && e.value.toLowerCase().includes(query))
        )
    }

    function timeAgo(dateString) {
        if (!dateString) return ""
        const parts = dateString.split(".")[0].replace(" ", "T")
        const date = new Date(parts)
        const now = new Date()
        const diffSec = Math.floor((now - date) / 1000)

        if (diffSec < 60) return "just now"
        if (diffSec < 3600) return Math.floor(diffSec / 60) + "m ago"
        if (diffSec < 86400) return Math.floor(diffSec / 3600) + "h ago"
        return Math.floor(diffSec / 86400) + "d ago"
    }

    function parseClipboard(data) {
        if (!data) return []
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
        } catch (e) {
            return []
        }
    }

    function activate(entry) {
        if (!entry) return
        UiState.clipboardVisible = false
        Quickshell.execDetached([
            "bash",
            Quickshell.shellPath("scripts/paste-clipboard.sh"),
            entry.isImage ? "image" : "text",
            entry.isImage ? entry.filePath : entry.value
        ])
    }

    onVisibleChanged: {
        if (visible) {
            cursorX = -1
            cursorY = -1
            searchQuery = ""
            searchInput.text = ""
            clipboardFile.reload()
            listView.currentIndex = 0
            posProc.running = true
            Qt.callLater(function() { searchInput.forceActiveFocus() })
        }
    }

    // Click outside to close (backdrop)
    MouseArea {
        anchors.fill: parent
        enabled: !root.isDragging
        onClicked: UiState.clipboardVisible = false
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

        // Consume clicks so they don't hit the backdrop MouseArea
        TapHandler {}

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            // Header: Title + search bar + Clear button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

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

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: parent.text.length === 0
                                text: "Search clipboard…"
                                color: Theme.fgMuted
                                font: parent.font
                            }

                            onTextChanged: {
                                root.searchQuery = text
                                listView.currentIndex = 0
                                listView.positionViewAtBeginning()
                            }

                            Keys.onEscapePressed: UiState.clipboardVisible = false
                            Keys.onDownPressed: {
                                if (listView.count > 0) {
                                    listView.currentIndex = Math.min(listView.count - 1, listView.currentIndex + 1)
                                    listView.positionViewAtIndex(listView.currentIndex, ListView.Contain)
                                }
                            }
                            Keys.onUpPressed: {
                                if (listView.count > 0) {
                                    listView.currentIndex = Math.max(0, listView.currentIndex - 1)
                                    listView.positionViewAtIndex(listView.currentIndex, ListView.Contain)
                                }
                            }
                            Keys.onReturnPressed: {
                                if (root.filteredEntries.length > 0) {
                                    var idx = (listView.currentIndex >= 0 && listView.currentIndex < root.filteredEntries.length) ? listView.currentIndex : 0
                                    root.activate(root.filteredEntries[idx])
                                }
                            }
                            Keys.onEnterPressed: {
                                if (root.filteredEntries.length > 0) {
                                    var idx = (listView.currentIndex >= 0 && listView.currentIndex < root.filteredEntries.length) ? listView.currentIndex : 0
                                    root.activate(root.filteredEntries[idx])
                                }
                            }
                        }

                        // Clear search text button
                        Rectangle {
                            visible: searchInput.text.length > 0
                            width: 18
                            height: 18
                            radius: 9
                            color: clearTextTap.pressed ? Theme.surface : (clearTextHover.hovered ? Theme.surface : "transparent")

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }

                            HoverHandler {
                                id: clearTextHover
                                cursorShape: Qt.PointingHandCursor
                            }

                            TapHandler {
                                id: clearTextTap
                                onTapped: {
                                    searchInput.text = ""
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }
                    }
                }

                // Clear history button
                Rectangle {
                    implicitWidth: clearLabel.implicitWidth + 14
                    Layout.preferredHeight: 36
                    radius: 8
                    color: clearTap.pressed ? Theme.surface : (clearHover.hovered ? Theme.surface : Theme.bgLight)
                    border.color: Theme.surface
                    border.width: 1

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear"
                        color: Theme.accent
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 11
                        font.weight: Theme.fontWeight
                    }

                    HoverHandler {
                        id: clearHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        id: clearTap
                        onTapped: {
                            Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/clear-clipboard.sh")])
                            Quickshell.clipboardText = ""
                            searchInput.text = ""
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.surface
            }

            // Entries List
            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.filteredEntries
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds

                onCountChanged: {
                    if (currentIndex >= count)
                        currentIndex = Math.max(0, count - 1)
                }

                delegate: Rectangle {
                    id: expRow
                    property bool nativeDragStarted: false
                    width: listView.width
                    height: modelData.isImage ? 80 : 52
                    radius: 8

                    readonly property bool isCurrent: (listView.currentIndex === index)
                    color: isCurrent ? Theme.surface : (rowHover.containsMouse ? Theme.bgLight : "transparent")
                    border.color: isCurrent ? Theme.accent : (rowHover.containsMouse ? Theme.surface : "transparent")
                    border.width: 1

                    Item {
                        id: expDragProxy
                        width: expRow.width
                        height: expRow.height
                        Drag.active: itemMouse.drag.active
                        Drag.dragType: Drag.Automatic
                        Drag.supportedActions: Qt.CopyAction | Qt.MoveAction | Qt.LinkAction
                        Drag.proposedAction: Qt.CopyAction
                        Drag.onDragStarted: {
                            expRow.nativeDragStarted = true
                            root.isDragging = true
                        }
                        Drag.onDragFinished: {
                            expRow.nativeDragStarted = false
                            root.isDragging = false
                        }
                        Drag.hotSpot.x: 24
                        Drag.hotSpot.y: 24
                        Drag.imageSource: modelData.isImage ? ("file://" + modelData.filePath) : ""
                        Drag.mimeData: {
                            var data = {};
                            if (modelData.isImage) {
                                var uri = "file://" + modelData.filePath;
                                data["text/uri-list"] = uri + "\r\n";
                                data["x-special/gnome-copied-files"] = "copy\n" + uri + "\r\n";
                                data["text/plain"] = uri;
                                data["text/plain;charset=utf-8"] = uri;
                            } else {
                                var txt = String(modelData.value || modelData.label || "");
                                data["text/plain"] = txt;
                                data["text/plain;charset=utf-8"] = txt;
                                data["UTF8_STRING"] = txt;
                                data["STRING"] = txt;
                                data["TEXT"] = txt;
                            }
                            return data;
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Image {
                            visible: modelData.isImage
                            asynchronous: true
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 64
                            Layout.fillHeight: true
                            source: modelData.isImage ? "file://" + modelData.filePath : ""
                            fillMode: Image.PreserveAspectCrop

                            Rectangle {
                                anchors.fill: parent
                                color: "transparent"
                                border.color: Theme.bgDark
                                border.width: 1
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    visible: modelData.pinned
                                    text: "󰐃"
                                    color: Theme.yellow
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.label || "(Empty)"
                                    color: expRow.isCurrent ? Theme.fg : Theme.fgDim
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 12
                                    font.weight: Theme.fontWeight
                                    wrapMode: Text.Wrap
                                    elide: Text.ElideRight
                                    maximumLineCount: modelData.isImage ? 2 : 1
                                    verticalAlignment: Qt.AlignVCenter
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.timeAgo(modelData.recorded)
                                color: Theme.fgMuted
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 10
                                font.weight: Theme.fontWeight
                            }
                        }
                    }

                    MouseArea {
                        id: itemMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        preventStealing: true
                        drag.target: expDragProxy
                        cursorShape: Qt.PointingHandCursor
                        onPressed: {
                            expRow.nativeDragStarted = false
                            listView.currentIndex = index
                            expRow.grabToImage(function(result) {
                                expDragProxy.Drag.imageSource = result.url;
                            }, Qt.size(160, 48));
                        }
                        onReleased: {
                            if (!expRow.nativeDragStarted)
                                root.isDragging = false
                        }
                        onCanceled: {
                            if (!expRow.nativeDragStarted)
                                root.isDragging = false
                        }
                        onClicked: root.activate(modelData)
                    }

                    HoverHandler { id: rowHover }
                }
            }
        }

        // Empty state overlay
        ColumnLayout {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: 24
            visible: listView.count === 0
            spacing: 8

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "󰅍"
                color: Theme.fgMuted
                font.family: Theme.fontFamily
                font.pixelSize: 28
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.searchQuery.length > 0 ? "No matching items" : "Clipboard empty"
                color: Theme.fgDim
                font.family: Theme.fontFamilySans
                font.pixelSize: 13
                font.weight: Theme.fontWeight
            }
        }
    }
}
