import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.DBusMenu
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../theme"
import "../components" as Components

Item {
    id: root

    property string targetScreenName: ""
    property var currentMenu: UiState.trayMenuHandle
    property var menuStack: []
    property var pendingSubmenuRefresh: null
    property bool submenuLoading: false
    property bool rootMenuRetained: false
    property bool rootMenuLoading: false
    property int rootMenuLoadAttempts: 0
    readonly property real collapsedWidth: trayItems.length === 1 ? Theme.compactPillSize : Math.max(Theme.compactPillSize, trayRow.implicitWidth + Theme.pillPaddingHoriz * 2)
    readonly property real topWidth: collapsedWidth
    readonly property var trayItems: SystemTray.items.values.filter(item => {
        // The NetworkManager applet is replaced by NetworkExpander, which uses
        // Quickshell's native NetworkManager integration instead of its flaky
        // mutable DBusMenu implementation.
        return (item.id || "").toLowerCase().indexOf("nm-applet") === -1
    })
    readonly property bool isEmpty: trayItems.length === 0
    readonly property bool expanded: UiState.trayMenuVisible
        && UiState.trayMenuHandle !== null
        && (UiState.trayMenuScreen === "" || UiState.trayMenuScreen === targetScreenName)
    readonly property int itemHeight: 32
    readonly property int bodyHeight: Math.min(380,
        46 + Math.max(1, menuOpener.children.values.length) * itemHeight + 12)
    property real reveal: expanded ? 1 : 0

    property real expandedWidth: Math.max(260, collapsedWidth)
    implicitWidth: isEmpty ? 0
        : (expanded || reveal > 0 ? expandedWidth : collapsedWidth)
    implicitHeight: isEmpty ? 0 : (reveal > 0
        ? Theme.barHeight + Theme.outerGap + bodyHeight * reveal
        : Theme.barHeight)
    visible: !isEmpty
    focus: expanded

    Behavior on reveal {
        NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easingDecelerate }
    }

    onExpandedChanged: {
        if (expanded) {
            reloadRootMenu()
        } else {
            resetMenuState()
        }
    }

    Connections {
        target: UiState
        function onTrayMenuHandleChanged() {
            if (root.expanded)
                root.reloadRootMenu()
        }
    }

    function resetMenuState() {
        pendingSubmenuRefresh = null
        submenuLoading = false
        rootMenuLoading = false
        rootMenuLoadAttempts = 0
        submenuRefreshTimer.stop()
        submenuLoadingTimeout.stop()
        rootMenuRetryTimer.stop()
        rootMenuRetained = false
        currentMenu = null
        menuStack = []
    }

    function reloadRootMenu() {
        // Force a fresh DBusMenu acquisition. nm-applet can occasionally leave
        // a closed menu's root model empty even though it has actions.
        pendingSubmenuRefresh = null
        submenuLoading = false
        submenuRefreshTimer.stop()
        submenuLoadingTimeout.stop()
        rootMenuRetryTimer.stop()
        rootMenuRetained = false
        currentMenu = null
        menuStack = []
        rootMenuLoading = true

        Qt.callLater(() => {
            if (!root.expanded)
                return

            rootMenuRetained = true
            currentMenu = UiState.trayMenuHandle
            menuView.currentIndex = -1
            rootMenuRetryTimer.restart()
            menuView.forceActiveFocus()
        })
    }

    function close() {
        resetMenuState()
        UiState.trayMenuVisible = false
    }

    function toggleMenu(item) {
        if (item && item.hasMenu && item.menu !== null)
            UiState.toggleTrayMenu(item, targetScreenName, 0)
    }

    function activateEntry(entry) {
        if (!entry || !entry.enabled || entry.isSeparator)
            return

        if (entry.hasChildren) {
            menuStack = menuStack.concat([currentMenu])
            currentMenu = entry
            menuView.currentIndex = -1
            refreshSubmenu(entry)
            return
        }

        entry.triggered()
        close()
    }

    function goBack() {
        pendingSubmenuRefresh = null
        submenuLoading = false
        submenuRefreshTimer.stop()
        submenuLoadingTimeout.stop()

        if (menuStack.length === 0) {
            close()
            return
        }

        currentMenu = menuStack[menuStack.length - 1]
        menuStack = menuStack.slice(0, -1)
        menuView.currentIndex = 0
    }

    function refreshSubmenu(entry) {
        if (!entry || root.currentMenu !== entry)
            return

        pendingSubmenuRefresh = entry
        submenuLoading = true
        submenuRefreshTimer.restart()
        submenuLoadingTimeout.restart()
    }

    Timer {
        id: rootMenuRetryTimer
        interval: 360
        onTriggered: {
            if (!root.expanded || !root.rootMenuLoading
                    || root.menuStack.length !== 0
                    || menuOpener.children.values.length > 0)
                return

            if (root.rootMenuLoadAttempts >= 1) {
                root.rootMenuLoading = false
                return
            }

            root.rootMenuLoadAttempts += 1
            root.reloadRootMenu()
        }
    }

    // DBus tray providers such as nm-applet build some submenus only after the
    // submenu receives its opened event. QsMenuOpener sends that event when the
    // handle changes; refresh on the next event-loop turn so the new children
    // are fetched after the provider has populated them.
    Timer {
        id: submenuRefreshTimer
        interval: 80
        onTriggered: {
            const entry = root.pendingSubmenuRefresh
            root.pendingSubmenuRefresh = null

            if (entry && root.currentMenu === entry
                    && typeof entry.updateLayout === "function")
                entry.updateLayout()
        }
    }

    Timer {
        id: submenuLoadingTimeout
        interval: 1200
        onTriggered: root.submenuLoading = false
    }

    Keys.onEscapePressed: root.close()

    QsMenuOpener {
        id: menuOpener
        menu: root.expanded ? root.currentMenu : null
    }

    // Keep the provider's root DBusMenu referenced while navigating children.
    // A JavaScript reference in menuStack does not retain a QsMenuHandle, so
    // without this opener switching menuOpener to a child destroys that child.
    QsMenuOpener {
        id: rootMenuKeeper
        menu: root.expanded && root.rootMenuRetained ? UiState.trayMenuHandle : null
    }

    Components.ConnectedDropdownSurface {
        z: 1
        anchors.fill: parent
        hasLeftShoulder: true
        hasRightShoulder: false
        hasBottomRightInverted: true
        visible: root.reveal > 0
    }

    Components.Pill {
        z: 2
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.collapsedWidth
        height: Theme.barHeight
        visible: root.reveal <= 0
    }

    Item {
        id: topButton
        z: 3
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.collapsedWidth
        height: Theme.barHeight

        RowLayout {
            id: trayRow
            anchors.centerIn: parent
            spacing: 10

            Repeater {
                model: root.trayItems

                Item {
                    required property var modelData
                    width: 18
                    height: 18

                    IconImage {
                        anchors.fill: parent
                        source: parent.modelData.icon
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.LeftButton) {
                                if (parent.modelData.hasMenu)
                                    root.toggleMenu(parent.modelData)
                                else {
                                    root.close()
                                    parent.modelData.activate()
                                }
                            } else if (mouse.button === Qt.MiddleButton) {
                                parent.modelData.secondaryActivate()
                            } else {
                                root.toggleMenu(parent.modelData)
                            }
                        }
                        onWheel: wheel => parent.modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }
        }
    }

    Rectangle {
        z: 2
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + Theme.outerGap
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.bodyHeight * root.reveal
        visible: height > 0
        opacity: Math.max(0.0, Math.min(1.0, (root.reveal - 0.15) / 0.85))
        color: "transparent"
        border.width: 0
        clip: true

        Item {
            anchors.top: parent.top
            width: parent.width
            height: root.bodyHeight

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
                    radius: Theme.radiusSmall
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
                    text: root.menuStack.length > 0 && root.currentMenu && root.currentMenu.text
                        ? root.currentMenu.text : UiState.trayMenuTitle
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
                onCountChanged: {
                    if (count > 0) {
                        root.rootMenuLoading = false
                        rootMenuRetryTimer.stop()
                        root.submenuLoading = false
                        submenuLoadingTimeout.stop()
                        if (currentIndex < 0)
                            currentIndex = 0
                    } else if (root.menuStack.length > 0) {
                        // nm-applet may send a root LayoutUpdated while a
                        // dynamic submenu is open. Quickshell then clears the
                        // submenu model even though its DBusMenuItem survives;
                        // refresh that item in place rather than showing an
                        // incorrect empty menu.
                        root.refreshSubmenu(root.currentMenu)
                    } else if (!root.rootMenuLoading && root.expanded) {
                        root.rootMenuLoading = true
                        rootMenuRetryTimer.restart()
                    }
                }

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
                        radius: Theme.radiusSmall
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
                    text: root.rootMenuLoading || root.submenuLoading
                        ? "Loading…" : "No menu actions"
                    color: Theme.fgDim
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
            }
        }
    }
}
