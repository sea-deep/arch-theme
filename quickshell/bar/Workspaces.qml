import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../theme"
import "../components" as Components

Item {
    id: root
    
    implicitWidth: mainPill.implicitWidth
    implicitHeight: Theme.barHeight
    
    property var previewWorkspace: null
    property real popupReveal: previewVisible ? 1 : 0
    readonly property bool previewVisible: previewWorkspace !== null
        && (previewWorkspace.toplevels ? previewWorkspace.toplevels.values.length > 0 : false)
    
    readonly property alias previewPopup: dropdownCard

    Behavior on popupReveal {
        NumberAnimation { duration: 160; easing.type: Easing.OutQuart }
    }

    Timer {
        id: closeTimer
        interval: 220
        onTriggered: {
            if (!dropdownHover.containsMouse && !layoutHover.containsMouse) {
                root.previewWorkspace = null
            }
        }
    }

    function scheduleClose() {
        closeTimer.restart()
    }

    function cancelClose() {
        closeTimer.stop()
    }

    function getAppIcon(toplevel) {
        if (!toplevel) return Quickshell.iconPath("application-x-executable")
        
        var cls = (toplevel.lastIpcObject && toplevel.lastIpcObject.class)
            || (toplevel.wayland && toplevel.wayland.appId)
            || "";
        var initCls = (toplevel.lastIpcObject && toplevel.lastIpcObject.initialClass) || "";

        // 1. Query Quickshell's native C++ DesktopEntries heuristic lookup
        var entry = (cls ? DesktopEntries.heuristicLookup(cls) : null)
            || (initCls ? DesktopEntries.heuristicLookup(initCls) : null);
        
        if (entry && entry.icon) {
            var direct = Quickshell.iconPath(entry.icon);
            if (direct && direct !== "") return direct;
        }

        // 2. Dynamic candidate generator (extracts reverse-domain IDs, clean names, and fallbacks)
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

    // Main Workspaces Pill
    Components.Pill {
        id: mainPill
        anchors.left: parent.left
        anchors.top: parent.top
        implicitWidth: layout.implicitWidth + 10

        MouseArea {
            id: layoutHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: root.cancelClose()
            onExited: root.scheduleClose()
        }

        RowLayout {
            id: layout
            anchors.centerIn: parent
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
                    implicitWidth: isSpecial ? 0 : rowContent.implicitWidth + 12
                    radius: 8
                    
                    Behavior on implicitWidth {
                        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                    }
                    
                    color: isActive ? Theme.accent : (wsHover.containsMouse ? Theme.surface : "transparent")
                    
                    MouseArea {
                        id: wsHover
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: {
                            root.cancelClose()
                            root.previewWorkspace = wsPill.modelData
                        }
                        onExited: {
                            root.scheduleClose()
                        }
                        onClicked: {
                            wsPill.modelData.activate()
                            root.previewWorkspace = null
                        }
                    }

                    RowLayout {
                        id: rowContent
                        anchors.centerIn: parent
                        spacing: 5

                        // Workspace Number
                        Text {
                            id: wsNum
                            text: wsPill.modelData.name
                            color: wsPill.isActive ? Theme.bgDark : (wsPill.isUrgent ? Theme.red : (wsHover.containsMouse ? Theme.blue : (wsPill.windowCount > 0 ? Theme.fg : Theme.fgDim)))
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
                                        color: iconHover.containsMouse ? (wsPill.isActive ? Qt.rgba(0, 0, 0, 0.25) : Theme.bgLight) : "transparent"

                                        IconImage {
                                            anchors.centerIn: parent
                                            width: 20
                                            height: 20
                                            source: iconGroup.modelData.icon
                                        }

                                        MouseArea {
                                            id: iconHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: {
                                                root.cancelClose()
                                                root.previewWorkspace = wsPill.modelData
                                            }
                                            onExited: root.scheduleClose()
                                            onClicked: {
                                                wsPill.modelData.activate();
                                                if (iconGroup.modelData.toplevels && iconGroup.modelData.toplevels.length > 0) {
                                                    iconGroup.modelData.toplevels[0].activate();
                                                }
                                                root.previewWorkspace = null
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

    // Pull-down Workspace Title Bar Preview Card
    Rectangle {
        id: dropdownCard
        z: 999
        anchors.left: parent.left
        y: Theme.barHeight + 6 + (1 - root.popupReveal) * -8
        opacity: root.popupReveal
        visible: root.popupReveal > 0

        implicitWidth: Math.min(420, Math.max(280, cardContent.implicitWidth + 24))
        implicitHeight: cardContent.implicitHeight + 20

        color: Theme.bg
        radius: Theme.radius
        border.width: 1
        border.color: Theme.accentGlow

        MouseArea {
            id: dropdownHover
            anchors.fill: parent
            hoverEnabled: true
            onEntered: root.cancelClose()
            onExited: root.scheduleClose()
        }

        ColumnLayout {
            id: cardContent
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            // Header: Workspace Title Badge
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 20
                    height: 20
                    radius: 5
                    color: Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: root.previewWorkspace ? root.previewWorkspace.name : ""
                        color: Theme.bgDark
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: root.previewWorkspace
                        ? ("Workspace " + root.previewWorkspace.name + "  ·  " + (root.previewWorkspace.toplevels ? root.previewWorkspace.toplevels.values.length : 0) + " open")
                        : ""
                    color: Theme.fgDim
                    font.family: Theme.fontFamilySans
                    font.pixelSize: 12
                    font.weight: Theme.fontWeight
                }

                Item { Layout.fillWidth: true }
            }

            // Window list
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: root.previewWorkspace && root.previewWorkspace.toplevels
                        ? root.previewWorkspace.toplevels.values
                        : []

                    Rectangle {
                        id: windowRow
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 38
                        radius: 8
                        color: rowMouse.containsMouse
                            ? Theme.surface
                            : (windowRow.modelData.activated ? Theme.bgLight : "transparent")
                        border.width: windowRow.modelData.activated ? 1 : 0
                        border.color: Theme.accentGlow

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 10

                            // App Icon
                            IconImage {
                                width: 22
                                height: 22
                                Layout.alignment: Qt.AlignVCenter
                                source: root.getAppIcon(windowRow.modelData)
                            }

                            // Window Title & App Class
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: windowRow.modelData.title || windowRow.modelData.lastIpcObject.class || "(Untitled Window)"
                                    color: windowRow.modelData.activated ? Theme.accent : Theme.fg
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 12
                                    font.weight: windowRow.modelData.activated ? Font.Bold : Theme.fontWeight
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: (windowRow.modelData.lastIpcObject && windowRow.modelData.lastIpcObject.class) || ""
                                    color: Theme.fgMuted
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    visible: text !== ""
                                }
                            }

                            // Active focus indicator dot
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: Theme.accent
                                visible: windowRow.modelData.activated
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: rowMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.previewWorkspace) {
                                    root.previewWorkspace.activate()
                                }
                                if (windowRow.modelData && windowRow.modelData.activate) {
                                    windowRow.modelData.activate()
                                }
                                root.previewWorkspace = null
                            }
                        }
                    }
                }
            }
        }
    }
}
