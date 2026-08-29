import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../theme"
import "../components" as Components

Item {
    id: root

    property string targetScreenName: ""
    readonly property bool expanded: UiState.clipboardVisible
        && (UiState.clipboardScreen === "" || UiState.clipboardScreen === targetScreenName)
    readonly property int fullBodyHeight: 400
    property real expandedWidth: 380
    property real reveal: expanded ? 1 : 0
    property bool isDragging: false

    implicitWidth: expanded || reveal > 0 ? expandedWidth : Theme.compactPillSize
    implicitHeight: reveal > 0
        ? Theme.barHeight + Theme.outerGap + fullBodyHeight * reveal
        : Theme.barHeight
    focus: expanded

    Behavior on reveal {
        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easingDecelerate }
    }

    onExpandedChanged: {
        if (expanded) {
            clipboardFile.reload()
            root.clipboardEntries = parseClipboard(clipboardFile.text())
            listView.currentIndex = 0
            Qt.callLater(() => root.forceActiveFocus())
        } else {
            searchQuery = ""
            searchInput.text = ""
        }
    }

    // All keyboard handling lives on root — TextInput never steals focus
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Down) {
            if (listView.currentIndex < listView.count - 1) {
                listView.currentIndex++
                listView.positionViewAtIndex(listView.currentIndex, ListView.Contain)
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            if (listView.currentIndex > 0) {
                listView.currentIndex--
                listView.positionViewAtIndex(listView.currentIndex, ListView.Contain)
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (listView.currentIndex >= 0 && listView.currentIndex < root.filteredEntries.length) {
                root.activate(root.filteredEntries[listView.currentIndex])
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            UiState.clipboardVisible = false
            event.accepted = true
        } else if (event.key === Qt.Key_Backspace) {
            if (searchQuery.length > 0) {
                searchQuery = searchQuery.slice(0, -1)
                searchInput.text = searchQuery
                listView.currentIndex = 0
            }
            event.accepted = true
        } else if (event.text && event.text.length === 1 && event.text.charCodeAt(0) >= 32) {
            // Forward printable characters to search
            searchQuery += event.text
            searchInput.text = searchQuery
            listView.currentIndex = 0
            event.accepted = true
        }
    }

    FileView {
        id: clipboardFile
        path: Quickshell.env("HOME") + "/.config/clipse/clipboard_history.json"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            clipboardFile.reload()
            root.clipboardEntries = parseClipboard(clipboardFile.text())
        }
    }

    property var clipboardEntries: parseClipboard(clipboardFile.text())

    property string searchQuery: ""
    readonly property var filteredEntries: {
        const query = searchQuery.toLowerCase()
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
        if (entry.isImage) {
            Quickshell.execDetached(["bash", Quickshell.shellPath("scripts/copy-image.sh"), entry.filePath])
        } else {
            Quickshell.clipboardText = entry.value
        }
        UiState.clipboardVisible = false
    }

    Components.ConnectedDropdownSurface {
        anchors.fill: parent
        tabWidth: Theme.compactPillSize
        tabOnLeft: true
        visible: root.reveal > 0
    }

    Item {
        anchors.top: parent.top
        anchors.left: parent.left
        width: Theme.compactPillSize
        height: Theme.barHeight

        Text {
            anchors.centerIn: parent
            visible: root.reveal > 0
            text: "󰅌"
            color: Theme.purple
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Theme.fontWeight
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton
            onClicked: UiState.toggleClipboard("")
        }
    }

    Item {
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + Theme.outerGap
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: root.reveal > 0
        opacity: root.reveal
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Clipboard"
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 16
                    font.weight: Theme.fontWeight
                    color: Theme.fg
                    Layout.alignment: Qt.AlignVCenter
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 28
                    radius: 9
                    color: Theme.bgLight
                    border.color: searchQuery.length > 0 ? Theme.accent : Theme.bgDark
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            text: "󰍉"
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }

                        // Read-only display — root handles all keystrokes
                        Text {
                            id: searchInput
                            Layout.fillWidth: true
                            color: Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 12
                            text: root.searchQuery
                            elide: Text.ElideRight

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.searchQuery.length === 0
                                text: "Search…"
                                color: Theme.fgMuted
                                font: parent.font
                            }
                        }
                    }
                }

                Rectangle {
                    implicitWidth: clearLabel.implicitWidth + 16
                    implicitHeight: 28
                    radius: 9
                    color: clearHover.hovered ? Theme.surface : Theme.bgLight

                    Text {
                        id: clearLabel
                        anchors.centerIn: parent
                        text: "Clear"
                        color: Theme.accent
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 11
                    }

                    HoverHandler { id: clearHover }
                    TapHandler {
                        onTapped: {
                            Quickshell.execDetached(["clipse", "-clear"])
                            root.clipboardEntries = []
                        }
                    }
                }

                Rectangle {
                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 9
                    color: closeHover.hovered ? Theme.surface : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: Theme.fgMuted
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 18
                    }

                    HoverHandler { id: closeHover }
                    TapHandler { onTapped: UiState.clipboardVisible = false }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.surface
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                model: root.filteredEntries
                onCountChanged: {
                    if (currentIndex >= count)
                        currentIndex = Math.max(0, count - 1)
                }
                spacing: 10
                clip: true

                delegate: Rectangle {
                    id: expRow
                    width: listView.width
                    height: modelData.isImage ? 90 : 56
                    radius: Theme.radius - 2
                    color: itemMouse.containsMouse || ListView.isCurrentItem ? Theme.surface : Theme.bgLight
                    border.color: itemMouse.containsMouse || ListView.isCurrentItem ? Theme.accentGlow : Theme.bgDark
                    border.width: 1

                    Item {
                        id: expDragProxy
                        width: expRow.width
                        height: expRow.height
                        Drag.active: itemMouse.drag.active
                        Drag.dragType: Drag.Automatic
                        // Clipboard entries are copied, never moved. Advertising
                        // Move makes Qt propose it first, which causes copy-only
                        // targets such as editors and browsers to reject the drag.
                        Drag.supportedActions: Qt.CopyAction
                        Drag.proposedAction: Qt.CopyAction
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
                        anchors.margins: 12
                        spacing: 12

                        Text {
                            Layout.alignment: Qt.AlignTop
                            text: modelData.pinned ? "󰐃" : (modelData.isImage ? "󰋩" : "󰅍")
                            color: modelData.pinned ? Theme.yellow : Theme.purple
                            font.family: Theme.fontFamily
                            font.pixelSize: 18
                        }

                        Image {
                            visible: modelData.isImage
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredWidth: 90
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
                            spacing: 4

                            Text {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: modelData.label || "(Empty)"
                                color: Theme.fg
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 13
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                maximumLineCount: modelData.isImage ? 2 : 1
                                verticalAlignment: Qt.AlignVCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.timeAgo(modelData.recorded)
                                color: Theme.fgDim
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 11
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
                            root.isDragging = true
                            expRow.grabToImage(function(result) {
                                expDragProxy.Drag.imageSource = result.url;
                            }, Qt.size(160, 48));
                        }
                        onReleased: root.isDragging = false
                        onCanceled: root.isDragging = false
                        onClicked: root.activate(modelData)
                    }
                }

                Text {
                    visible: listView.count === 0
                    anchors.centerIn: parent
                    text: "󰅍\n\nClipboard empty"
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                }
            }
        }
    }
}
