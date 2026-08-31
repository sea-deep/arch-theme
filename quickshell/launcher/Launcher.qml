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
        onActivated: {
            if (contextMenu.visible) {
                contextMenu.visible = false
            } else {
                UiState.launcherVisible = false
            }
        }
    }

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

    property var activePinnedAppNames: []
    property var activeRecentAppNames: []
    property var launcherFlatModel: []
    property int totalFilteredCount: 0

    FileView {
        id: pinnedAppsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/state/pinned_apps.json"
        printErrors: false
    }

    FileView {
        id: recentAppsFile
        path: Quickshell.env("HOME") + "/.config/quickshell/state/recent_apps.json"
        printErrors: false
    }

    function syncPinnedFromDisk() {
        try {
            var raw = pinnedAppsFile.text().trim()
            if (raw) {
                var parsed = JSON.parse(raw)
                if (Array.isArray(parsed)) {
                    root.activePinnedAppNames = parsed
                    filterApps()
                    return
                }
            }
        } catch(e) {}
    }

    function syncRecentsFromDisk() {
        try {
            var raw = recentAppsFile.text().trim()
            if (raw) {
                var parsed = JSON.parse(raw)
                if (Array.isArray(parsed)) {
                    root.activeRecentAppNames = parsed.slice(0, 8)
                    filterApps()
                    return
                }
            }
        } catch(e) {}
    }

    function getPinnedAppNames() {
        if (root.activePinnedAppNames && root.activePinnedAppNames.length > 0) return root.activePinnedAppNames
        syncPinnedFromDisk()
        return root.activePinnedAppNames || []
    }

    function getRecentAppNames() {
        if (root.activeRecentAppNames && root.activeRecentAppNames.length > 0) return root.activeRecentAppNames
        syncRecentsFromDisk()
        return root.activeRecentAppNames || []
    }

    function isAppPinned(name) {
        if (!name) return false
        var clean = name.toLowerCase().trim()
        var pinned = root.activePinnedAppNames || []
        for (var i = 0; i < pinned.length; i++) {
            if (pinned[i] && pinned[i].toLowerCase().trim() === clean) return true
        }
        return false
    }

    function togglePinApp(name) {
        if (!name) return
        var clean = name.trim()
        var cleanLower = clean.toLowerCase()
        var pinned = (root.activePinnedAppNames || []).slice()
        var idx = -1
        for (var i = 0; i < pinned.length; i++) {
            if (pinned[i] && pinned[i].toLowerCase().trim() === cleanLower) {
                idx = i
                break
            }
        }
        if (idx !== -1) {
            pinned.splice(idx, 1)
        } else {
            pinned.push(clean)
        }
        root.activePinnedAppNames = pinned
        if (contextMenu.visible && contextMenu.appName && contextMenu.appName.toLowerCase().trim() === cleanLower) {
            contextMenu.isPinned = (idx === -1)
        }
        filterApps()

        var jsonStr = JSON.stringify(pinned)
        Quickshell.execDetached(["bash", "-c", "mkdir -p ~/.config/quickshell/state && printf '%s\\n' '" + jsonStr.replace(/'/g, "'\\''") + "' > ~/.config/quickshell/state/pinned_apps.json"])
    }

    function recordRecentApp(name) {
        if (!name) return
        var cleanName = name.trim()
        if (!cleanName) return

        var recents = (root.activeRecentAppNames || []).slice()
        recents = recents.filter(function(n) { return n && n.toLowerCase().trim() !== cleanName.toLowerCase() })
        recents.unshift(cleanName)
        if (recents.length > 8) recents = recents.slice(0, 8)
        root.activeRecentAppNames = recents
        filterApps()

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
        appListView.positionViewAtBeginning()
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
        var flatList = []
        var totalCount = 0

        if (query !== "") {
            var searchResults = []
            for (var i = 0; i < allApps.length; i++) {
                var item = allApps[i]
                if (item.searchTerms.indexOf(query) !== -1) {
                    searchResults.push(item)
                }
            }
            totalCount = searchResults.length
            if (searchResults.length > 0) {
                flatList.push({ isHeader: true, title: "Search Results (" + searchResults.length + ")", icon: "" })
                for (var i = 0; i < searchResults.length; i += 7) {
                    flatList.push({ isHeader: false, rowApps: searchResults.slice(i, i + 7) })
                }
            }
        } else if (cat === "all") {
            // 1. Pinned Apps section
            var pinnedNames = getPinnedAppNames()
            if (pinnedNames.length > 0) {
                var pinnedMap = {}
                for (var p = 0; p < pinnedNames.length; p++) {
                    if (pinnedNames[p]) {
                        pinnedMap[pinnedNames[p].toLowerCase().trim()] = p
                    }
                }
                var pinnedApps = []
                for (var i = 0; i < allApps.length; i++) {
                    var pKey = (allApps[i].name || "").toLowerCase().trim()
                    if (pinnedMap[pKey] !== undefined) {
                        pinnedApps.push({ appItem: allApps[i], order: pinnedMap[pKey] })
                    }
                }
                pinnedApps.sort(function(a, b) { return a.order - b.order })
                var pinnedList = pinnedApps.map(function(x) { return x.appItem })
                if (pinnedList.length > 0) {
                    flatList.push({ isHeader: true, title: "Pinned", icon: "󰤉" })
                    for (var i = 0; i < pinnedList.length; i += 7) {
                        flatList.push({ isHeader: false, rowApps: pinnedList.slice(i, i + 7) })
                    }
                }
            }

            // 2. Recently Opened section (up to 7 apps = 1 row)
            var recentNames = getRecentAppNames()
            if (recentNames.length > 0) {
                var recentMap = {}
                for (var r = 0; r < recentNames.length; r++) {
                    if (recentNames[r]) {
                        recentMap[recentNames[r].toLowerCase().trim()] = r
                    }
                }
                var recentApps = []
                for (var i = 0; i < allApps.length; i++) {
                    var nKey = (allApps[i].name || "").toLowerCase().trim()
                    if (recentMap[nKey] !== undefined) {
                        recentApps.push({ appItem: allApps[i], order: recentMap[nKey] })
                    }
                }
                recentApps.sort(function(a, b) { return a.order - b.order })
                var recentList = recentApps.slice(0, 7).map(function(x) { return x.appItem })
                if (recentList.length > 0) {
                    flatList.push({ isHeader: true, title: "Recently Opened", icon: "󰄉" })
                    flatList.push({ isHeader: false, rowApps: recentList })
                }
            }

            // 3. All Applications section
            if (allApps.length > 0) {
                flatList.push({ isHeader: true, title: "All Applications", icon: "󰀻" })
                for (var i = 0; i < allApps.length; i += 7) {
                    flatList.push({ isHeader: false, rowApps: allApps.slice(i, i + 7) })
                }
            }
            totalCount = allApps.length
        } else {
            var catResults = []
            for (var i = 0; i < allApps.length; i++) {
                var item = allApps[i]
                var matched = false
                for (var c = 0; c < item.categories.length; c++) {
                    if (item.categories[c].indexOf(cat) !== -1) {
                        matched = true
                        break
                    }
                }
                if (matched) {
                    catResults.push(item)
                }
            }
            totalCount = catResults.length
            if (catResults.length > 0) {
                flatList.push({ isHeader: true, title: root.activeCategory, icon: "󰀻" })
                for (var i = 0; i < catResults.length; i += 7) {
                    flatList.push({ isHeader: false, rowApps: catResults.slice(i, i + 7) })
                }
            }
        }

        root.launcherFlatModel = flatList
        root.totalFilteredCount = totalCount
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

    function launchFirstApp() {
        for (var i = 0; i < root.launcherFlatModel.length; i++) {
            var row = root.launcherFlatModel[i]
            if (!row.isHeader && row.rowApps && row.rowApps.length > 0) {
                root.launch(row.rowApps[0])
                return
            }
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
        syncPinnedFromDisk()
        syncRecentsFromDisk()
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
            if (activePinnedAppNames.length === 0) syncPinnedFromDisk()
            if (activeRecentAppNames.length === 0) syncRecentsFromDisk()
            searchQuery = ""
            searchInput.text = ""
            activeCategory = "All"
            contextMenu.visible = false
            if (allApps.length === 0) {
                reloadApps()
            } else {
                filterApps()
                appListView.positionViewAtBeginning()
            }
            searchInput.forceActiveFocus()
        } else {
            contextMenu.visible = false
        }
    }

    // Backdrop: transparent click outside closes launcher or dismisses context menu
    MouseArea {
        anchors.fill: parent
        enabled: root.showing
        onClicked: {
            if (contextMenu.visible) {
                contextMenu.visible = false
            } else {
                UiState.launcherVisible = false
            }
        }
    }

    // Bottom drawer unroll card container
    Components.BottomDrawerSurface {
        id: launcherCard
        // Exact width for 7 columns (7 * 120 = 840) + margins (24 * 2 = 48) = 888
        width: 888
        readonly property real fullHeight: layout.implicitHeight + layout.anchors.topMargin + 24
        height: fullHeight * root.reveal
        clip: true
        visible: height > 0
        
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0

        // Context menu outer click dismissal shield inside launcherCard
        MouseArea {
            anchors.fill: parent
            z: 9
            enabled: contextMenu.visible
            acceptedButtons: Qt.AllButtons
            onClicked: {
                contextMenu.visible = false
            }
        }

        Item {
            anchors.fill: parent
            clip: true
            opacity: Math.min(1.0, Math.max(0.0, (root.reveal - 0.08) / 0.92))

            Item {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                width: parent.width
                height: launcherCard.fullHeight

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
                                    appListView.positionViewAtBeginning()
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
                                Keys.onReturnPressed: {
                                    root.launchFirstApp()
                                }
                                Keys.onEnterPressed: {
                                    root.launchFirstApp()
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
                        text: root.totalFilteredCount + " apps"
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

            // Apps Continuous Scrollable Flat Virtualized List
            ListView {
                id: appListView
                Layout.preferredWidth: 840
                Layout.preferredHeight: 4 * 110
                Layout.alignment: Qt.AlignHCenter
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds
                model: root.launcherFlatModel

                delegate: Item {
                    id: rowItem
                    required property var modelData
                    required property int index

                    width: appListView.width
                    height: modelData.isHeader ? 32 : 110

                    // Section Header
                    RowLayout {
                        visible: rowItem.modelData.isHeader
                        anchors.fill: parent
                        anchors.topMargin: rowItem.index === 0 ? 0 : 8
                        anchors.bottomMargin: 4
                        spacing: 8

                        Text {
                            text: (rowItem.modelData.icon || "") + "  " + (rowItem.modelData.title || "")
                            color: Theme.accent
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 12
                            font.weight: Theme.fontWeight
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: Theme.surfaceVariant
                        }
                    }

                    // 7-column App Row
                    Row {
                        visible: !rowItem.modelData.isHeader
                        anchors.fill: parent
                        spacing: 0

                        Repeater {
                            model: rowItem.modelData.rowApps || []

                            Item {
                                id: delegateRoot
                                required property var modelData
                                required property int index

                                width: 120
                                height: 110

                                Rectangle {
                                    id: delegateCard
                                    anchors.centerIn: parent
                                    width: 112
                                    height: 102
                                    radius: Theme.radius
                                    color: cardMouse.containsMouse ? Theme.bgLight : Theme.bgDark
                                    border.width: 0

                                    Behavior on color { ColorAnimation { duration: Theme.durationFast } }

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
                                        color: Theme.fg
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
                                            if (mouse.button === Qt.LeftButton) {
                                                root.launch(delegateRoot.modelData)
                                            } else if (mouse.button === Qt.RightButton) {
                                                root.openContextMenu(delegateRoot.modelData, delegateCard)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Empty search result placeholder
                Text {
                    visible: root.totalFilteredCount === 0
                    anchors.centerIn: parent
                    text: "  No applications found"
                    color: Theme.fgDim
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 15
                }
            }
        }
    }

        // Floating Right-Click Option Selector Context Menu
        AppContextMenu {
            id: contextMenu
            visible: false
            z: 10
            onActionTriggered: root.close()
            onLaunchRequested: function(app, name) {
                root.launch({ app: app, name: name })
            }
            onPinToggled: function(name) {
                root.togglePinApp(name)
            }
        }
    }
}
}
