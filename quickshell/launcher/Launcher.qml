import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import "../components" as Components
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

    Shortcut {
        sequence: "Escape"
        enabled: root.showing
        onActivated: UiState.launcherVisible = false
    }

    property string searchQuery: ""
    property string activeCategory: "All"
    property var filteredApps: []
    property var allApps: []

    readonly property var categoryList: [
        { id: "All", label: "All", icon: "󰀻" },
        { id: "Pinned", label: "Pinned", icon: "󰤉" },
        { id: "Recent", label: "Recent", icon: "󰄉" },
        { id: "Development", label: "Development", icon: "" },
        { id: "Network", label: "Internet", icon: "󰖟" },
        { id: "AudioVideo", label: "Multimedia", icon: "󰎈" },
        { id: "Utility", label: "Utilities", icon: "󰛄" },
        { id: "System", label: "System", icon: "󰒓" },
        { id: "Settings", label: "Settings", icon: "" },
        { id: "Game", label: "Games", icon: "󰊗" }
    ]

    FileView {
        id: pinnedAppsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/state/pinned_apps.json"
        watchChanges: true
        printErrors: false
        onFileChanged: filterApps()
    }

    FileView {
        id: recentAppsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/state/recent_apps.json"
        watchChanges: true
        printErrors: false
        onFileChanged: filterApps()
    }

    function getPinnedAppNames() {
        try {
            var raw = pinnedAppsFile.text().trim()
            if (!raw) return []
            var parsed = JSON.parse(raw)
            if (Array.isArray(parsed)) return parsed
        } catch(e) {}
        return []
    }

    function getRecentAppNames() {
        try {
            var raw = recentAppsFile.text().trim()
            if (!raw) return []
            var parsed = JSON.parse(raw)
            if (Array.isArray(parsed)) return parsed.slice(0, 8)
        } catch(e) {}
        return []
    }

    function isAppPinned(name) {
        if (!name) return false
        var pinned = getPinnedAppNames()
        return pinned.indexOf(name) !== -1
    }

    function togglePinApp(name) {
        if (!name) return
        var pinned = getPinnedAppNames()
        var idx = pinned.indexOf(name)
        if (idx !== -1) {
            pinned.splice(idx, 1)
        } else {
            pinned.push(name)
        }
        var jsonStr = JSON.stringify(pinned)
        Quickshell.execDetached(["bash", "-c", "mkdir -p ~/.config/quickshell/state && printf '%s\\n' '" + jsonStr.replace(/'/g, "'\\''") + "' > ~/.config/quickshell/state/pinned_apps.json"])
        filterApps()
    }

    function recordRecentApp(name) {
        if (!name) return
        var recents = getRecentAppNames()
        recents = recents.filter(function(n) { return n !== name })
        recents.unshift(name)
        if (recents.length > 8) recents = recents.slice(0, 8)
        var jsonStr = JSON.stringify(recents)
        Quickshell.execDetached(["bash", "-c", "mkdir -p ~/.config/quickshell/state && printf '%s\\n' '" + jsonStr.replace(/'/g, "'\\''") + "' > ~/.config/quickshell/state/recent_apps.json"])
    }

    function reloadApps() {
        var raw = DesktopEntries.applications.values || []
        var valid = []
        var seen = {}
        for (var i = 0; i < raw.length; i++) {
            var app = raw[i]
            if (app && !app.noDisplay && app.name) {
                var cleanExec = (app.execString || "").replace(/%[a-zA-Z]/g, "").trim()
                var key = app.name.toLowerCase() + "::" + cleanExec.toLowerCase()
                if (seen[key]) continue
                seen[key] = true

                var cats = (app.categories || []).map(function(c) { return String(c).toLowerCase() })
                var kw = (app.keywords || []).join(" ")
                var searchStr = ((app.name || "") + " " + (app.genericName || "") + " " + (app.comment || "") + " " + kw).toLowerCase()
                var iconSrc = app.icon ? Quickshell.iconPath(app.icon, "application-x-executable") : ""

                valid.push({
                    app: app,
                    name: app.name || "",
                    icon: app.icon || "",
                    iconSource: iconSrc,
                    categories: cats,
                    searchTerms: searchStr
                })
            }
        }
        valid.sort(function(a, b) {
            return a.name.localeCompare(b.name)
        })
        allApps = valid
        filterApps()
    }

    function cycleCategory(forward) {
        var idx = 0
        for (var i = 0; i < categoryList.length; i++) {
            if (categoryList[i].id === activeCategory) {
                idx = i
                break
            }
        }
        if (forward) {
            idx = (idx + 1) % categoryList.length
        } else {
            idx = (idx - 1 + categoryList.length) % categoryList.length
        }
        activeCategory = categoryList[idx].id
        filterApps()
        grid.currentIndex = 0
        grid.positionViewAtBeginning()
    }

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.reloadApps()
        }
    }

    function filterApps() {
        var query = root.searchQuery.trim().toLowerCase()
        var cat = root.activeCategory.toLowerCase()

        if (cat === "pinned") {
            var pinned = getPinnedAppNames()
            var pinnedSet = {}
            for (var p = 0; p < pinned.length; p++) pinnedSet[pinned[p]] = true
            var result = []
            for (var i = 0; i < allApps.length; i++) {
                var item = allApps[i]
                if (pinnedSet[item.name]) {
                    if (query === "" || item.searchTerms.indexOf(query) !== -1) {
                        result.push(item)
                    }
                }
            }
            root.filteredApps = result
            if (grid.currentIndex >= result.length) {
                grid.currentIndex = Math.max(0, result.length - 1)
            }
            return
        }

        if (cat === "recent") {
            var recents = getRecentAppNames()
            var recentMap = {}
            for (var r = 0; r < recents.length; r++) recentMap[recents[r]] = r
            var result = []
            for (var i = 0; i < allApps.length; i++) {
                var item = allApps[i]
                if (recentMap[item.name] !== undefined) {
                    if (query === "" || item.searchTerms.indexOf(query) !== -1) {
                        result.push({ appItem: item, order: recentMap[item.name] })
                    }
                }
            }
            result.sort(function(a, b) { return a.order - b.order })
            root.filteredApps = result.map(function(x) { return x.appItem })
            if (grid.currentIndex >= root.filteredApps.length) {
                grid.currentIndex = Math.max(0, root.filteredApps.length - 1)
            }
            return
        }

        if (query === "" && cat === "all") {
            var pinned = getPinnedAppNames()
            if (pinned.length > 0) {
                var pinnedSet = {}
                for (var p = 0; p < pinned.length; p++) pinnedSet[pinned[p]] = true
                var pinnedList = []
                var restList = []
                for (var i = 0; i < allApps.length; i++) {
                    if (pinnedSet[allApps[i].name]) {
                        pinnedList.push(allApps[i])
                    } else {
                        restList.push(allApps[i])
                    }
                }
                root.filteredApps = pinnedList.concat(restList)
                return
            }
            root.filteredApps = allApps
            return
        }

        var result = []
        for (var i = 0; i < allApps.length; i++) {
            var item = allApps[i]

            // Fast category check
            if (cat !== "all") {
                var matched = false
                for (var c = 0; c < item.categories.length; c++) {
                    if (item.categories[c].indexOf(cat) !== -1) {
                        matched = true
                        break
                    }
                }
                if (!matched) continue
            }

            // Fast search query check
            if (query !== "" && item.searchTerms.indexOf(query) === -1) {
                continue
            }

            result.push(item)
        }

        root.filteredApps = result
        if (grid.currentIndex >= result.length) {
            grid.currentIndex = Math.max(0, result.length - 1)
        }
    }

    function launch(item) {
        if (!item) return
        var app = (item && item.app) ? item.app : item
        var appName = (item && item.name) ? item.name : (app ? app.name : "")
        if (appName) recordRecentApp(appName)
        close()

        if (app.runInTerminal) {
            var execCmd = app.execString || (app.command ? (typeof app.command.join === "function" ? app.command.join(" ") : app.command) : app.id)
            execCmd = execCmd.replace(/%[a-zA-Z]/g, "").trim()
            Quickshell.execDetached(["kitty", "-e", "sh", "-c", execCmd])
            return
        }

        if (app.execute) {
            app.execute()
        } else if (app.execString) {
            var cmd = app.execString.replace(/%[a-zA-Z]/g, "").trim()
            Quickshell.execDetached(["sh", "-c", cmd])
        }
    }

    function close() {
        contextMenu.visible = false
        UiState.launcherVisible = false
    }

    function openContextMenu(item, targetItem) {
        var app = (item && item.app) ? item.app : item
        var appName = (item && item.name) ? item.name : (app ? app.name : "")
        contextMenu.app = app
        contextMenu.appName = appName
        contextMenu.isPinned = root.isAppPinned(appName)

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

    property bool showing: UiState.launcherVisible
    property real reveal: showing ? 1 : 0

    Behavior on reveal {
        NumberAnimation {
            duration: root.showing ? 160 : 120
            easing.type: root.showing ? Easing.OutCubic : Easing.InQuad
        }
    }

    visible: reveal > 0

    onShowingChanged: {
        if (showing) {
            searchQuery = ""
            searchInput.text = ""
            activeCategory = "All"
            contextMenu.visible = false
            if (allApps.length === 0) {
                reloadApps()
            } else {
                filteredApps = allApps
                grid.currentIndex = 0
            }
            searchInput.forceActiveFocus()
        } else {
            contextMenu.visible = false
        }
    }

    // Backdrop: dim background and click outside closes launcher
    MouseArea {
        anchors.fill: parent
        onClicked: UiState.launcherVisible = false

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.reveal * 0.5
        }
    }

    // Bottom slide-up card container
    Components.BottomDrawerSurface {
        id: launcherCard
        // Exact width for 7 columns (7 * 120 = 840) + margins (24 * 2 = 48) = 888
        width: 888
        height: layout.implicitHeight + layout.anchors.topMargin + 24
        
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        transform: Translate {
            y: (1 - root.reveal) * (launcherCard.height + 32)
        }

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
                spacing: 10

                // Search Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.barHeight
                    radius: Theme.radius
                    color: Theme.bgDark
                    border.width: 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 10
                        spacing: 10

                        Text {
                            text: ""
                            color: searchInput.activeFocus ? Theme.accent : Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                            Behavior on color {
                                ColorAnimation { duration: Theme.durationFast }
                            }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Text {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search applications..."
                                color: Theme.fgMuted
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 14
                                visible: searchInput.text.length === 0
                            }

                            TextInput {
                                id: searchInput
                                anchors.fill: parent
                                color: Theme.fg
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 14
                                font.weight: Theme.fontWeight
                                verticalAlignment: TextInput.AlignVCenter
                                selectionColor: Theme.accent
                                selectedTextColor: Theme.bgDark

                                onTextChanged: {
                                    root.searchQuery = text
                                    root.filterApps()
                                    grid.currentIndex = 0
                                    grid.positionViewAtBeginning()
                                }

                                Keys.onEscapePressed: root.close()
                                Keys.onTabPressed: event => {
                                    root.cycleCategory(true)
                                    event.accepted = true
                                }
                                Keys.onBacktabPressed: event => {
                                    root.cycleCategory(false)
                                    event.accepted = true
                                }
                                Keys.onDownPressed: {
                                    if (grid.count > 0) {
                                        grid.currentIndex = Math.min(grid.count - 1, grid.currentIndex + grid.columns)
                                        grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
                                    }
                                }
                                Keys.onUpPressed: {
                                    if (grid.count > 0) {
                                        grid.currentIndex = Math.max(0, grid.currentIndex - grid.columns)
                                        grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
                                    }
                                }
                                Keys.onRightPressed: {
                                    if (grid.count > 0) {
                                        grid.currentIndex = Math.min(grid.count - 1, grid.currentIndex + 1)
                                        grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
                                    }
                                }
                                Keys.onLeftPressed: {
                                    if (grid.count > 0) {
                                        grid.currentIndex = Math.max(0, grid.currentIndex - 1)
                                        grid.positionViewAtIndex(grid.currentIndex, GridView.Contain)
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
                        }

                        // Clear search button
                        Rectangle {
                            visible: searchInput.text.length > 0
                            width: 22
                            height: 22
                            radius: 11
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

                // App count badge (styled as top bar pill)
                Rectangle {
                    Layout.preferredHeight: Theme.barHeight
                    implicitWidth: countText.implicitWidth + 20
                    radius: Theme.radius
                    color: Theme.bgDark
                    border.width: 0

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

            // Category toolbar (styled identically to the top bar workspace pill container)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.barHeight
                radius: Theme.radius
                color: Theme.bgDark
                border.color: "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: 4

                    Repeater {
                        model: root.categoryList

                        Rectangle {
                            id: catChip
                            required property var modelData
                            readonly property bool isActive: root.activeCategory === modelData.id

                            Layout.fillHeight: true
                            implicitWidth: chipRow.implicitWidth + 18
                            radius: Theme.radiusSmall
                            color: isActive ? Theme.accent : (chipHover.containsMouse ? Theme.surface : "transparent")

                            Behavior on color { ColorAnimation { duration: Theme.durationFast } }

                            RowLayout {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: catChip.modelData.icon
                                    color: catChip.isActive ? Theme.bgDark : (chipHover.containsMouse ? Theme.fg : Theme.accent)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 13
                                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
                                }

                                Text {
                                    text: catChip.modelData.label
                                    color: catChip.isActive ? Theme.bgDark : (chipHover.containsMouse ? Theme.fg : Theme.fgDim)
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 13
                                    font.weight: catChip.isActive ? Font.Bold : Theme.fontWeight
                                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }
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

                    Item { Layout.fillWidth: true }

                    // Tab key navigation hint pill
                    Rectangle {
                        Layout.fillHeight: true
                        implicitWidth: tabHintRow.implicitWidth + 12
                        radius: Theme.radiusSmall
                        color: Theme.surface
                        opacity: 0.75

                        RowLayout {
                            id: tabHintRow
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "Tab"
                                color: Theme.fgDim
                                font.family: Theme.fontFamilySans
                                font.pixelSize: 11
                                font.weight: Theme.fontWeight
                            }

                            Text {
                                text: "󰌑"
                                color: Theme.accent
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.surfaceVariant
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
                cacheBuffer: 110
                reuseItems: true
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

                Keys.onTabPressed: event => {
                    root.cycleCategory(true)
                    event.accepted = true
                }
                Keys.onBacktabPressed: event => {
                    root.cycleCategory(false)
                    event.accepted = true
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
                        readonly property bool isSelected: grid.currentIndex === delegateRoot.index

                        anchors.centerIn: parent
                        width: grid.cellWidth - 8
                        height: grid.cellHeight - 8
                        radius: Theme.radius

                        color: isSelected 
                            ? Theme.surface 
                            : (cardMouse.containsMouse ? Theme.bgLight : Theme.bgDark)
                        border.width: 0

                        IconImage {
                            id: appIcon
                            anchors.top: parent.top
                            anchors.topMargin: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 44
                            height: 44
                            source: delegateRoot.modelData ? (delegateRoot.modelData.iconSource || "") : ""
                        }

                        Text {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.topMargin: 4
                            anchors.rightMargin: 6
                            text: "󰤉"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            visible: delegateRoot.modelData ? root.isAppPinned(delegateRoot.modelData.name) : false
                        }

                        Text {
                            anchors.top: appIcon.bottom
                            anchors.topMargin: 6
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            text: delegateRoot.modelData ? (delegateRoot.modelData.name || "") : ""
                            color: delegateCard.isSelected ? Theme.accent : Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 12
                            font.weight: Theme.fontWeight
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.Wrap
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
            onPinToggled: function(name) {
                root.togglePinApp(name)
            }
        }
    }
}
