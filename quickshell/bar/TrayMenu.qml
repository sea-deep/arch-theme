import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"

PanelWindow {
    id: root

    property string targetScreenName: ""
    property var currentMenu: UiState.trayMenuHandle
    property var menuStack: []
    readonly property bool shouldOpen: UiState.trayMenuVisible
        && UiState.trayMenuHandle !== null
        && (UiState.trayMenuScreen === "" || UiState.trayMenuScreen === targetScreenName)
    readonly property int itemHeight: 32
    readonly property int contentHeight: Math.min(380,
        46 + Math.max(1, menuOpener.children.values.length) * itemHeight + 12)

    anchors.top: true
    anchors.right: true
    margins.top: Theme.outerGap + Theme.barHeight + Theme.moduleSpacing
    margins.right: UiState.trayMenuRightOffset
    implicitWidth: 260
    implicitHeight: contentHeight
    color: "transparent"
    visible: shouldOpen

    WlrLayershell.namespace: "quickshell-tray-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    onShouldOpenChanged: {
        if (shouldOpen) {
            currentMenu = UiState.trayMenuHandle
            menuStack = []
            menuView.currentIndex = menuOpener.children.values.length > 0 ? 0 : -1
            Qt.callLater(() => menuView.forceActiveFocus())
        }
    }

    Connections {
        target: UiState
        function onTrayMenuHandleChanged() {
            root.currentMenu = UiState.trayMenuHandle
            root.menuStack = []
        }
    }

    function close() {
        UiState.trayMenuVisible = false
    }

    function activateEntry(entry) {
        if (!entry || !entry.enabled || entry.isSeparator)
            return

        if (entry.hasChildren) {
            menuStack = menuStack.concat([currentMenu])
            currentMenu = entry
            menuView.currentIndex = 0
            return
        }

        entry.triggered()
        close()
    }

    function goBack() {
        if (menuStack.length === 0) {
            close()
            return
        }

        currentMenu = menuStack[menuStack.length - 1]
        menuStack = menuStack.slice(0, -1)
        menuView.currentIndex = 0
    }

    Shortcut { sequence: "Escape"; onActivated: root.close() }

    QsMenuOpener {
        id: menuOpener
        menu: root.currentMenu
    }

    Rectangle {
        width: parent.width
        height: root.contentHeight
        anchors.top: parent.top
        radius: Theme.radius
        color: Theme.bg
        border.width: Theme.borderWidth
        border.color: Theme.bgDark
        clip: true

        RowLayout {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 8
            height: 30
            spacing: 8

            Rectangle {
                visible: root.menuStack.length > 0
                Layout.preferredWidth: visible ? 28 : 0
                Layout.preferredHeight: 28
                radius: 8
                color: backHover.hovered ? Theme.surface : Theme.bgLight
                Text {
                    anchors.centerIn: parent
                    text: "󰁍"
                    color: Theme.fg
                    font.family: Theme.fontFamily
                }
                HoverHandler { id: backHover }
                TapHandler { onTapped: root.goBack() }
            }

            IconImage {
                visible: root.menuStack.length === 0 && UiState.trayMenuIcon !== ""
                Layout.preferredWidth: visible ? 20 : 0
                Layout.preferredHeight: 20
                source: UiState.trayMenuIcon
            }

            Text {
                Layout.fillWidth: true
                text: root.menuStack.length > 0 ? "Application menu" : UiState.trayMenuTitle
                color: Theme.fg
                elide: Text.ElideRight
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Theme.fontWeight
            }

            Text {
                text: "󰅖"
                color: closeHover.hovered ? Theme.red : Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 14
                HoverHandler { id: closeHover }
                TapHandler { onTapped: root.close() }
            }
        }

        Rectangle {
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Theme.borderWidth
            anchors.rightMargin: Theme.borderWidth
            height: 1
            color: Theme.surface
        }

        ListView {
            id: menuView
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 6
            anchors.topMargin: 5
            clip: true
            spacing: 0
            model: menuOpener.children
            activeFocusOnTab: true
            highlightMoveDuration: 70

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Down) {
                    incrementCurrentIndex()
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    decrementCurrentIndex()
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    root.activateEntry(currentItem ? currentItem.menuEntry : null)
                    event.accepted = true
                } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backspace) {
                    root.goBack()
                    event.accepted = true
                }
            }

            delegate: Item {
                id: delegateRoot
                required property var modelData
                required property int index
                readonly property var menuEntry: modelData
                width: ListView.view.width
                height: modelData.isSeparator ? 9 : root.itemHeight

                Rectangle {
                    visible: delegateRoot.modelData.isSeparator
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    height: 1
                    color: Theme.surface
                }

                Rectangle {
                    anchors.fill: parent
                    visible: !delegateRoot.modelData.isSeparator
                    radius: 8
                    color: delegateRoot.modelData.enabled
                            && (delegateRoot.ListView.isCurrentItem || entryHover.hovered)
                        ? Theme.accent : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        Text {
                            visible: delegateRoot.modelData.buttonType !== QsMenuButtonType.None
                            Layout.preferredWidth: visible ? 16 : 0
                            text: delegateRoot.modelData.checkState === Qt.Checked ? "󰄬" : ""
                            color: Theme.bgDark
                            font.family: Theme.fontFamily
                        }

                        IconImage {
                            visible: delegateRoot.modelData.icon !== ""
                            Layout.preferredWidth: visible ? 18 : 0
                            Layout.preferredHeight: 18
                            source: delegateRoot.modelData.icon
                        }

                        Text {
                            Layout.fillWidth: true
                            text: delegateRoot.modelData.text
                            color: !delegateRoot.modelData.enabled ? Theme.fgMuted
                                : (delegateRoot.ListView.isCurrentItem || entryHover.hovered
                                    ? Theme.bgDark : Theme.fg)
                            elide: Text.ElideRight
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Theme.fontWeight
                        }

                        Text {
                            visible: delegateRoot.modelData.hasChildren
                            text: "󰅂"
                            color: delegateRoot.ListView.isCurrentItem || entryHover.hovered
                                ? Theme.bgDark : Theme.fgDim
                            font.family: Theme.fontFamily
                        }
                    }

                    HoverHandler { id: entryHover }
                    TapHandler {
                        enabled: delegateRoot.modelData.enabled
                        onTapped: {
                            menuView.currentIndex = delegateRoot.index
                            root.activateEntry(delegateRoot.modelData)
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: menuOpener.children.values.length === 0
                text: "No menu actions"
                color: Theme.fgDim
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
    }
}
