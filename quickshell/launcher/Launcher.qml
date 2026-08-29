import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../theme"

PanelWindow {
    WlrLayershell.namespace: "quickshell-launcher"
    id: root

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"
    visible: UiState.launcherVisible

    property string searchQuery: ""
    property string activeCategory: "All"
    property var filteredApps: []
    property var allApps: []

    readonly property var categoryList: [
        { id: "All", label: "All", icon: "󰀻" },
        { id: "Development", label: "Development", icon: "" },
        { id: "Network", label: "Internet", icon: "󰖟" },
        { id: "AudioVideo", label: "Multimedia", icon: "󰎈" },
        { id: "Utility", label: "Utilities", icon: "󰛄" },
        { id: "System", label: "System", icon: "󰒓" },
        { id: "Settings", label: "Settings", icon: "" },
        { id: "Game", label: "Games", icon: "󰊗" }
    ]

    function reloadApps() {
        var raw = DesktopEntries.applications.values || []
        var valid = []
        for (var i = 0; i < raw.length; i++) {
            var app = raw[i]
            if (app && !app.noDisplay && app.name) {
                valid.push(app)
            }
        }
        // Sort alphabetically by name
        valid.sort(function(a, b) {
            return (a.name || "").localeCompare(b.name || "")
        })
        allApps = valid
        filterApps()
    }

    function filterApps() {
        var query = root.searchQuery.trim().toLowerCase()
        var cat = root.activeCategory
        var result = []

        for (var i = 0; i < allApps.length; i++) {
            var app = allApps[i]

            // Category check
            if (cat !== "All") {
                var cats = app.categories || []
                var matchCat = false
                for (var c = 0; c < cats.length; c++) {
                    if (cats[c].toLowerCase().indexOf(cat.toLowerCase()) !== -1) {
                        matchCat = true
                        break
                    }
                }
                if (!matchCat) continue
            }

            // Search query check
            if (query !== "") {
                var nameMatch = (app.name || "").toLowerCase().indexOf(query) !== -1
                var commentMatch = (app.comment || "").toLowerCase().indexOf(query) !== -1
                var genMatch = (app.genericName || "").toLowerCase().indexOf(query) !== -1
                var keyMatch = false
                var keywords = app.keywords || []
                for (var k = 0; k < keywords.length; k++) {
                    if (keywords[k].toLowerCase().indexOf(query) !== -1) {
                        keyMatch = true
                        break
                    }
                }

                if (!nameMatch && !commentMatch && !genMatch && !keyMatch) {
                    continue
                }
            }

            result.push(app)
        }

        root.filteredApps = result
        if (grid.currentIndex >= result.length) {
            grid.currentIndex = Math.max(0, result.length - 1)
        }
    }

    function launch(app) {
        if (!app) return
        close()
        if (app.execute) {
            app.execute()
        }
    }

    function close() {
        contextMenu.visible = false
        UiState.launcherVisible = false
    }

    function openContextMenu(app, targetItem) {
        contextMenu.app = app
        var pos = targetItem.mapToItem(launcherCard, 0, 0)
        var menuX = pos.x + targetItem.width + 8
        var menuY = pos.y

        // Bounds check inside launcherCard
        if (menuX + contextMenu.width > launcherCard.width - 16) {
            menuX = pos.x - contextMenu.width - 8
        }
        if (menuX < 16) menuX = 16

        if (menuY + contextMenu.implicitHeight > launcherCard.height - 16) {
            menuY = launcherCard.height - contextMenu.implicitHeight - 16
        }
        if (menuY < 16) menuY = 16

        contextMenu.x = menuX
        contextMenu.y = menuY
        contextMenu.visible = true
    }

    Component.onCompleted: {
        reloadApps()
    }

    onVisibleChanged: {
        if (visible) {
            searchQuery = ""
            searchInput.text = ""
            activeCategory = "All"
            contextMenu.visible = false
            reloadApps()
            Qt.callLater(function() {
                searchInput.forceActiveFocus()
            })
        } else {
            contextMenu.visible = false
        }
    }

    // Backdrop: click outside closes launcher
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    // Bottom slide-up card container
    Rectangle {
        id: launcherCard
        // Exact width for 7 columns (7 * 120 = 840) + margins (24 * 2 = 48) = 888
        width: 888
        height: layout.implicitHeight + layout.anchors.topMargin + 24
        anchors.horizontalCenter: parent.horizontalCenter

        // Slide up completely from off-screen bottom edge to a small gap
        y: root.visible ? (parent.height - height - 16) : parent.height + 20
        opacity: root.visible ? 1 : 0
        scale: root.visible ? 1 : 0.98

        Behavior on y {
            NumberAnimation { duration: 250; easing.type: Easing.OutExpo }
        }
        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
        }
        Behavior on scale {
            NumberAnimation { duration: 250; easing.type: Easing.OutExpo }
        }

        color: Theme.bg
        radius: 16
        border.color: Theme.surface
        border.width: 1

        // Consume clicks on card so backdrop doesn't close launcher
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: {
                if (contextMenu.visible) contextMenu.visible = false
            }
        }

        ColumnLayout {
            id: layout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 24
            spacing: 16

            // Top Header: Search bar + app count badge
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Search Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: Theme.radius
                    color: Theme.bgLight
                    border.color: searchInput.activeFocus ? Theme.accent : Theme.surface
                    border.width: 1

                    Behavior on border.color {
                        ColorAnimation { duration: 150 }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            text: ""
                            color: searchInput.activeFocus ? Theme.accent : Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            Behavior on color {
                                ColorAnimation { duration: 150 }
                            }
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 15
                            verticalAlignment: TextInput.AlignVCenter
                            selectionColor: Theme.accent
                            selectedTextColor: Theme.bgDark

                            onTextChanged: {
                                root.searchQuery = text
                                root.filterApps()
                                grid.currentIndex = 0
                            }

                            Keys.onEscapePressed: root.close()
                            Keys.onDownPressed: {
                                if (grid.count > 0) {
                                    grid.forceActiveFocus()
                                    grid.currentIndex = 0
                                }
                            }
                            Keys.onReturnPressed: {
                                if (root.filteredApps.length > 0) {
                                    var idx = (grid.currentIndex >= 0 && grid.currentIndex < root.filteredApps.length) ? grid.currentIndex : 0
                                    root.launch(root.filteredApps[idx])
                                }
                            }
                            Keys.onEnterPressed: {
                                if (root.filteredApps.length > 0) {
                                    var idx = (grid.currentIndex >= 0 && grid.currentIndex < root.filteredApps.length) ? grid.currentIndex : 0
                                    root.launch(root.filteredApps[idx])
                                }
                            }
                        }

                        // Clear search button
                        Rectangle {
                            visible: searchInput.text.length > 0
                            width: 24
                            height: 24
                            radius: 12
                            color: clearHover.containsMouse ? Theme.surface : "transparent"
                            Behavior on color { ColorAnimation { duration: 100 } }

                            Text {
                                anchors.centerIn: parent
                                text: ""
                                color: Theme.fgDim
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: clearHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = ""
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }
                    }
                }

                // App count badge
                Rectangle {
                    Layout.preferredHeight: 44
                    implicitWidth: countText.implicitWidth + 24
                    radius: Theme.radius
                    color: Theme.bgLight
                    border.color: Theme.surface
                    border.width: 1

                    Text {
                        id: countText
                        anchors.centerIn: parent
                        text: root.filteredApps.length + " apps"
                        color: Theme.fgDim
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 13
                        font.weight: Theme.fontWeight
                    }
                }
            }

            // Category filter chips row
            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                RowLayout {
                    spacing: 8

                    Repeater {
                        model: root.categoryList

                        Rectangle {
                            id: catChip
                            required property var modelData
                            readonly property bool isActive: root.activeCategory === modelData.id

                            implicitWidth: chipRow.implicitWidth + 24
                            implicitHeight: 32
                            radius: 16
                            color: isActive ? Theme.accent : (chipHover.containsMouse ? Theme.bgLight : "transparent")
                            border.color: isActive ? Theme.accent : (chipHover.containsMouse ? Theme.surface : "transparent")
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            RowLayout {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: catChip.modelData.icon
                                    color: catChip.isActive ? Theme.bgDark : (chipHover.containsMouse ? Theme.accent : Theme.fgDim)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Text {
                                    text: catChip.modelData.label
                                    color: catChip.isActive ? Theme.bgDark : Theme.fg
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 13
                                    font.weight: catChip.isActive ? Font.Bold : Font.Medium
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                            }

                            MouseArea {
                                id: chipHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeCategory = catChip.modelData.id
                                    root.filterApps()
                                    searchInput.forceActiveFocus()
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.surface
            }

            // Apps Grid
            GridView {
                id: grid
                Layout.preferredWidth: 840
                Layout.preferredHeight: 4 * 110
                Layout.alignment: Qt.AlignHCenter
                cellWidth: 120
                cellHeight: 110
                clip: true
                model: root.filteredApps
                activeFocusOnTab: true
                highlightFollowsCurrentItem: true
                keyNavigationEnabled: true

                readonly property int columns: Math.floor(width / cellWidth)

                Keys.onEscapePressed: {
                    if (contextMenu.visible) {
                        contextMenu.visible = false
                    } else {
                        root.close()
                    }
                }

                Keys.onReturnPressed: {
                    if (currentIndex >= 0 && currentIndex < root.filteredApps.length) {
                        root.launch(root.filteredApps[currentIndex])
                    }
                }
                Keys.onEnterPressed: {
                    if (currentIndex >= 0 && currentIndex < root.filteredApps.length) {
                        root.launch(root.filteredApps[currentIndex])
                    }
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Up && currentIndex < columns) {
                        searchInput.forceActiveFocus()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Backspace) {
                        searchInput.forceActiveFocus()
                        if (searchInput.text.length > 0) {
                            searchInput.text = searchInput.text.slice(0, -1)
                        }
                        event.accepted = true
                    } else if (event.text && event.text.length > 0 && event.text.charCodeAt(0) >= 32 && event.key !== Qt.Key_Space) {
                        searchInput.forceActiveFocus()
                        searchInput.text += event.text
                        event.accepted = true
                    }
                }

                delegate: Item {
                    id: delegateRoot
                    required property var modelData
                    required property int index

                    width: grid.cellWidth
                    height: grid.cellHeight

                    Rectangle {
                        id: delegateCard
                        readonly property bool isSelected: grid.activeFocus && grid.currentIndex === delegateRoot.index

                        anchors.centerIn: parent
                        width: grid.cellWidth - 10
                        height: grid.cellHeight - 10
                        radius: Theme.radius

                        scale: isSelected ? 1.02 : (cardMouse.containsMouse ? 1.02 : 1.0)
                        color: isSelected ? Theme.accent : (cardMouse.containsMouse ? Theme.bgLight : "transparent")
                        border.color: isSelected ? Theme.accent : (cardMouse.containsMouse ? Theme.surface : "transparent")
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 48
                                Layout.preferredHeight: 48

                                IconImage {
                                    anchors.fill: parent
                                    source: delegateRoot.modelData && delegateRoot.modelData.icon
                                        ? Quickshell.iconPath(delegateRoot.modelData.icon, "application-x-executable")
                                        : ""
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignHCenter
                                text: delegateRoot.modelData ? (delegateRoot.modelData.name || "") : ""
                                color: delegateCard.isSelected ? Theme.bgDark : Theme.fg
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 12
                                font.weight: Theme.fontWeight
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor

                            onClicked: mouse => {
                                grid.currentIndex = delegateRoot.index
                                if (mouse.button === Qt.LeftButton) {
                                    root.launch(delegateRoot.modelData)
                                } else if (mouse.button === Qt.RightButton) {
                                    root.openContextMenu(delegateRoot.modelData, delegateCard)
                                }
                            }
                        }
                    }
                }

                // Empty search result placeholder
                Text {
                    visible: root.filteredApps.length === 0
                    anchors.centerIn: parent
                    text: "  No applications found"
                    color: Theme.fgDim
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 15
                }
            }
        }

        // Floating Right-Click Option Selector Context Menu
        AppContextMenu {
            id: contextMenu
            visible: false
            z: 10
            onActionTriggered: root.close()
        }
    }
}
