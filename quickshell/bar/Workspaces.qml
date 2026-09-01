import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../theme"
import "../components" as Components

Item {
    id: root
    
    property var hoveredWorkspace: null
    
    readonly property var activeWs: (hoveredWorkspace !== null ? hoveredWorkspace : Hyprland.focusedWorkspace)
    
    readonly property var windowList: activeWs && activeWs.toplevels
        ? activeWs.toplevels.values
        : []
    
    property bool isHovered: false
    readonly property bool isExpanded: root.isHovered
    property real reveal: isExpanded ? 1 : 0
    
    readonly property real collapsedWidth: topLayout.implicitWidth + 8
    readonly property real expandedWidth: Math.max(340, collapsedWidth + 40)
    readonly property int bodyHeight: contentCol.implicitHeight > 0 ? (contentCol.implicitHeight + 8) : 56
    
    implicitWidth: reveal > 0 ? expandedWidth : collapsedWidth
    implicitHeight: reveal > 0
        ? Theme.barHeight + bodyHeight * reveal
        : Theme.barHeight
    width: implicitWidth
    height: implicitHeight
    
    Behavior on reveal { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easingDecelerate } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.durationMedium; easing.type: Theme.easingDecelerate } }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            root.hoveredWorkspace = null
        }
    }

    Timer {
        id: closeTimer
        interval: 260
        onTriggered: {
            root.isHovered = false
            root.hoveredWorkspace = null
        }
    }

    HoverHandler {
        id: globalHover
        onHoveredChanged: {
            if (hovered) {
                closeTimer.stop()
                root.isHovered = true
            } else {
                closeTimer.restart()
            }
        }
    }

    function getAppIcon(toplevel) {
        if (!toplevel) return Quickshell.iconPath("application-x-executable")
        
        var cls = (toplevel.lastIpcObject && toplevel.lastIpcObject.class)
            || (toplevel.wayland && toplevel.wayland.appId)
            || "";
        var initCls = (toplevel.lastIpcObject && toplevel.lastIpcObject.initialClass) || "";

        var entry = (cls ? DesktopEntries.heuristicLookup(cls) : null)
            || (initCls ? DesktopEntries.heuristicLookup(initCls) : null);
        
        if (entry && entry.icon) {
            var direct = Quickshell.iconPath(entry.icon);
            if (direct && direct !== "") return direct;
        }

        var candidates = [];
        if (entry && entry.icon) candidates.push(entry.icon);
        if (cls) {
            candidates.push(cls);
            candidates.push(cls.toLowerCase());
            var parts = cls.split(".");
            if (parts.length > 1) {
                var last = parts[parts.length - 1];
                candidates.push(last);
                candidates.push(last.toLowerCase());
            }
        }
        if (initCls && initCls !== cls) {
            candidates.push(initCls);
            candidates.push(initCls.toLowerCase());
        }
        candidates.push("application-x-executable");

        return Quickshell.iconPath.apply(Quickshell, candidates);
    }

    function getSuperscript(count) {
        if (count <= 1) return "";
        var superscripts = {
            '0': '⁰', '1': '¹', '2': '²', '3': '³', '4': '⁴',
            '5': '⁵', '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹'
        };
        return String(count).split('').map(function(c) { return superscripts[c] || c; }).join('');
    }

    function getGroupedApps(toplevelsList) {
        if (!toplevelsList) return [];
        var groups = {};
        var list = [];
        for (var i = 0; i < toplevelsList.length; i++) {
            var top = toplevelsList[i];
            var icon = root.getAppIcon(top);
            if (!groups[icon]) {
                groups[icon] = {
                    icon: icon,
                    count: 0,
                    toplevels: []
                };
                list.push(groups[icon]);
            }
            groups[icon].count++;
            groups[icon].toplevels.push(top);
        }
        return list;
    }

    function formatAddress(addr) {
        if (!addr) return "";
        if (typeof addr === "number") {
            return "0x" + addr.toString(16);
        }
        var s = String(addr).trim();
        if (s.startsWith("0x")) return s;
        if (/^\d+$/.test(s)) {
            return "0x" + parseInt(s, 10).toString(16);
        }
        return "0x" + s;
    }

    function killWindow(top) {
        if (!top) return;

        // 1. Quickshell native Wayland handle close
        if (top.wayland && typeof top.wayland.close === "function") {
            try {
                top.wayland.close();
            } catch(e) {}
        }

        // 2. Format address and dispatch via hyprctl
        var rawAddr = (top.address) || (top.lastIpcObject && top.lastIpcObject.address) || "";
        var addr = root.formatAddress(rawAddr);
        if (addr !== "" && addr !== "0x0" && addr !== "0x") {
            var hexOnly = addr.startsWith("0x") ? addr.slice(2) : addr;
            Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "address:0x" + hexOnly]);
            Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "address:" + hexOnly]);
        }

        // 3. Fallback to PID
        var pid = top.pid || (top.lastIpcObject && top.lastIpcObject.pid) || 0;
        if (pid > 0) {
            Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "pid:" + pid]);
        }

        // 4. Fallback to Class
        var cls = (top.lastIpcObject && top.lastIpcObject.class) || "";
        if (cls !== "") {
            Quickshell.execDetached(["hyprctl", "dispatch", "closewindow", "class:" + cls]);
        }
    }

    function focusWindow(top) {
        if (root.activeWs) {
            root.activeWs.activate();
        }
        if (!top) return;

        if (top.wayland && typeof top.wayland.activate === "function") {
            try {
                top.wayland.activate();
            } catch(e) {}
        } else if (typeof top.activate === "function") {
            try {
                top.activate();
            } catch(e) {}
        }

        var rawAddr = (top.address) || (top.lastIpcObject && top.lastIpcObject.address) || "";
        var addr = root.formatAddress(rawAddr);
        if (addr !== "" && addr !== "0x0" && addr !== "0x") {
            var hexOnly = addr.startsWith("0x") ? addr.slice(2) : addr;
            Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "address:0x" + hexOnly]);
        }
        root.isHovered = false;
        root.hoveredWorkspace = null;
    }

    // Organic Connected Dropdown Surface when expanded
    Components.ConnectedDropdownSurface {
        z: 1
        anchors.fill: parent
        shoulderRadius: 10
        cornerRadius: 10
        hasLeftShoulder: false
        hasRightShoulder: true
        hasBottomLeftInverted: true
        hasBottomRightInverted: false
        visible: root.reveal > 0
    }

    // Default Pill Surface when collapsed
    Rectangle {
        z: 2
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.collapsedWidth
        height: Theme.barHeight
        visible: root.reveal <= 0
        color: (root.isHovered && !UiState.hasActiveOverlay) ? Theme.bgLight : "transparent"
        topRightRadius: Theme.radius
        bottomRightRadius: Theme.radius
        topLeftRadius: 0
        bottomLeftRadius: 0

        Behavior on color {
            ColorAnimation { duration: 120 }
        }
    }

    // TOP BAR SECTION (Workspaces numbers + App icons)
    Item {
        id: topSection
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.collapsedWidth
        height: Theme.barHeight
        z: 3

        property Item activePill: null

        Rectangle {
            id: activeIndicator
            z: 4
            y: 0
            height: 2
            color: Theme.accent
            
            property real targetX: topSection.activePill ? (4 + topSection.activePill.parent.x + topSection.activePill.x) : 4
            property real targetWidth: topSection.activePill ? topSection.activePill.width : 0
            
            x: targetX
            width: targetWidth
            
            Behavior on x {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
            Behavior on width {
                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
            }
        }

        RowLayout {
            id: topLayout
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            
            Repeater {
                model: Hyprland.workspaces
                
                RowLayout {
                    id: wsItem
                    required property var modelData
                    required property int index

                    property bool isSpecial: modelData.name.startsWith("special:")
                    visible: !isSpecial
                    spacing: 3

                    // Subtle vertical divider between workspaces
                    Rectangle {
                        visible: wsItem.index > 0 && !wsItem.isSpecial
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 12
                        radius: 0.5
                        color: Theme.surfaceVariant
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Rectangle {
                        id: wsPill

                        property bool isActive: wsItem.modelData.focused || wsItem.modelData.active
                        property bool isUrgent: wsItem.modelData.urgent
                        property var toplevelsList: wsItem.modelData.toplevels ? wsItem.modelData.toplevels.values : []
                        property var groupedApps: root.getGroupedApps(toplevelsList)
                        property int windowCount: toplevelsList.length

                        onIsActiveChanged: {
                            if (isActive) topSection.activePill = wsPill
                        }
                        Component.onCompleted: {
                            if (isActive) topSection.activePill = wsPill
                        }
                        
                        readonly property int maxVisibleGroups: 3
                        readonly property int overflowCount: Math.max(0, groupedApps.length - maxVisibleGroups)
                        
                        implicitHeight: wsItem.isSpecial ? 0 : 30
                        implicitWidth: wsItem.isSpecial ? 0 : rowContent.implicitWidth + 8
                        radius: 6
                        
                        Behavior on implicitWidth {
                            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                        }
                        
                        color: isActive ? Qt.rgba(0, 0, 0, 0.2) : (wsHoverHandler.hovered && !UiState.hasActiveOverlay ? Theme.surface : "transparent")
                        
                        HoverHandler {
                            id: wsHoverHandler
                            onHoveredChanged: {
                                if (hovered) {
                                    closeTimer.stop()
                                    root.isHovered = true
                                    root.hoveredWorkspace = wsItem.modelData
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wsItem.modelData.activate()
                        }

                        RowLayout {
                            id: rowContent
                            anchors.centerIn: parent
                            spacing: 5

                            // Workspace Number
                            Text {
                                id: wsNum
                                text: wsItem.modelData.name
                                color: wsPill.isActive ? Theme.accent : (wsPill.isUrgent ? Theme.red : (wsHoverHandler.hovered ? Theme.blue : (wsPill.windowCount > 0 ? Theme.fg : Theme.fgDim)))
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.weight: wsPill.isActive ? Font.Bold : Theme.fontWeight
                            }

                            // Grouped App icons for ALL occupied workspaces
                            RowLayout {
                                visible: wsPill.groupedApps.length > 0
                                spacing: 3

                                Repeater {
                                    model: wsPill.groupedApps.slice(0, wsPill.maxVisibleGroups)
                                    
                                    RowLayout {
                                        id: iconGroup
                                        required property var modelData
                                        spacing: 1

                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 5
                                            color: iconHoverHandler.hovered ? Theme.surfaceVariant : "transparent"

                                            IconImage {
                                                anchors.centerIn: parent
                                                width: 20
                                                height: 20
                                                source: iconGroup.modelData.icon
                                            }

                                            HoverHandler {
                                                id: iconHoverHandler
                                                onHoveredChanged: {
                                                    if (hovered) {
                                                        closeTimer.stop()
                                                        root.isHovered = true
                                                        root.hoveredWorkspace = wsItem.modelData
                                                    }
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    wsItem.modelData.activate();
                                                    if (iconGroup.modelData.toplevels && iconGroup.modelData.toplevels.length > 0) {
                                                        var top = iconGroup.modelData.toplevels[0];
                                                        if (top.activate) top.activate();
                                                        var addr = (top.address)
                                                            || (top.lastIpcObject && top.lastIpcObject.address)
                                                            || "";
                                                        if (addr !== "") {
                                                            Hyprland.dispatch("focuswindow address:" + addr);
                                                        }
                                                    }
                                                    root.isHovered = false;
                                                    root.hoveredWorkspace = null;
                                                }
                                            }
                                        }

                                        // Superscript count if multiple windows of the same app exist (e.g. >_³)
                                        Text {
                                            visible: iconGroup.modelData.count > 1
                                            text: root.getSuperscript(iconGroup.modelData.count)
                                            color: Theme.accent
                                            font.family: Theme.fontFamilySans
                                            font.pixelSize: 18
                                            font.weight: Font.Black
                                            Layout.alignment: Qt.AlignTop
                                            Layout.topMargin: -1
                                        }
                                    }
                                }

                                // Overflow counter (+N) if more than maxVisibleGroups unique apps exist
                                Rectangle {
                                    visible: wsPill.overflowCount > 0
                                    height: 18
                                    implicitWidth: overflowText.implicitWidth + 8
                                    radius: 4
                                    color: wsPill.isActive ? Qt.rgba(0, 0, 0, 0.4) : Theme.surface

                                    Text {
                                        id: overflowText
                                        anchors.centerIn: parent
                                        text: "+" + wsPill.overflowCount
                                        color: wsPill.isActive ? Theme.accent : Theme.fgDim
                                        font.family: Theme.fontFamilySans
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // EXPANDED BODY (Connected window title rows)
    Item {
        id: expandableBody
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + 2
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        height: root.bodyHeight * root.reveal
        visible: root.reveal > 0
        clip: true
        z: 2

        Item {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: root.bodyHeight

            ColumnLayout {
                id: contentCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: 3

                // Header: Workspace Title + Window Count
                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 4
                    Layout.rightMargin: 4
                    Layout.topMargin: 2
                    Layout.bottomMargin: 1
                    spacing: 6

                    Text {
                        text: "Workspace " + (root.activeWs ? (root.activeWs.name || root.activeWs.id || "") : "")
                        color: Theme.accent
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: root.windowList.length + (root.windowList.length === 1 ? " window" : " windows")
                        color: Theme.fgDim
                        font.family: Theme.fontFamilySans
                        font.pixelSize: 10
                        font.weight: Theme.fontWeight
                    }
                }

                // Thin Separator Line (Tight, no wasted space)
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.surfaceVariant
                    Layout.bottomMargin: 1
                }

                // Empty Workspace placeholder
                Item {
                    visible: root.windowList.length === 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: "󰇄"
                            color: Theme.fgDim
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }

                        Text {
                            text: "No active windows"
                            color: Theme.fgDim
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 11
                            font.weight: Theme.fontWeight
                        }
                    }
                }

                Repeater {
                    model: root.windowList

                    Rectangle {
                        id: rowItem
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 28
                        radius: 5
                        color: (rowHover.hovered && !closeHover.hovered)
                            ? Theme.surface
                            : (rowItem.modelData.activated ? Theme.bgLight : "transparent")

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 4
                            spacing: 6

                            // Clickable area to focus window
                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                HoverHandler { id: rowHover }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.focusWindow(rowItem.modelData)
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: 6

                                    IconImage {
                                        width: 16
                                        height: 16
                                        Layout.alignment: Qt.AlignVCenter
                                        source: root.getAppIcon(rowItem.modelData)
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: rowItem.modelData.title || (rowItem.modelData.lastIpcObject && rowItem.modelData.lastIpcObject.class) || "(Window)"
                                        color: rowItem.modelData.activated ? Theme.accent : Theme.fg
                                        font.family: Theme.fontFamilySans
                                        font.pixelSize: 11
                                        font.weight: rowItem.modelData.activated ? Font.Bold : Theme.fontWeight
                                        elide: Text.ElideRight
                                    }

                                    Rectangle {
                                        width: 5
                                        height: 5
                                        radius: 2.5
                                        color: Theme.accent
                                        visible: rowItem.modelData.activated
                                        Layout.alignment: Qt.AlignVCenter
                                    }
                                }
                            }

                            // Close / Kill Window Cross Button
                            Rectangle {
                                id: closeBtn
                                Layout.preferredWidth: 20
                                Layout.preferredHeight: 20
                                radius: 10
                                color: closeHover.hovered ? Qt.rgba(0.968, 0.463, 0.557, 0.25) : "transparent"
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color {
                                    ColorAnimation { duration: 100 }
                                }

                                HoverHandler { id: closeHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰅖"
                                    color: closeHover.hovered ? Theme.red : Theme.fgDim
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    preventStealing: true
                                    onClicked: (mouse) => {
                                        mouse.accepted = true;
                                        root.killWindow(rowItem.modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

