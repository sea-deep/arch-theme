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

    FileView {
        id: clipboardFile
        path: Quickshell.env("HOME") + "/.config/clipse/clipboard_history.json"
        watchChanges: true
        printErrors: false
    }

    readonly property var clipboardEntries: parseClipboard(clipboardFile.text())

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

    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + Theme.outerGap
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.fullBodyHeight * root.reveal
        color: Theme.bg
        radius: Theme.radius
        border.color: Theme.bgDark
        border.width: Theme.borderWidth
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "󰅌"
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                    color: Theme.purple
                    Layout.alignment: Qt.AlignVCenter
                }

                Text {
                    text: "Clipboard"
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 16
                    font.weight: Theme.fontWeight
                    color: Theme.fg
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
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
                model: root.clipboardEntries
                spacing: 6
                clip: true

                delegate: Rectangle {
                    width: listView.width
                    height: 50
                    radius: Theme.radius - 2
                    color: itemHover.hovered ? Theme.surface : Theme.bgLight
                    border.color: itemHover.hovered ? Theme.accentGlow : Theme.bgDark
                    border.width: 1

                    HoverHandler { id: itemHover }
                    TapHandler { onTapped: root.activate(modelData) }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Text {
                            text: modelData.pinned ? "󰐃" : (modelData.isImage ? "󰋩" : "󰅍")
                            color: modelData.pinned ? Theme.yellow : Theme.purple
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                        }

                        Text {
                            Layout.fillWidth: true
                            text: modelData.label || "(Empty)"
                            color: Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        Text {
                            text: modelData.recorded
                            color: Theme.fgDim
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 11
                        }
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
