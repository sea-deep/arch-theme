import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import "../theme"
import "../components" as Components

Components.Pill {
    id: root
    
    implicitWidth: layout.implicitWidth + 10
    
    function getAppIcon(toplevel) {
        if (!toplevel) return Quickshell.iconPath("application-x-executable")
        var cls = (toplevel.lastIpcObject && toplevel.lastIpcObject.class)
            || (toplevel.wayland && toplevel.wayland.appId)
            || "";
        
        var lower = cls.toLowerCase();
        if (lower.includes("zed")) return Quickshell.iconPath("zed", "dev.zed.Zed", "zed-preview");
        if (lower.includes("zen")) return Quickshell.iconPath("zen", "zen-browser");
        if (lower.includes("code")) return Quickshell.iconPath("visual-studio-code", "code-oss", "code");
        if (lower.includes("kitty")) return Quickshell.iconPath("kitty", "utilities-terminal");
        if (lower.includes("antigravity")) return Quickshell.iconPath("antigravity", "application-x-executable");
        
        return Quickshell.iconPath(cls, lower, "application-x-executable");
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
                
                color: isActive ? Theme.accent : (wsHover.hovered ? Theme.surface : "transparent")
                
                MouseArea {
                    id: wsHover
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
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
                        color: wsPill.isActive ? Theme.bgDark : (wsPill.isUrgent ? Theme.red : (wsHover.hovered ? Theme.blue : (wsPill.windowCount > 0 ? Theme.fg : Theme.fgDim)))
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
                                    width: 22
                                    height: 22
                                    radius: 5
                                    color: iconHover.containsMouse ? (wsPill.isActive ? Qt.rgba(0, 0, 0, 0.25) : Theme.bgLight) : "transparent"

                                    IconImage {
                                        anchors.centerIn: parent
                                        width: 18
                                        height: 18
                                        source: iconGroup.modelData.icon
                                    }

                                    MouseArea {
                                        id: iconHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            wsPill.modelData.activate();
                                            if (iconGroup.modelData.toplevels && iconGroup.modelData.toplevels.length > 0) {
                                                iconGroup.modelData.toplevels[0].activate();
                                            }
                                        }
                                    }
                                }

                                // Superscript count if multiple windows of the same app exist (e.g. >_³)
                                Text {
                                    visible: iconGroup.modelData.count > 1
                                    text: root.getSuperscript(iconGroup.modelData.count)
                                    color: wsPill.isActive ? Theme.bgDark : Theme.accent
                                    font.family: Theme.fontFamilySans
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    Layout.alignment: Qt.AlignTop
                                    Layout.leftMargin: 1
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
