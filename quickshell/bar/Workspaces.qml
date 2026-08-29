import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import "../theme"
import "../components" as Components

Components.Pill {
    id: root
    
    implicitWidth: layout.implicitWidth + 8
    
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 4
        
        Repeater {
            model: Hyprland.workspaces
            
            Rectangle {
                required property var modelData

                property bool isSpecial: modelData.name.startsWith("special:")
                visible: !isSpecial
                
                // Content-driven width based on Waybar button CSS (padding: 0px 4px; margin: 4px 2px)
                // Width = implicitTextWidth + 8px padding
                implicitWidth: isSpecial ? 0 : wsText.implicitWidth + 8
                implicitHeight: isSpecial ? 0 : 26
                radius: 8
                
                property bool isActive: modelData.focused || modelData.active
                property bool isUrgent: modelData.urgent
                
                color: isActive ? Theme.accent : (hover.hovered ? Theme.surface : "transparent")
                
                Text {
                    id: wsText
                    anchors.centerIn: parent
                    text: parent.modelData.name
                    // Active color is bgDark, urgent is red, otherwise fg
                    color: parent.isActive ? Theme.bgDark : (parent.isUrgent ? Theme.red : (hover.hovered ? Theme.blue : Theme.fg))
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSize
                    font.weight: Theme.fontWeight
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    id: hover
                    onClicked: {
                        modelData.activate()
                    }
                }
            }
        }
    }
}
