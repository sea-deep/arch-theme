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
    
    readonly property var activeWs: hoveredWorkspace
        || (Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.toplevels && Hyprland.focusedWorkspace.toplevels.values.length > 0 ? Hyprland.focusedWorkspace : null)
    
    readonly property var windowList: activeWs && activeWs.toplevels
        ? activeWs.toplevels.values
        : []
    
    property bool isHovered: false
    readonly property bool isExpanded: root.isHovered && windowList.length > 0
    property real reveal: isExpanded ? 1 : 0
    
    readonly property real collapsedWidth: topLayout.implicitWidth + 8
    readonly property real expandedWidth: Math.max(340, collapsedWidth)
    readonly property int bodyHeight: windowList.length > 0 ? Math.min(320, windowList.length * 38 + 16) : 0
    
    implicitWidth: reveal > 0 ? expandedWidth : collapsedWidth
    implicitHeight: reveal > 0
        ? Theme.barHeight + Theme.outerGap + bodyHeight * reveal
        : Theme.barHeight
    
    Behavior on reveal { NumberAnimation { duration: 110; easing.type: Easing.OutQuart } }
    Behavior on implicitWidth { NumberAnimation { duration: 120; easing.type: Easing.OutQuart } }

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
            '2': '²', '3': '³', '4': '⁴', '5': '⁵',
            '6': '⁶', '7': '⁷', '8': '⁸', '9': '⁹'
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

    // Organic Connected Dropdown Surface when expanded
    Components.ConnectedDropdownSurface {
        anchors.fill: parent
        tabWidth: root.collapsedWidth
        tabOnLeft: true
        visible: root.reveal > 0
    }

    // Default Pill Surface when collapsed
    Components.Pill {
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.collapsedWidth
        height: Theme.barHeight
        visible: root.reveal <= 0
        border.color: root.isHovered ? Theme.accentGlow : Theme.bgDark
    }

    // TOP BAR SECTION (Workspaces numbers + App icons)
    Item {
        id: topSection
        anchors.top: parent.top
        anchors.left: parent.left
        width: root.collapsedWidth
        height: Theme.barHeight
        z: 2

        RowLayout {
            id: topLayout
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            
            Repeater {
                model: Hyprland.workspaces
                
                Rectangle {
                    id: wsPill
                    required property var modelData

                    property bool isSpecial: modelData.name.startsWith("special:")
                    visible: !isSpecial
                    
                    property bool isActive: modelData.focused || modelData.active
                    property bool isUrgent: modelData.urgent
                    property var toplevelsList: modelData.toplevels ? modelData.toplevels.values : []
                    property var groupedApps: root.getGroupedApps(toplevelsList)
                    property int windowCount: toplevelsList.length
                    
                    readonly property int maxVisibleGroups: 3
                    readonly property int overflowCount: Math.max(0, groupedApps.length - maxVisibleGroups)
                    
                    implicitHeight: isSpecial ? 0 : 26
                    implicitWidth: isSpecial ? 0 : rowContent.implicitWidth + 8
                    radius: 6
                    
                    Behavior on implicitWidth {
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                    
                    color: isActive ? Theme.accent : (wsHoverHandler.hovered ? Theme.surface : "transparent")
                    
                    HoverHandler {
                        id: wsHoverHandler
                        onHoveredChanged: {
                            if (hovered) {
                                closeTimer.stop()
                                root.isHovered = true
                                root.hoveredWorkspace = wsPill.modelData
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wsPill.modelData.activate()
                    }

                    RowLayout {
                        id: rowContent
                        anchors.centerIn: parent
                        spacing: 5

                        // Workspace Number
                        Text {
                            id: wsNum
                            text: wsPill.modelData.name
                            color: wsPill.isActive ? Theme.bgDark : (wsPill.isUrgent ? Theme.red : (wsHoverHandler.hovered ? Theme.blue : (wsPill.windowCount > 0 ? Theme.fg : Theme.fgDim)))
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            font.weight: wsPill.isActive ? Font.Bold : Theme.fontWeight
                        }

                        // Grouped App icons for ALL occupied workspaces
                        RowLayout {
                            visible: wsPill.groupedApps.length > 0
                            spacing: 4

                            Repeater {
                                model: wsPill.groupedApps.slice(0, wsPill.maxVisibleGroups)
                                
                                RowLayout {
                                    id: iconGroup
                                    required property var modelData
                                    spacing: 1

                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 6
                                        color: iconHoverHandler.hovered ? (wsPill.isActive ? Qt.rgba(0, 0, 0, 0.25) : Theme.bgLight) : "transparent"

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
                                                    root.hoveredWorkspace = wsPill.modelData
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                wsPill.modelData.activate();
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
                                        color: wsPill.isActive ? Theme.bgDark : Theme.accent
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
                                color: wsPill.isActive ? Qt.rgba(0, 0, 0, 0.2) : Theme.surface

                                Text {
                                    id: overflowText
                                    anchors.centerIn: parent
                                    text: "+" + wsPill.overflowCount
                                    color: wsPill.isActive ? Theme.bgDark : Theme.fgDim
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

    // EXPANDED BODY (Connected window title rows)
    Item {
        id: expandableBody
        anchors.top: parent.top
        anchors.topMargin: Theme.barHeight + Theme.outerGap + 8
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        visible: root.reveal > 0
        opacity: root.reveal
        z: 2
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 4

            Repeater {
                model: root.windowList

                Rectangle {
                    id: rowItem
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: 34
                    radius: 7
                    color: rowHover.containsMouse
                        ? Theme.surface
                        : (rowItem.modelData.activated ? Theme.bgLight : "transparent")

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 10

                        IconImage {
                            width: 20
                            height: 20
                            Layout.alignment: Qt.AlignVCenter
                            source: root.getAppIcon(rowItem.modelData)
                        }

                        Text {
                            Layout.fillWidth: true
                            text: rowItem.modelData.title || (rowItem.modelData.lastIpcObject && rowItem.modelData.lastIpcObject.class) || "(Window)"
                            color: rowItem.modelData.activated ? Theme.accent : Theme.fg
                            font.family: Theme.fontFamilySans
                            font.pixelSize: 12
                            font.weight: rowItem.modelData.activated ? Font.Bold : Theme.fontWeight
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.accent
                            visible: rowItem.modelData.activated
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    MouseArea {
                        id: rowHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.activeWs) {
                                root.activeWs.activate()
                            }
                            if (rowItem.modelData) {
                                if (rowItem.modelData.activate) {
                                    rowItem.modelData.activate()
                                }
                                var addr = (rowItem.modelData.address)
                                    || (rowItem.modelData.lastIpcObject && rowItem.modelData.lastIpcObject.address)
                                    || "";
                                if (addr !== "") {
                                    Hyprland.dispatch("focuswindow address:" + addr)
                                }
                            }
                            root.isHovered = false
                            root.hoveredWorkspace = null
                        }
                    }
                }
            }
        }
    }
}
