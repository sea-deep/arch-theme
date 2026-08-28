import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../theme"
import "../components" as Components

Components.Pill {
    id: root
    
    implicitWidth: layout.implicitWidth + Theme.pillPadding * 2
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: Theme.spacing
        
        Repeater {
            model: Hyprland.workspaces
            
            Rectangle {
                required property var modelData
                
                width: 26
                height: 26
                radius: 8
                
                property bool isFocused: modelData === Hyprland.focusedWorkspace
                property bool hasWindows: modelData.windows > 0
                
                color: isFocused ? Theme.accent : (hasWindows ? Theme.surface : Theme.bgLight)
                
                Text {
                    anchors.centerIn: parent
                    text: parent.modelData.name
                    color: parent.isFocused ? Theme.bgDark : Theme.fg
                    font.family: Theme.fontFamilySans
                    font.pixelSize: Theme.fontSize
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onEntered: root.hovered = true
                    onExited: root.hovered = false
                    onClicked: Hyprland.dispatch("workspace " + parent.modelData.name)
                }
            }
        }
    }
}
