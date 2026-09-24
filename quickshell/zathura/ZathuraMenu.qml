import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: root
    WlrLayershell.namespace: "quickshell-zathura-menu"
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: root.showing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    color: "transparent"
    property bool showing: UiState.zathuraMenuVisible
    property bool positioned: false
    property real reveal: (showing && positioned) ? 1 : 0

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
        onActivated: UiState.zathuraMenuVisible = false
    }

    property int cursorX: -1
    property int cursorY: -1
    property int selectedIndex: 0

    mask: Region {
        Region {
            x: 0
            y: 0
            width: root.width
            height: root.showing ? root.height : 0
        }
        Region { item: popup }
    }

    readonly property var menuItems: [
        { name: "Toggle Dark Mode", icon: "󰌵", key: "d", action: "recolor" },
        { name: "Open Document...", icon: "󰈔", key: "Ctrl+O", action: "open" },
        { name: "Table of Contents", icon: "󰂺", key: "Tab", action: "table_of_contents" },
        { name: "Find in Document", icon: "󰍉", key: "Ctrl+F", action: "search" },
        { name: "Two-Page (Book) View", icon: "󰘚", key: "Shift+D", action: "two_page" },
        { name: "Fit Page to Width", icon: "󰤄", key: "w", action: "fit_width" },
        { name: "Fit Whole Page", icon: "󰊓", key: "f", action: "fit_page" },
        { name: "Zoom In", icon: "󰐕", key: "+", action: "zoom_in" },
        { name: "Zoom Out", icon: "󰍴", key: "-", action: "zoom_out" },
        { name: "Reset Zoom (100%)", icon: "󰁨", key: "0", action: "zoom_100" },
        { name: "Rotate Clockwise", icon: "󰑕", key: "r", action: "rotate_cw" },
        { name: "Rotate Counter-CW", icon: "󰑖", key: "R", action: "rotate_ccw" },
        { name: "Reload Document", icon: "󰑐", key: "F5", action: "reload" },
        { name: "Print Document", icon: "󰐪", key: "Ctrl+P", action: "print" },
        { name: "Copy File Path", icon: "󰅍", key: "y", action: "copy_path" },
        { name: "Toggle Fullscreen", icon: "󰍹", key: "F11", action: "fullscreen" },
        { name: "Quit Zathura", icon: "󰅖", key: "q", action: "quit" }
    ]

    function executeItem(item) {
        if (!item) return
        root.positioned = false
        UiState.zathuraMenuVisible = false
        Quickshell.execDetached([
            "bash",
            Quickshell.shellPath("scripts/zathura-action.sh"),
            item.action
        ])
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
                root.positioned = true
            }
        }
    }

    Timer {
        interval: 80
        running: root.showing && !root.positioned
        onTriggered: {
            if (root.showing && !root.positioned) {
                root.positioned = true
            }
        }
    }

    function updateCoordinates(cx, cy) {
        var screenW = (root.screen && root.screen.width > 0) ? root.screen.width : (root.width > 0 ? root.width : 1600)
        var screenH = (root.screen && root.screen.height > 0) ? root.screen.height : (root.height > 0 ? root.height : 900)
        var popupW = popup.fullWidth
        var popupH = popup.fullHeight

        // Pop near cursor: default opens right and down from cursor
        var targetX = cx + 4
        if (targetX + popupW > screenW - 12) {
            targetX = cx - popupW - 4
        }
        if (targetX < 12) targetX = 12

        var targetY = cy + 4
        if (targetY + popupH > screenH - 12) {
            targetY = cy - popupH - 4
        }
        if (targetY < 12) targetY = 12

        root.cursorX = targetX
        root.cursorY = targetY
    }

    onShowingChanged: {
        if (showing) {
            root.selectedIndex = 0
            root.positioned = false
            cursorQuery.running = true
            keyGrabber.forceActiveFocus()
        } else {
            root.positioned = false
        }
    }

    // Direct child 1: Dismiss shield MouseArea (z: 0)
    MouseArea {
        z: 0
        anchors.fill: parent
        enabled: root.showing
        cursorShape: Qt.ArrowCursor
        onClicked: UiState.zathuraMenuVisible = false
    }

    Item {
        id: keyGrabber
        focus: true
        Keys.onEscapePressed: UiState.zathuraMenuVisible = false
        Keys.onDownPressed: {
            root.selectedIndex = (root.selectedIndex + 1) % root.menuItems.length
            menuList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
        }
        Keys.onUpPressed: {
            root.selectedIndex = (root.selectedIndex - 1 + root.menuItems.length) % root.menuItems.length
            menuList.positionViewAtIndex(root.selectedIndex, ListView.Contain)
        }
        Keys.onReturnPressed: {
            if (root.selectedIndex >= 0 && root.selectedIndex < root.menuItems.length) {
                root.executeItem(root.menuItems[root.selectedIndex])
            }
        }
        Keys.onEnterPressed: {
            if (root.selectedIndex >= 0 && root.selectedIndex < root.menuItems.length) {
                root.executeItem(root.menuItems[root.selectedIndex])
            }
        }
    }

    // Direct child 2: Popup container (z: 1, stacked above shield)
    Rectangle {
        id: popup
        z: 1
        readonly property int fullHeight: Math.min(524, ((root.screen && root.screen.height > 0) ? root.screen.height : (root.height > 0 ? root.height : 900)) - 32)
        readonly property int fullWidth: 280

        x: root.cursorX >= 0 ? root.cursorX : 12
        y: root.cursorY >= 0 ? root.cursorY : 12
        width: fullWidth
        height: fullHeight * root.reveal
        clip: true
        visible: height > 0

        color: Theme.bg
        radius: Theme.radiusLarge
        border.color: Theme.accentGlow
        border.width: Theme.borderWidth

        // Zero pixel overflow containment wrapper
        Item {
            anchors.fill: parent
            anchors.margins: Theme.borderWidth
            clip: true
            opacity: Math.min(1.0, Math.max(0.0, (root.reveal - 0.08) / 0.92))

            // Inner content anchored to top
            Item {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: popup.fullHeight

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    // Header row
                    RowLayout {
                        id: headerRow
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        Layout.rightMargin: 6
                        Layout.topMargin: 2
                        Layout.bottomMargin: 2
                        spacing: 8

                        Text {
                            text: "󰈙"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }

                        Text {
                            Layout.fillWidth: true
                            text: "Document Controls"
                            color: Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 12
                            font.weight: Font.Bold
                        }

                        Text {
                            text: "󰅖"
                            color: closeHeaderHover.hovered ? Theme.red : Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 13

                            HoverHandler { id: closeHeaderHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: UiState.zathuraMenuVisible = false }
                        }
                    }

                    // Separator line
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.surfaceVariant
                    }

                    // Action items list
                    ListView {
                        id: menuList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        spacing: 2
                        model: root.menuItems
                        currentIndex: root.selectedIndex

                        delegate: Rectangle {
                            id: rowDelegate
                            required property var modelData
                            required property int index

                            width: ListView.view.width
                            height: 26
                            radius: 6

                            readonly property bool isSelected: (root.selectedIndex === index)
                            readonly property bool isHovered: itemMouseArea.containsMouse

                            color: (isSelected || isHovered) ? Theme.surface : "transparent"
                            border.color: (isSelected || isHovered) ? Theme.accent : "transparent"
                            border.width: 1

                            Behavior on color {
                                ColorAnimation { duration: Theme.durationFast }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                // Action Icon (Nerd Font icon, NO emoji)
                                Text {
                                    Layout.preferredWidth: 20
                                    horizontalAlignment: Text.AlignHCenter
                                    text: rowDelegate.modelData.icon
                                    color: (rowDelegate.isSelected || rowDelegate.isHovered) ? Theme.accent : Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14

                                    Behavior on color {
                                        ColorAnimation { duration: Theme.durationFast }
                                    }
                                }

                                // Action Name
                                Text {
                                    Layout.fillWidth: true
                                    text: rowDelegate.modelData.name
                                    color: (rowDelegate.isSelected || rowDelegate.isHovered) ? Theme.fg : Theme.fg
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 11
                                    font.weight: (rowDelegate.isSelected || rowDelegate.isHovered) ? Font.Bold : Theme.fontWeight
                                    elide: Text.ElideRight
                                }

                                // Shortcut key badge (High-contrast, clearly visible)
                                Rectangle {
                                    Layout.preferredHeight: 19
                                    implicitWidth: keyText.implicitWidth + 12
                                    radius: 4
                                    color: (rowDelegate.isSelected || rowDelegate.isHovered) ? Theme.surfaceVariant : Theme.bgDark
                                    border.color: (rowDelegate.isSelected || rowDelegate.isHovered) ? Theme.accent : Theme.surfaceVariant
                                    border.width: 1

                                    Behavior on border.color {
                                        ColorAnimation { duration: Theme.durationFast }
                                    }
                                    Behavior on color {
                                        ColorAnimation { duration: Theme.durationFast }
                                    }

                                    Text {
                                        id: keyText
                                        anchors.centerIn: parent
                                        text: rowDelegate.modelData.key
                                        color: (rowDelegate.isSelected || rowDelegate.isHovered) ? Theme.accent : Theme.fg
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold

                                        Behavior on color {
                                            ColorAnimation { duration: Theme.durationFast }
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: itemMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selectedIndex = rowDelegate.index
                                onClicked: root.executeItem(rowDelegate.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
