import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../theme"
import "../components" as Components

Components.Pill {
    id: root
    required property var hostWindow
    
    active: UiState.trayMenuVisible
    collapseWhenEmpty: true
    isEmpty: SystemTray.items.values.length === 0
    
    implicitWidth: layout.implicitWidth + Theme.pillPaddingHoriz * 2

    function toggleMenu(item, anchorItem) {
        if (!item.hasMenu || item.menu === null)
            return

        const edge = anchorItem.mapToItem(null, anchorItem.width, anchorItem.height)
        const rightOffset = root.hostWindow.width - edge.x + Theme.outerGap
        UiState.toggleTrayMenu(item, root.hostWindow.screen.name, rightOffset)
    }
    
    function resolveIcon(item) {
        if (!item) return ""
        if (item.icon && item.icon !== "") return item.icon
        if (item.iconName && item.iconName !== "") {
            var p = Quickshell.iconPath(item.iconName)
            if (p && p !== "") return p
        }
        if (item.id && item.id !== "") {
            var p2 = Quickshell.iconPath(item.id)
            if (p2 && p2 !== "") return p2
        }
        return Quickshell.iconPath("application-x-executable")
    }

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 10
        
        Repeater {
            model: SystemTray.items
            
            Item {
                required property var modelData
                
                width: 18
                height: 18
                
                IconImage {
                    anchors.fill: parent
                    source: root.resolveIcon(parent.modelData)
                }
                
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: (mouse) => {
                        if (mouse.button === Qt.LeftButton) {
                            if (parent.modelData.onlyMenu) {
                                root.toggleMenu(parent.modelData, parent)
                            } else {
                                parent.modelData.activate()
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            parent.modelData.secondaryActivate()
                        } else if (mouse.button === Qt.RightButton) {
                            root.toggleMenu(parent.modelData, parent)
                        }
                    }
                    onWheel: (wheel) => {
                        parent.modelData.scroll(wheel.angleDelta.y, false)
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }
    }
}
