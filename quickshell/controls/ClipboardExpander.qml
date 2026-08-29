import QtQuick.Controls
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

    implicitWidth: expanded || reveal > 0 ? expandedWidth : Theme.compactPillSize
    implicitHeight: reveal > 0
        ? Theme.barHeight + Theme.outerGap + fullBodyHeight * reveal
        : Theme.barHeight
    focus: expanded

    Behavior on reveal {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    visible: reveal > 0
    onExpandedChanged: { if (!expanded) searchQuery = "" }

    FileView {
        id: clipboardFile
        path: Quickshell.env("HOME") + "/.config/clipse/clipboard_history.json"
        watchChanges: true
        printErrors: false
    }

    readonly property var clipboardEntries: parseClipboard(clipboardFile.text())
    
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
                    border.color: searchInput.activeFocus ? Theme.accent : Theme.bgDark
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
                        
                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 12
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            selectByMouse: true
                            text: root.searchQuery
                            onTextChanged: root.searchQuery = text
                            
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                onClicked: searchInput.forceActiveFocus()
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
                spacing: 10
                clip: true
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                
                // Add a MouseArea to capture wheel events and force scroll if the native flickable ignores it
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    onWheel: (wheel) => {
                        if (wheel.angleDelta.y > 0)
                            listView.flick(0, 1500)
                        else
                            listView.flick(0, -1500)
                    }
                }
                
                ScrollBar.vertical: ScrollBar {
                    active: true
                    width: 4
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: Theme.fgDim
                    }
                }

                delegate: Rectangle {
                    width: listView.width
                    height: modelData.isImage ? 90 : 56
                    radius: Theme.radius - 2
                    color: itemHover.hovered ? Theme.surface : Theme.bgLight
                    border.color: itemHover.hovered ? Theme.accentGlow : Theme.bgDark
                    border.width: 1

                    HoverHandler { id: itemHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.activate(modelData) }

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
                }

                Text {
                    visible: listView.count === 0
                    anchors.centerIn: parent
                    text: "󰅍

Clipboard empty"
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                }
            }
        }
    }
}